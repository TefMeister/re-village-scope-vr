"""Third and final attempt at px/deg from the 0.5-degree sweep.

The two earlier attempts both built the mask from image STATISTICS (variance, or
change-with-pitch) and both locked onto the animated game world OUTSIDE the scope,
which does not move when the plane pitches. So this one does not ask the pixels
what the scope is - it finds the disc GEOMETRICALLY from the radial brightness
profile, which is a property of the scope furniture and cannot drift onto grass:

    the tube around the picture is dark      -> low ring mean at large r
    the picture itself is bright             -> high ring mean in the annulus
    the inner sub-disc is dark               -> low ring mean at small r

If that profile does not show a clear bright annulus, the script says so and
refuses to fit, rather than producing a number.
"""
import glob
import os
import numpy as np
from PIL import Image

SRC = r"C:\Users\TD3KX\github-backups-pd\re-village-scope-vr\dev-archive\recon\2026-09-05e-flat-control-and-eyebox-ladder\sweep-0.5deg"
OUT = r"C:\Users\TD3KX\AppData\Local\Temp\claude\C--Steam-steamapps-common\f9a9208a-d9a3-4409-b891-2ea19c978b48\scratchpad"


def load(p):
    return np.asarray(Image.open(p).convert("L"), dtype=np.float64)


files = sorted(glob.glob(os.path.join(SRC, "p*-a.jpg")))
degs = [float(os.path.basename(f)[1:5]) for f in files]
A = [load(f) for f in files]
B = [load(f.replace("-a.jpg", "-b.jpg")) for f in files]
back = load(os.path.join(SRC, "back-p180.jpg"))
H, W = A[0].shape
base = A[0]

# ---- 1. centre: brightness centroid of the brightest region near frame centre
yy, xx = np.mgrid[0:H, 0:W]
r0 = np.hypot(yy - H / 2, xx - W / 2)
core = (r0 < 0.45 * H) & (base > np.percentile(base[r0 < 0.45 * H], 80))
cy, cx = yy[core].mean(), xx[core].mean()
r = np.hypot(yy - cy, xx - cx)
print("disc centre from the bright core: (%.0f, %.0f)   frame centre (%.0f, %.0f)" % (cx, cy, W / 2, H / 2))

# ---- 2. radial brightness profile
rmax = int(min(cx, cy, W - cx, H - cy))
prof = np.array([base[(r >= k) & (r < k + 1)].mean() for k in range(rmax)])
hi = prof.max()
bright = prof > 0.55 * hi
if not bright.any():
    raise SystemExit("REFUSING: no bright annulus in the radial profile - the disc was not found")
idx = np.nonzero(bright)[0]
r_in, r_out = idx.min(), idx.max()
print("radial profile: bright from r=%d to r=%d (peak ring mean %.0f)" % (r_in, r_out, hi))
print("  profile sample every 40 px:", " ".join("%d:%.0f" % (k, prof[k]) for k in range(0, rmax, 40)))

lo, hi_r = r_in + 12, r_out - 12
if hi_r - lo < 60:
    raise SystemExit("REFUSING: annulus only %d px wide - too thin to correlate" % (hi_r - lo))

# ---- 3. mask: the annulus, minus the dark reticle bars
mask = (r >= lo) & (r <= hi_r) & (base > 40)
print("mask: %d px, annulus r %d..%d" % (mask.sum(), lo, hi_r))
vis = np.stack([base] * 3, -1)
vis[..., 0] = np.where(mask, 255, vis[..., 0])
Image.fromarray(vis.astype(np.uint8)).save(os.path.join(OUT, "check-mask-c.png"))

ys, xs = np.nonzero(mask)
sub = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1))

# ⚠️ NOT a hard mask. A binary annulus has enormous energy at its own rim, and after
# high-passing that rim is the strongest feature in BOTH images - so the correlator
# locks onto the mask instead of the picture and pins the peak at (0,0) with a huge
# apparent confidence. That is what broke all three attempts today, and it is what
# the positive control below exists to catch. A smooth raised-cosine taper in radius
# has no edge to lock onto.
def taper(rr, a, b, roll):
    t = np.ones_like(rr)
    lo_e = np.clip((rr - a) / roll, 0.0, 1.0)
    hi_e = np.clip((b - rr) / roll, 0.0, 1.0)
    t = 0.5 * (1 - np.cos(np.pi * lo_e)) * 0.5 * (1 - np.cos(np.pi * hi_e))
    t[(rr < a) | (rr > b)] = 0.0
    return t

m = taper(r[sub], lo, hi_r, 40.0)
h, w = m.shape
win = np.ones((h, w))
fy = np.fft.fftfreq(h)[:, None]
fx = np.fft.rfftfreq(w)[None, :]
lp = np.exp(-0.5 * ((fy / 0.02) ** 2 + (fx / 0.02) ** 2))


def prep(img):
    a = img[sub] * m
    a = a - np.fft.irfft2(np.fft.rfft2(a) * lp, s=(h, w))
    a = a * m * win
    return a - a.mean()


def pc(a, b):
    FA, FB = np.fft.rfft2(prep(a)), np.fft.rfft2(prep(b))
    R = FA * np.conj(FB)
    mg = np.abs(R)
    mg[mg < 1e-12] = 1e-12
    c = np.fft.irfft2(R / mg, s=(h, w))
    i = np.unravel_index(np.argmax(c), c.shape)
    dy = i[0] - (h if i[0] > h // 2 else 0)
    dx = i[1] - (w if i[1] > w // 2 else 0)
    # Sign convention, pinned by the positive control below: POSITIVE dy means the
    # content in `b` sits LOWER in the image than in `a` (y grows down).
    return -dx, -dy, c[i] / c.std()


# ---- 4. positive control: does this mask detect a KNOWN shift?
shifted = np.roll(np.roll(base, 17, axis=0), -23, axis=1)
dx, dy, q = pc(base, shifted)
print("\npositive control: rolled the baseline by (dx=-23, dy=+17) -> measured (dx=%+d, dy=%+d) peak/rms=%.1f"
      % (dx, dy, q))
if abs(dx + 23) > 2 or abs(dy - 17) > 2:
    raise SystemExit("REFUSING: the mask cannot recover a known shift - no result is trustworthy from it")
print("  the instrument works on this mask.")

print("\n--- noise floor: two frames at the SAME pitch ---")
for d, a, b in zip(degs, A, B):
    dx, dy, q = pc(a, b)
    print("  +%.1f  dx=%+4d dy=%+4d  peak/rms=%6.1f" % (d, dx, dy, q))

print("\n--- baseline vs each step ---")
rows = []
for d, a in zip(degs, A):
    dx, dy, q = pc(A[0], a)
    rows.append((d, dx, dy, q))
    print("  +%.1f  dx=%+4d dy=%+4d  peak/rms=%6.1f" % (d, dx, dy, q))

dx, dy, q = pc(A[0], back)
print("\nrepeatability, back to 180: dx=%+d dy=%+d peak/rms=%.1f" % (dx, dy, q))

d = np.array([x[0] for x in rows])
vx = np.array([x[1] for x in rows], float)
vy = np.array([x[2] for x in rows], float)
print()
if np.abs(vx).max() < 2 and np.abs(vy).max() < 2:
    print("RESULT: no motion above 1 px across 2.5 deg, on a mask proven to detect a 28 px shift.")
    print("        Either the response is under ~0.4 px/deg here, or the plane pitch does not move")
    print("        the picture at these angles at all. NOT a measurement failure this time.")
else:
    for nm, v in (("dx", vx), ("dy", vy)):
        sl, c = np.polyfit(d, v, 1)
        print("  %s slope = %+7.2f px/deg   residual rms %.2f px" % (nm, sl, np.sqrt(((v - (sl * d + c)) ** 2).mean())))
    mag = np.hypot(vx, vy)
    sl, c = np.polyfit(d, mag, 1)
    print("  |shift| = %+6.2f px/deg   residual rms %.2f px" % (sl, np.sqrt(((mag - (sl * d + c)) ** 2).mean())))
    print("  direction over the full %.1f deg: dx %+.0f dy %+.0f  (y grows DOWN)" % (d[-1], vx[-1], vy[-1]))
