"""Click inside the game window using CLIENT coordinates (which equal screenshot
pixels here, client is 1920x1080).

Uses SendInput with MOUSEEVENTF_ABSOLUTE, which is what REFramework's ImGui
actually sees; the legacy mouse_event() path moved the cursor and produced a
correct HOVER but its button events never registered as a click.

Usage: python click2.py <client_x> <client_y> [hold_seconds]
"""
import ctypes, ctypes.wintypes as w, importlib.util, sys, time

TOOLKIT = r"C:\Users\TD3KX\github-backups\flat-to-vr-RE-toolkit\tools\game-harness.py"
spec = importlib.util.spec_from_file_location("harness", TOOLKIT)
H = importlib.util.module_from_spec(spec); spec.loader.exec_module(H)
u = ctypes.windll.user32

MOUSEEVENTF_MOVE, MOUSEEVENTF_ABSOLUTE = 0x0001, 0x8000
MOUSEEVENTF_LEFTDOWN, MOUSEEVENTF_LEFTUP = 0x0002, 0x0004


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


def send(flags, nx=0, ny=0):
    i = H.INPUT(type=H.INPUT_MOUSE,
                u=H._I(mi=H.MOUSEINPUT(nx, ny, 0, flags, 0, None)))
    u.SendInput(1, ctypes.byref(i), ctypes.sizeof(H.INPUT))


hwnd = find_window()
cx, cy = int(sys.argv[1]), int(sys.argv[2])
hold = float(sys.argv[3]) if len(sys.argv) > 3 else 0.20

pt = w.POINT(0, 0); u.ClientToScreen(hwnd, ctypes.byref(pt))
sx, sy = pt.x + cx, pt.y + cy
sw, sh = u.GetSystemMetrics(0), u.GetSystemMetrics(1)
nx, ny = int(sx * 65535 / (sw - 1)), int(sy * 65535 / (sh - 1))

H.focus(hwnd)
time.sleep(0.2)
send(MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE, nx, ny)
time.sleep(0.35)            # let ImGui see the hover on its own frame
send(MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_ABSOLUTE, nx, ny)
time.sleep(hold)            # down and up must straddle at least one frame
send(MOUSEEVENTF_LEFTUP | MOUSEEVENTF_ABSOLUTE, nx, ny)
time.sleep(0.4)
print("clicked client (%d,%d) -> screen (%d,%d) norm (%d,%d) hold=%.2f"
      % (cx, cy, sx, sy, nx, ny, hold))
