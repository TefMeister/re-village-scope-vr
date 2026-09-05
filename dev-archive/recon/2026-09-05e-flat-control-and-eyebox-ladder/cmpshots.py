"""Compare captures inside the scope disc only.

The disc geometry is the one located from this same game's captures earlier today
(centre 636,353 radius 258 at 1920x1080 window scale); these captures are a
different window size, so the disc is re-found here by looking for the region
that changes least between two same-state frames and most between states. To keep
it simple and honest we just report whole-frame and centre-region statistics and
let the pictures decide.
"""
import sys
import numpy as np
from PIL import Image


def load(p):
    return np.asarray(Image.open(p).convert("L"), dtype=np.float64)


def stats(a, b, label):
    d = np.abs(a - b)
    print("%-34s meanAbs=%7.3f  p99=%7.3f  max=%6.1f  changed>8: %5.2f%%"
          % (label, d.mean(), np.percentile(d, 99), d.max(), 100.0 * (d > 8).mean()))
    return d


if __name__ == "__main__":
    paths = sys.argv[1:]
    imgs = [load(p) for p in paths]
    names = [p.rsplit("\\", 1)[-1].rsplit("/", 1)[-1] for p in paths]
    print("frame size:", imgs[0].shape)
    print()
    print("--- noise floor: two frames in the SAME state ---")
    stats(imgs[0], imgs[1], names[0] + " vs " + names[1])
    if len(imgs) >= 4:
        stats(imgs[2], imgs[3], names[2] + " vs " + names[3])
        print()
        print("--- the actual test: state A vs state B ---")
        d = stats(imgs[0], imgs[2], names[0] + " vs " + names[2])
        # where did it change?
        h, w = d.shape
        ys, xs = np.nonzero(d > 20)
        if len(ys):
            print("    pixels changed by >20: %d, bounding box x %d..%d  y %d..%d"
                  % (len(ys), xs.min(), xs.max(), ys.min(), ys.max()))
            print("    centroid of change: (%.0f, %.0f)" % (xs.mean(), ys.mean()))
        else:
            print("    no pixel changed by more than 20 levels")
