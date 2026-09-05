"""Fit pixels-per-degree from the 0.5-degree pitch sweep.

Method notes, so the numbers can be judged:
  * The scope picture is an annulus. The reticle, bezel and inner sub-disc are
    STATIC across every frame, and correlating with them included makes the
    correlator lock onto them and report ~zero shift with high confidence -- the
    trap that cost the 5-degree measurement two iterations. So the mask is built
    from the per-pixel standard deviation ACROSS the whole sweep: static
    furniture has low variance, scene content has high.
  * Phase correlation on a high-passed, windowed, mean-subtracted crop.
  * peak/rms is reported for every pair. A validated match on this rig runs well
    above the noise; single digits mean no match.
  * Two frames at the SAME pitch give the per-step noise floor, measured rather
    than assumed.
"""
import glob
import os
import numpy as np
from PIL import Image

SRC = r"C:\Users\TD3KX\AppData\Local\Temp\claude\C--Steam-steamapps-common\f9a9208a-d9a3-4409-b891-2ea19c978b48\scratchpad\lm\sweep"


def load(p):
    return np.asarray(Image.open(p).convert("L"), dtype=np.float64)


files = sorted(glob.glob(os.path.join(SRC, "p*-a.png")))
degs = [float(os.path.basename(f)[1:5]) for f in files]
A = [load(f) for f in files]
B = [load(f.replace("-a.png", "-b.png")) for f in files]
back = load(os.path.join(SRC, "back-p180.png"))
H, W = A[0].shape
print("frames: %d   size %dx%d   degrees: %s" % (len(A), W, H, degs))

# ---- scene mask: high variance across the sweep, inside the picture annulus
stack = np.stack(A + B)
std = stack.std(axis=0)
yy, xx = np.mgrid[0:H, 0:W]

# locate the picture: the bright, high-variance blob's centroid and extent
seed = std > np.percentile(std, 97)
cy, cx = yy[seed].mean(), xx[seed].mean()
r = np.hypot(yy - cy, xx - cx)
rad = np.percentile(r[seed], 97)
print("picture centre (%.0f, %.0f), working radius %.0f px" % (cx, cy, rad))

mask = (r < rad) & (std > np.percentile(std[r < rad], 55))
print("scene mask: %d px (%.1f%% of the disc)" % (mask.sum(), 100.0 * mask.sum() / (r < rad).sum()))

ys, xs = np.nonzero(mask)
y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
sub = (slice(y0, y1), slice(x0, x1))
m = mask[sub].astype(np.float64)
h, w = m.shape
win = np.outer(np.hanning(h), np.hanning(w))


def prep(img):
    a = img[sub] * m
    # high-pass: subtract a heavy box blur, cheaply, via FFT of a gaussian
    f = np.fft.rfft2(a)
    fy = np.fft.fftfreq(h)[:, None]
    fx = np.fft.rfftfreq(w)[None, :]
    lp = np.exp(-0.5 * ((fy / 0.010) ** 2 + (fx / 0.010) ** 2))
    a = a - np.fft.irfft2(f * lp, s=(h, w))
    a = a * m * win
    a -= a.mean()
    return a


def phase_corr(a, b):
    FA, FB = np.fft.rfft2(prep(a)), np.fft.rfft2(prep(b))
    R = FA * np.conj(FB)
    mag = np.abs(R)
    mag[mag < 1e-12] = 1e-12
    c = np.fft.irfft2(R / mag, s=(h, w))
    idx = np.unravel_index(np.argmax(c), c.shape)
    peak = c[idx]
    dy = idx[0] - (h if idx[0] > h // 2 else 0)
    dx = idx[1] - (w if idx[1] > w // 2 else 0)
    return dx, dy, peak / c.std()


print()
print("--- per-step noise floor: the two frames captured at the SAME pitch ---")
for d, a, b in zip(degs, A, B):
    dx, dy, q = phase_corr(a, b)
    print("  pitch +%.1f   dx=%+5d dy=%+5d   peak/rms=%6.1f" % (d, dx, dy, q))

print()
print("--- the measurement: baseline vs each step ---")
rows = []
for d, a in zip(degs, A):
    dx, dy, q = phase_corr(A[0], a)
    rows.append((d, dx, dy, q))
    print("  +%.1f deg   dx=%+5d dy=%+5d   peak/rms=%6.1f" % (d, dx, dy, q))

dx, dy, q = phase_corr(A[0], back)
print()
print("--- repeatability: back to pitch 180 ---")
print("  back-p180  dx=%+5d dy=%+5d   peak/rms=%6.1f" % (dx, dy, q))

good = [r for r in rows if r[3] > 8.0]
print()
if len(good) >= 3:
    d = np.array([r[0] for r in good])
    vx = np.array([r[1] for r in good], dtype=float)
    vy = np.array([r[2] for r in good], dtype=float)
    for name, v in (("dx", vx), ("dy", vy)):
        s, c = np.polyfit(d, v, 1)
        res = v - (s * d + c)
        print("  %s slope = %+8.2f px/deg   intercept %+7.2f   residual rms %.2f px"
              % (name, s, c, np.sqrt((res ** 2).mean())))
    mag = np.hypot(vx, vy)
    s, c = np.polyfit(d, mag, 1)
    print("  |shift| slope = %+7.2f px/deg  (residual rms %.2f px)"
          % (s, np.sqrt(((mag - (s * d + c)) ** 2).mean())))
else:
    print("  NOT ENOUGH COHERENT STEPS TO FIT (%d of %d cleared peak/rms 8)" % (len(good), len(rows)))
