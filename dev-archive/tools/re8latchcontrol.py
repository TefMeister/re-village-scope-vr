"""re8latchcontrol.py - the control for the 2026-09-05 mirror-latch fix.

Runs N rig rebuild cycles against a live flat game and prints one row per cycle:
which allocation the plugin latched (from its own log line) and whether the
scope showed a picture (centre-crop mean/stddev of a BitBlt capture in ADS).

Pass criterion, stated up front so the run cannot move it:
  every cycle latches fmt=29 flags=0x1 AND the ADS capture has mean > 40.
  A cycle with NO latch line means the format assumption is wrong for that
  target; a cycle with fmt=26 means the predicate running is not the one built.

Usage: python re8latchcontrol.py <out_dir> [cycles=3] [--first-already-built]
"""
import os, re, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVE = os.path.join(HERE, "re8drive.py")
out = sys.argv[1]
cycles = int(sys.argv[2]) if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else 3
first_built = "--first-already-built" in sys.argv
os.makedirs(out, exist_ok=True)


def drive(*args):
    return subprocess.run([sys.executable, DRIVE, *args], capture_output=True, text=True).stdout


def stats(png):
    from PIL import Image, ImageStat
    s = ImageStat.Stat(Image.open(png).convert("L").crop((620, 150, 1320, 850)))
    return s.mean[0], s.stddev[0]


rows = []
for c in range(1, cycles + 1):
    drive("mark")
    if not (c == 1 and first_built):
        if c > 1:
            drive("cmd", "ads 0"); time.sleep(2)
            drive("cmd", "fn destroy_rig"); time.sleep(3)
        drive("num", "."); time.sleep(1)
        drive("cmd", "fn p10"); time.sleep(5)
        drive("cmd", "fn drive_on"); time.sleep(2)
        drive("num", "*"); time.sleep(3)
    log = drive("since", "60000")
    m = re.findall(r"MIRROR SOURCE latched \(1280-wide\): (\d+x\d+ fmt=\d+ flags=0x\d+)", log)
    latched = m[-1] if m else ("(none this cycle)" if not (c == 1 and first_built) else "(built before script; see cycle-1 line in log)")
    drive("cmd", "ads 1"); time.sleep(5)
    png = os.path.join(out, "latch-control-cycle%d.png" % c)
    drive("shot", png)
    mean, sd = stats(png)
    ok = ("fmt=29 flags=0x1" in latched or (c == 1 and first_built)) and mean > 40
    rows.append((c, latched, mean, sd, "PASS" if ok else "FAIL"))
    print("cycle %d  latched=%-32s  mean=%6.1f  sd=%5.1f  %s" % rows[-1], flush=True)

drive("cmd", "ads 0")
n_pass = sum(1 for r in rows if r[4] == "PASS")
print("RESULT: %d/%d cycles passed" % (n_pass, cycles))
