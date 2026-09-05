import os, re, subprocess, sys, time
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
    top = ImageStat.Stat(im.crop((760, 160, 1180, 330)))
    lap = ImageStat.Stat(c.filter(ImageFilter.FIND_EDGES))
    return s.mean[0], s.stddev[0], top.mean[0], lap.mean[0]

def compositor_state():
    l = [x for x in drive("since", "4000").splitlines() if "mirror compositor:" in x]
    if not l: return "(no compositor line)"
    m = re.search(r"wb=([\d.]+).*?atmo=(\d) skyThresh=([\d.]+)", l[-1])
    return "atmo=%s skyThresh=%s wb=%s" % (m.group(2), m.group(3), m.group(1)) if m else l[-1][-80:]

# ---- ladder: 7 presses of numpad 9, capture each rung (already in ADS) ----
print("== ladder on the current (1280 raw-HDR) source ==", flush=True)
drive("mark")
png = os.path.join(OUT, "ladder-rung0-start.png"); drive("shot", png)
print("start           %-34s mean=%6.1f sd=%5.1f top=%6.1f edge=%5.1f" % ((compositor_state(),) + stats(png)), flush=True)
for i in range(1, 8):
    drive("mark"); drive("num", "9"); time.sleep(1.5)
    st = compositor_state()
    png = os.path.join(OUT, "ladder-press%d.png" % i); drive("shot", png)
    print("press %d         %-34s mean=%6.1f sd=%5.1f top=%6.1f edge=%5.1f" % ((i, st) + stats(png)), flush=True)

# ---- sharpness: switch to 1920 at the same pose ----
print("== 1920 cycle ==", flush=True)
png = os.path.join(OUT, "sharp-1280-ads.png"); drive("shot", png)
print("1280 (kept)     mean=%6.1f sd=%5.1f top=%6.1f edge=%5.1f" % stats(png), flush=True)
drive("mark")
drive("cmd", "ads 0"); time.sleep(2)
drive("num", "."); time.sleep(1)
drive("cmd", "fn destroy_rig"); time.sleep(3)
drive("cmd", "fn rtex_1920"); time.sleep(1)
drive("cmd", "fn p10"); time.sleep(5)
drive("cmd", "fn drive_on"); time.sleep(2)
drive("num", "*"); time.sleep(3)
log = drive("since", "60000")
for x in log.splitlines():
    if any(k in x for k in ("MIRROR SOURCE", "UPGRADED", "REPLACED", "re-arm", "mirror RT: using", "glass: 2 slot")):
        print("   LOG:", x[26:180], flush=True)
drive("cmd", "ads 1"); time.sleep(5)
png = os.path.join(OUT, "sharp-1920-ads.png"); drive("shot", png)
print("1920 (after)    mean=%6.1f sd=%5.1f top=%6.1f edge=%5.1f" % stats(png), flush=True)
