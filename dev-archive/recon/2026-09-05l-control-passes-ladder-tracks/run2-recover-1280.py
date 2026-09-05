import os, subprocess, sys, time
HERE = r"C:\Users\TD3KX\re-village-scope-vr\dev-archive\tools"
DRIVE = os.path.join(HERE, "re8drive.py")
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
from PIL import Image, ImageStat, ImageFilter

def drive(*a):
    return subprocess.run([sys.executable, DRIVE, *a], capture_output=True, text=True).stdout

def stats(png):
    im = Image.open(png).convert("L")
    c = im.crop((620, 150, 1320, 850))
    s = ImageStat.Stat(c)
    lap = ImageStat.Stat(c.filter(ImageFilter.FIND_EDGES))
    return s.mean[0], s.stddev[0], lap.mean[0]

def cycle(target, tag):
    drive("mark")
    drive("cmd", "ads 0"); time.sleep(2)
    drive("cmd", "fn destroy_rig"); time.sleep(3)
    drive("cmd", "fn rtex_%s" % target); time.sleep(1)
    drive("cmd", "fn p10"); time.sleep(5)
    drive("cmd", "fn drive_on"); time.sleep(2)
    drive("num", "*"); time.sleep(3)
    log = drive("since", "60000")
    latch = [x[26:170] for x in log.splitlines() if any(k in x for k in ("MIRROR SOURCE", "UPGRADED", "REPLACED"))]
    drive("cmd", "ads 1"); time.sleep(5)
    png = os.path.join(OUT, "cycle-%s.png" % tag); drive("shot", png)
    m, sd, e = stats(png)
    print("cycle %-10s latch lines: %d   mean=%6.1f sd=%5.1f edge=%5.1f" % (tag, len(latch), m, sd, e), flush=True)
    for l in latch: print("    ", l, flush=True)
    return len(latch) > 0

ok1280 = cycle("1280", "1280-recover")
if ok1280:
    ok1920 = cycle("1920", "1920-try2")
    if not ok1920:
        print("1920 did not allocate; scope is on a dead buffer again -- recovering on 1280", flush=True)
        cycle("1280", "1280-recover2")
else:
    print("1280 did not allocate either; picture stays on the dead buffer", flush=True)
