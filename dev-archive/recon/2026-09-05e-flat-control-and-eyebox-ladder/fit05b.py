"""Fit px/deg from the 0.5-degree sweep - second attempt, with an honest mask.

The first attempt built its mask from "high variance across the sweep" and
locked onto the GAME WORLD OUTSIDE THE SCOPE: animated grass and birds are
high-variance and cover far more of the frame than the scope picture, and they do
not move when the mirror plane pitches, so every pair correlated to exactly zero
with a huge peak. Same failure class as the reticle trap, different costume.

The mask here is built from the only thing that distinguishes the scope picture:
it is the region that changes when the PITCH changes but does NOT change from
scene animation alone.

    pitch_change = |A(2.5 deg) - A(0 deg)|      changes with the plane
    time_change  = |B(0 deg)   - A(0 deg)|      changes on its own
    scope        = pitch_change high AND time_change low-ish

That is self-validating: if the resulting mask is not a disc in the middle of the
frame, the instrument is wrong and the numbers get thrown away, not published.
"""
import glob
import os
import numpy as np
from PIL import Image

SRC = r"C:\Users\TD3KX\AppData\Local\Temp\claude\C--Steam-steamapps-common\f9a9208a-d9a3-4409-b891-2ea19c978b48\scratchpad\lm\sweep"
OUT = r"C:\Users\TD3KX\AppData\Local\Temp\claude\C--Steam-steamapps-common\f9a9208a-d9a3-4409-b891-2ea19c978b48\scratchpad\lm"


def load(p):
    return np.asarray(Image.open(p).convert("L"), dtype=np.float64)


files = sorted(glob.glob(os.path.join(SRC, "p*-a.png")))
degs = [float(os.path.basename(f)[1:5]) for f in files]
A = [load(f) for f in files]
B = [load(f.replace("-a.png", "-b.png")) for f in files]
back = load(os.path.join(SRC, "back-p180.png"))
H, W = A[0].shape

pitch_change = np.abs(A[-1] - A[0])
time_change = np.abs(B[0] - A[0])
score = pitch_change - 1.5 * time_change
mask = score > np.percentile(score, 92)

ys, xs = np.nonzero(mask)
cx, cy = xs.mean(), ys.mean()
rad = np.percentile(np.hypot(ys - cy, xs - cx), 95)
print("candidate scope region: centre (%.0f, %.0f)  r95=%.0f  px=%d" % (cx, cy, rad, mask.sum()))
print("  frame centre is (%.0f, %.0f) - a scope picture should be near it" % (W / 2, H / 2))
compact = mask.sum() / (np.pi * rad * rad)
print("  fill of its own bounding circle: %.2f  (a disc-ish blob is > ~0.35)" % compact)

# tighten to a clean annulus about that centre, dropping the dark reticle bars
yy, xx = np.mgrid[0:H, 0:W]
r = np.hypot(yy - cy, xx - cx)
base = A[0]
mask = (r < rad) & (base > 25) & (pitch_change > np.percentile(pitch_change[r < rad], 40))
print("  final mask: %d px" % mask.sum())

vis = np.stack([base] * 3, axis=-1)
vis[..., 0] = np.where(mask, 255, vis[..., 0])
Image.fromarray(vis.astype(np.uint8)).save(os.path.join(OUT, "check-mask.png"))
print("  wrote check-mask.png (mask in red over the baseline)")

ys, xs = np.nonzero(mask)
y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
sub = (slice(y0, y1), slice(x0, x1))
m = mask[sub].astype(np.float64)
h, w = m.shape
win = np.outer(np.hanning(h), np.hanning(w))
fy = np.fft.fftfreq(h)[:, None]
fx = np.fft.rfftfreq(w)[None, :]
lp = np.exp(-0.5 * ((fy / 0.012) ** 2 + (fx / 0.012) ** 2))


def prep(img):
    a = img[sub] * m
    a = a - np.fft.irfft2(np.fft.rfft2(a) * lp, s=(h, w))
    a = a * m * win
    return a - a.mean()


def phase_corr(a, b):
    FA, FB = np.fft.rfft2(prep(a)), np.fft.rfft2(prep(b))
    R = FA * np.conj(FB)
    mag = np.abs(R)
    mag[mag < 1e-12] = 1e-12
    c = np.fft.irfft2(R / mag, s=(h, w))
    idx = np.unravel_index(np.argmax(c), c.shape)
    dy = idx[0] - (h if idx[0] > h // 2 else 0)
    dx = idx[1] - (w if idx[1] > w // 2 else 0)
    return dx, dy, c[idx] / c.std()


print("\n--- noise floor: two frames at the SAME pitch ---")
floors = []
for d, a, b in zip(degs, A, B):
    dx, dy, q = phase_corr(a, b)
    floors.append(np.hypot(dx, dy))
    print("  +%.1f   dx=%+5d dy=%+5d  peak/rms=%6.1f" % (d, dx, dy, q))
print("  worst same-state shift: %.1f px" % max(floors))

print("\n--- baseline vs each step ---")
rows = []
for d, a in zip(degs, A):
    dx, dy, q = phase_corr(A[0], a)
    rows.append((d, dx, dy, q))
    print("  +%.1f   dx=%+5d dy=%+5d  peak/rms=%6.1f" % (d, dx, dy, q))

dx, dy, q = phase_corr(A[0], back)
print("\n--- repeatability: back to pitch 180 ---")
print("  dx=%+5d dy=%+5d  peak/rms=%6.1f" % (dx, dy, q))

d = np.array([r[0] for r in rows])
vx = np.array([r[1] for r in rows], float)
vy = np.array([r[2] for r in rows], float)
print()
if np.abs(vx).max() < 2 and np.abs(vy).max() < 2:
    print("  NO MOTION DETECTED ACROSS THE WHOLE SWEEP - suspect the mask again, not the game")
else:
    for name, v in (("dx", vx), ("dy", vy)):
        s, c = np.polyfit(d, v, 1)
        print("  %s slope = %+8.2f px/deg  residual rms %.2f px"
              % (name, s, np.sqrt(((v - (s * d + c)) ** 2).mean())))
    mag = np.hypot(vx, vy)
    s, c = np.polyfit(d, mag, 1)
    print("  |shift| = %+7.2f px/deg  residual rms %.2f px" % (s, np.sqrt(((mag - (s * d + c)) ** 2).mean())))
    print("  direction of travel: dx %+.0f, dy %+.0f over the full %.1f deg (y grows DOWN)"
          % (vx[-1], vy[-1], d[-1]))
