"""re8pad.py - a virtual Xbox pad for Resident Evil Village (ViGEm via vgamepad), kept alive between steps.

    python re8pad.py serve                    run the pad; reads steps from re8pad_cmd.txt (one per line), forever
    steps:  tap <button> [ms]                 a/b/x/y/lb/rb/start/back/up/down/left/right/ls/rs
            lt <ms> | rt <ms>                 hold a trigger
            aimfire <aim ms> <fire ms>        LT held, RT pressed during it
            wait <ms>
"""
import os, sys, time
import vgamepad as vg

HERE = os.path.dirname(os.path.abspath(__file__))   # the command file sits beside this script
CMD = os.path.join(HERE, "re8pad_cmd.txt")
B = vg.XUSB_BUTTON
BUTTONS = {"a": B.XUSB_GAMEPAD_A, "b": B.XUSB_GAMEPAD_B, "x": B.XUSB_GAMEPAD_X, "y": B.XUSB_GAMEPAD_Y,
           "lb": B.XUSB_GAMEPAD_LEFT_SHOULDER, "rb": B.XUSB_GAMEPAD_RIGHT_SHOULDER, "start": B.XUSB_GAMEPAD_START,
           "back": B.XUSB_GAMEPAD_BACK, "up": B.XUSB_GAMEPAD_DPAD_UP, "down": B.XUSB_GAMEPAD_DPAD_DOWN,
           "left": B.XUSB_GAMEPAD_DPAD_LEFT, "right": B.XUSB_GAMEPAD_DPAD_RIGHT, "ls": B.XUSB_GAMEPAD_LEFT_THUMB,
           "rs": B.XUSB_GAMEPAD_RIGHT_THUMB}


def step(pad, line):
    p = line.split()
    if not p:
        return
    c = p[0]
    ms = lambda i, d: int(p[i]) / 1000.0 if len(p) > i else d
    if c == "tap":
        pad.press_button(BUTTONS[p[1]]); pad.update(); time.sleep(ms(2, 0.12))
        pad.release_button(BUTTONS[p[1]]); pad.update()
    elif c in ("lt", "rt"):
        (pad.left_trigger if c == "lt" else pad.right_trigger)(255); pad.update(); time.sleep(ms(1, 0.2))
        (pad.left_trigger if c == "lt" else pad.right_trigger)(0); pad.update()
    elif c == "aimfire":
        pad.left_trigger(255); pad.update(); time.sleep(ms(1, 0.6))
        pad.right_trigger(255); pad.update(); time.sleep(ms(2, 0.15))
        pad.right_trigger(0); pad.update(); time.sleep(0.3)
        pad.left_trigger(0); pad.update()
    elif c == "wait":
        time.sleep(ms(1, 0.5))
    print(time.strftime("%H:%M:%S"), "done:", line, flush=True)


def serve():
    pad = vg.VX360Gamepad()
    pad.reset(); pad.update()
    print("pad up", flush=True)
    open(CMD, "w").close()
    while True:
        with open(CMD, encoding="utf-8") as f:
            lines = f.read().splitlines()
        if lines:
            open(CMD, "w").close()
            for ln in lines:
                step(pad, ln.strip())
        time.sleep(0.05)


if __name__ == "__main__":
    serve()
