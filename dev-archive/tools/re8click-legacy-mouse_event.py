"""Click inside the game window using CLIENT-area coordinates that match the
BitBlt screenshot, so a point read off a capture can be clicked directly.

Usage:  python click.py <client_x> <client_y>
        python click.py --info
"""
import ctypes, ctypes.wintypes as w, importlib.util, sys, time

TOOLKIT = r"C:\Users\TD3KX\github-backups\flat-to-vr-RE-toolkit\tools\game-harness.py"
spec = importlib.util.spec_from_file_location("harness", TOOLKIT)
H = importlib.util.module_from_spec(spec); spec.loader.exec_module(H)
u = ctypes.windll.user32


def find_window():
    found = []
    @ctypes.WINFUNCTYPE(ctypes.c_bool, w.HWND, w.LPARAM)
    def cb(hh, l):
        n = u.GetWindowTextLengthW(hh)
        if n and u.IsWindowVisible(hh):
            b = ctypes.create_unicode_buffer(n + 1); u.GetWindowTextW(hh, b, n + 1)
            if b.value.upper().startswith("RESIDENT EVIL VILLAGE"):
                found.append(hh)
        return True
    u.EnumWindows(cb, 0)
    if not found:
        raise SystemExit("no game window")
    return found[0]


hwnd = find_window()
cr = w.RECT(); u.GetClientRect(hwnd, ctypes.byref(cr))
pt = w.POINT(0, 0); u.ClientToScreen(hwnd, ctypes.byref(pt))

if "--info" in sys.argv:
    print("client size = %dx%d, client origin on screen = (%d,%d)" %
          (cr.right, cr.bottom, pt.x, pt.y))
    raise SystemExit

cx, cy = int(sys.argv[1]), int(sys.argv[2])
H.focus(hwnd)
sx, sy = pt.x + cx, pt.y + cy
u.SetCursorPos(sx, sy)
time.sleep(0.25)
u.mouse_event(0x0002, 0, 0, 0, 0)   # LEFTDOWN
time.sleep(0.08)
u.mouse_event(0x0004, 0, 0, 0, 0)   # LEFTUP
time.sleep(0.35)
print("clicked client (%d,%d) -> screen (%d,%d)" % (cx, cy, sx, sy))
