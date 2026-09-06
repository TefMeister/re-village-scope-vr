"""roll_sweep.py - unattended pane sweep with a capture per step.

Holds the harness aim (ads 1) only for the duration of the sweep and releases it (ads 0)
at the end, whatever happens. Captures land in OUT. Prints the harness echo per step.

    python roll_sweep.py OUT            the 2026-09-06 pitch/yaw sweep (door frame montage)
    python roll_sweep.py OUT roll       the SIMULATED RIFLE ROLL sweep (2026-09-06 /pd build):
                                        `roll 0,5,10,15,20` then back to 0. Each step turns the
                                        whole rig about the bore AND feeds the same degrees to
                                        the plugin's roll_k counter-rotation. Run it once with
                                        roll_k = 0 in re_scope_vr_settings.txt (the raw mirror
                                        law: expected 2x, sign by flip_h/flip_v) and once with
                                        roll_k at the measured coefficient (the null).
    python roll_sweep.py OUT rollpane   only the rig turns (the plugin feed stays at the
                                        measured roll) -- the raw law without touching roll_k
    python roll_sweep.py OUT rollsim    only the plugin feed turns, rig fixed -- shows the
                                        compositor's own rotation direction with roll_k != 0

The harness echoes `roll=`/`rollsim=` on every command, so each capture is matched to the
values that produced it. Read the picture's roll off a straight edge (door frame, roofline).
"""
import os, subprocess, sys, time

DRIVE = r"C:\Users\TD3KX\github-backups\re-village-scope-vr\dev-archive\tools\re8drive.py"
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
MODE = sys.argv[2].lower() if len(sys.argv) > 2 else "pitchyaw"
SETTLE = 1.2
ROLL_STEPS = (5, 10, 15, 20)


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
    if MODE in ("roll", "rollpane", "rollsim"):
        step("base-%s-0" % MODE, "%s 0" % MODE)
        for r in ROLL_STEPS:
            step("%s-%d" % (MODE, r), "%s %d" % (MODE, r))
        step("back-%s-0" % MODE, "%s 0" % MODE)
    else:
        step("base-p180-y90", "pitch 180")
        for p in (185, 190, 195, 200, 205):
            step("pitch-%d" % p, "pitch %d" % p)
        step("back-p180", "pitch 180")
        for y in (95, 100, 105, 110, 115):
            step("yaw-%d" % y, "yaw %d" % y)
        step("back-y90", "yaw 90")
finally:
    if MODE in ("roll", "rollpane", "rollsim"):
        print(drive("cmd", "roll 0"))   # never leave a simulated roll behind
        drive("wait-log", "harness: roll 0", "6")
    print(drive("cmd", "ads 0"))
    drive("wait-log", "harness: ads 0", "6")
    print("aim released")
