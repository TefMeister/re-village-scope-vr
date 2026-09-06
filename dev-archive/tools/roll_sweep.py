"""roll_sweep.py - unattended pane pitch/yaw sweep with a capture per step.

Holds the harness aim (ads 1) only for the duration of the sweep and releases it (ads 0)
at the end, whatever happens. Captures land in OUT. Prints the harness echo per step.
"""
import os, subprocess, sys, time

DRIVE = r"C:\Users\TD3KX\github-backups\re-village-scope-vr\dev-archive\tools\re8drive.py"
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
SETTLE = 1.2


def drive(*args):
    r = subprocess.run([sys.executable, DRIVE, *args], capture_output=True, text=True)
    return (r.stdout + r.stderr).strip()


def step(name, cmdline):
    print(drive("cmd", cmdline))
    ok = drive("wait-log", "harness: " + cmdline, "6")
    time.sleep(SETTLE)
    print(drive("shot", os.path.join(OUT, name + ".png")), "|", ok)


os.makedirs(OUT, exist_ok=True)
try:
    print(drive("cmd", "ads 1")); drive("wait-log", "harness: ads 1", "6"); time.sleep(1.5)
    step("base-p180-y90", "pitch 180")
    for p in (185, 190, 195, 200, 205):
        step("pitch-%d" % p, "pitch %d" % p)
    step("back-p180", "pitch 180")
    for y in (95, 100, 105, 110, 115):
        step("yaw-%d" % y, "yaw %d" % y)
    step("back-y90", "yaw 90")
finally:
    print(drive("cmd", "ads 0"))
    drive("wait-log", "harness: ads 0", "6")
    print("aim released")
