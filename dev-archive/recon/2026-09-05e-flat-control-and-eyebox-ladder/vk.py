"""Send an arbitrary virtual key to the RE Village window.

re8drive.py's `num` only covers the numpad digits (0x60+n). The scope panel also
binds VK_DECIMAL (0x6E, "re-arm mirror latch") and VK_MULTIPLY (0x6A, "bind
glass"), which the cold order needs. Same mechanism: virtual key, not scancode,
because the plugin polls GetAsyncKeyState.

    python vk.py decimal
    python vk.py multiply
    python vk.py 0x6B
"""
import ctypes
import importlib.util
import sys
import time

TOOLKIT = r"C:\Users\TD3KX\github-backups\flat-to-vr-RE-toolkit\tools\game-harness.py"
spec = importlib.util.spec_from_file_location("harness", TOOLKIT)
H = importlib.util.module_from_spec(spec)
spec.loader.exec_module(H)

DRIVE = r"C:\Users\TD3KX\re-village-scope-vr\dev-archive\tools\re8drive.py"
spec2 = importlib.util.spec_from_file_location("re8drive", DRIVE)
D = importlib.util.module_from_spec(spec2)
spec2.loader.exec_module(D)

NAMES = {
    "decimal": 0x6E, "dot": 0x6E, "period": 0x6E,
    "multiply": 0x6A, "star": 0x6A,
    "add": 0x6B, "plus": 0x6B,
    "subtract": 0x6D, "minus": 0x6D,
    "divide": 0x6F, "slash": 0x6F,
    "f9": 0x78,
}

u = ctypes.windll.user32


def send_vk(vk, hold=0.07):
    down = H.INPUT(type=H.INPUT_KEYBOARD, u=H._I(ki=H.KEYBDINPUT(vk, 0, 0, 0, None)))
    up = H.INPUT(type=H.INPUT_KEYBOARD, u=H._I(ki=H.KEYBDINPUT(vk, 0, H.KEYEVENTF_KEYUP, 0, None)))
    u.SendInput(1, ctypes.byref(down), ctypes.sizeof(H.INPUT))
    time.sleep(hold)
    u.SendInput(1, ctypes.byref(up), ctypes.sizeof(H.INPUT))
    time.sleep(0.25)


if __name__ == "__main__":
    arg = sys.argv[1].lower()
    vk = NAMES.get(arg)
    if vk is None:
        vk = int(arg, 16) if arg.startswith("0x") else int(arg)
    hwnd, title = D.find_window()
    if not H.focus(hwnd):
        print("WARNING: could not foreground", title)
    send_vk(vk)
    print("sent VK 0x%02X (%s)" % (vk, arg))
