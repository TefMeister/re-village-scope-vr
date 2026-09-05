"""The 0.5-degree pitch sweep the board asked for.

The 2026-09-05 5-degree sweep replaced the picture at every step, so no
pixels-per-degree slope could be fitted. This one steps by 0.5 degrees, which
should keep enough overlap between consecutive frames for phase correlation.

Two frames are captured at every step so the scene-animation noise floor is
measurable at each one, not assumed.
"""
import importlib.util
import os
import time

DRIVE = r"C:\Users\TD3KX\re-village-scope-vr\dev-archive\tools\re8drive.py"
spec = importlib.util.spec_from_file_location("re8drive", DRIVE)
D = importlib.util.module_from_spec(spec)
spec.loader.exec_module(D)
H = D.H

OUT = r"C:\Users\TD3KX\AppData\Local\Temp\claude\C--Steam-steamapps-common\f9a9208a-d9a3-4409-b891-2ea19c978b48\scratchpad\lm\sweep"
os.makedirs(OUT, exist_ok=True)

hwnd, title = D.find_window()
H.focus(hwnd)


def cmd(line):
    with open(D.CMD, "a") as f:
        f.write(line + "\n")
    time.sleep(1.2)          # the harness polls twice a second


def shot(name):
    H.focus(hwnd)
    time.sleep(0.4)
    p = os.path.join(OUT, name)
    H.grab(hwnd).save(p)
    return p


# park at the baseline and let it settle
cmd("steer 0")
cmd("pitch 180")
cmd("yaw 90")
time.sleep(2.0)
print("baseline parked at pitch 180 yaw 90, steering off")

steps = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5]
for i, deg in enumerate(steps):
    if i > 0:
        cmd("dpitch 0.5")
    time.sleep(1.5)
    a = shot("p%04.1f-a.png" % deg)
    time.sleep(1.0)
    b = shot("p%04.1f-b.png" % deg)
    print("pitch +%.1f  ->  %s , %s" % (deg, os.path.basename(a), os.path.basename(b)), flush=True)

# return to the baseline: a repeatability control
cmd("pitch 180")
time.sleep(2.0)
shot("back-p180.png")
print("returned to pitch 180, captured back-p180.png")
print("DONE")
