"""scope_metrics.py - sharpness (edge energy) and roll (dominant gradient orientation)
inside a circular crop of a game capture.

Usage:
    python scope_metrics.py CX CY R img1.png [img2.png ...]

CX, CY, R = the scope circle centre and radius in capture pixels.
Prints, per image: mean luminance, Laplacian variance, gradient energy (both normalised by
mean so exposure differences do not masquerade as sharpness), and the dominant edge
orientation in degrees (structure tensor, 0 = vertical edges, +90 = horizontal) with its
coherence (0..1; below ~0.15 is noise).
"""
import sys
import numpy as np
from PIL import Image


def load_gray(path):
    im = Image.open(path).convert("L")
    return np.asarray(im, dtype=np.float64)


def circle_mask(shape, cx, cy, r):
    yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
    return ((xx - cx) ** 2 + (yy - cy) ** 2) <= (r * r)


def metrics(g, mask):
    gx = np.zeros_like(g)
    gy = np.zeros_like(g)
    gx[:, 1:-1] = (g[:, 2:] - g[:, :-2]) * 0.5
    gy[1:-1, :] = (g[2:, :] - g[:-2, :]) * 0.5
    lap = np.zeros_like(g)
    lap[1:-1, 1:-1] = (g[:-2, 1:-1] + g[2:, 1:-1] + g[1:-1, :-2] + g[1:-1, 2:] - 4.0 * g[1:-1, 1:-1])
    m = mask
    mean = g[m].mean()
    if mean < 1e-6:
        mean = 1e-6
    lap_var = lap[m].var() / (mean * mean)
    grad_e = np.sqrt(gx[m] ** 2 + gy[m] ** 2).mean() / mean
    # structure tensor for orientation
    jxx = (gx[m] ** 2).sum()
    jyy = (gy[m] ** 2).sum()
    jxy = (gx[m] * gy[m]).sum()
    theta = 0.5 * np.degrees(np.arctan2(2.0 * jxy, jxx - jyy))
    tr = jxx + jyy
    coh = 0.0 if tr < 1e-9 else np.sqrt((jxx - jyy) ** 2 + 4.0 * jxy ** 2) / tr
    return mean, lap_var, grad_e, theta, coh


def main():
    if len(sys.argv) < 5:
        print(__doc__)
        return 2
    cx, cy, r = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
    print("%-40s %8s %10s %10s %8s %6s" % ("image", "mean", "lapvar", "gradE", "theta", "coh"))
    for path in sys.argv[4:]:
        g = load_gray(path)
        m = circle_mask(g.shape, cx, cy, r)
        mean, lv, ge, th, coh = metrics(g, m)
        print("%-40s %8.1f %10.5f %10.5f %8.1f %6.2f" % (path[-40:], mean, lv, ge, th, coh))
    return 0


if __name__ == "__main__":
    sys.exit(main())
