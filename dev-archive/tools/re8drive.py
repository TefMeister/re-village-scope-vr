"""
re8drive.py - drive Resident Evil Village + REFramework + the scope plugin/Lua from outside.

Same mechanism as visceral-re2-vr/dev-archive/tools/re2drive.py (RE Engine, REFramework):
BitBlt capture, scancode keys for the game's keyboard path, numpad by VIRTUAL KEY for the
plugin's GetAsyncKeyState polling, the REFramework log as the state oracle. New here:
    cmd <line...>   write one line into reframework\\data\\re_scope_cmd.txt, which
                    re8_scope_harness.lua applies within 0.5 s (pitch/yaw/dpitch/dyaw/
                    steer/ads/status) and echoes as "harness: ..." + a "sliders:" line.

Usage:
    python re8drive.py shot out.png
    python re8drive.py key enter|space|w|s|esc|... [--repeat N]
    python re8drive.py num 7
    python re8drive.py cmd "dpitch 5"
    python re8drive.py wait-log "<needle>" 60
    python re8drive.py tail 40 [filter]
    python re8drive.py close
"""
import ctypes, ctypes.wintypes as w, importlib.util, os, sys, time

TOOLKIT = r"C:\Users\TD3KX\github-backups\flat-to-vr-RE-toolkit\tools\game-harness.py"
GAME = r"C:\Steam\steamapps\common\Resident Evil Village BIOHAZARD VILLAGE"
LOG = os.path.join(GAME, "re2_framework_log.txt")   # the fork names it re2_ for every RE game
CMD = os.path.join(GAME, "reframework", "data", "re_scope_cmd.txt")
WINDOW = "RESIDENT EVIL VILLAGE"
MARK = os.path.join(os.environ.get("TEMP", "."), "re8drive.logmark")

spec = importlib.util.spec_from_file_location("harness", TOOLKIT)
H = importlib.util.module_from_spec(spec); spec.loader.exec_module(H)

EXTRA = {"1": (0x02, False), "2": (0x03, False), "3": (0x04, False), "4": (0x05, False),
         "r": (0x13, False), "e": (0x12, False), "f": (0x21, False), "insert": (0x52, True)}
H.KEYS.update(EXTRA)
u = ctypes.windll.user32


def find_window():
    found = []
    @ctypes.WINFUNCTYPE(ctypes.c_bool, w.HWND, w.LPARAM)
    def cb(hh, l):
        n = u.GetWindowTextLengthW(hh)
        if n and u.IsWindowVisible(hh):
            b = ctypes.create_unicode_buffer(n + 1); u.GetWindowTextW(hh, b, n + 1)
            t = b.value
            if t.upper().startswith(WINDOW) or t.upper().startswith("RESIDENT EVIL VILLAGE"):
                found.append((hh, t))
        return True
    u.EnumWindows(cb, 0)
    if not found: raise SystemExit("no game window (title starting with %r)" % WINDOW)
    return found[0]


def num(n, hold=0.07):
    vk = 0x60 + int(n)
    down = H.INPUT(type=H.INPUT_KEYBOARD, u=H._I(ki=H.KEYBDINPUT(vk, 0, 0, 0, None)))
    up = H.INPUT(type=H.INPUT_KEYBOARD, u=H._I(ki=H.KEYBDINPUT(vk, 0, H.KEYEVENTF_KEYUP, 0, None)))
    u.SendInput(1, ctypes.byref(down), ctypes.sizeof(H.INPUT)); time.sleep(hold)
    u.SendInput(1, ctypes.byref(up), ctypes.sizeof(H.INPUT)); time.sleep(0.2)


def log_size():
    try: return os.path.getsize(LOG)
    except OSError: return 0


def mark():
    with open(MARK, "w") as f: f.write(str(log_size()))


def since_mark():
    try: off = int(open(MARK).read().strip())
    except Exception: off = 0
    if off > log_size(): off = 0
    try:
        with open(LOG, "rb") as f:
            f.seek(off); return f.read().decode("utf-8", "replace")
    except OSError:
        return ""


def wait_log(needle, timeout):
    t0 = time.time()
    while time.time() - t0 < timeout:
        if needle in since_mark(): return True
        time.sleep(1.0)
    return False


def tail(n, filt=None):
    try: lines = open(LOG, "r", encoding="utf-8", errors="replace").read().splitlines()
    except OSError: return []
    if filt: lines = [l for l in lines if filt in l]
    return lines[-n:]


if __name__ == "__main__":
    cmd, rest = sys.argv[1], sys.argv[2:]
    if cmd == "mark":
        mark(); print("log mark at", log_size()); sys.exit()
    if cmd == "wait-log":
        ok = wait_log(rest[0], float(rest[1]) if len(rest) > 1 else 60)
        print("FOUND" if ok else "TIMEOUT", rest[0]); sys.exit(0 if ok else 1)
    if cmd == "tail":
        print("\n".join(tail(int(rest[0]) if rest else 40, rest[1] if len(rest) > 1 else None))); sys.exit()
    if cmd == "since":
        print(since_mark()[-int(rest[0]) if rest else -20000:]); sys.exit()
    if cmd == "cmd":
        os.makedirs(os.path.dirname(CMD), exist_ok=True)
        with open(CMD, "a") as f:
            for line in rest: f.write(line + "\n")
        print("queued:", rest); sys.exit()
    hwnd, title = find_window()
    if cmd == "close":
        u.PostMessageW(hwnd, 0x0010, 0, 0)
        for _ in range(40):
            time.sleep(1)
            if not u.IsWindow(hwnd): print("closed"); sys.exit()
        print("still open after 40 s"); sys.exit(1)
    if cmd == "state":
        r = w.RECT(); u.GetWindowRect(hwnd, ctypes.byref(r))
        print("title=%r rect=(%d,%d)-(%d,%d) iconic=%d" % (title, r.left, r.top, r.right, r.bottom, u.IsIconic(hwnd))); sys.exit()
    if not H.focus(hwnd): print("WARNING: could not foreground", title)
    if cmd == "shot":
        H.grab(hwnd).save(rest[0]); print("saved", rest[0])
    elif cmd == "key":
        rep = int(rest[rest.index("--repeat") + 1]) if "--repeat" in rest else 1
        for _ in range(rep): H.tap(rest[0], settle=0.5)
        print("tapped", rest[0], "x", rep)
    elif cmd == "hold":
        H.hold(rest[0], float(rest[1])); print("held", rest[0], rest[1])
    elif cmd == "num":
        num(rest[0]); print("numpad", rest[0])
    elif cmd == "watch":
        ds = H.watch(hwnd, 6, 0.4)
        print("deltas:", ["%.2f" % x for x in ds], "->", "RENDERING" if max(ds) > 1.0 else "STATIC")
    else:
        raise SystemExit("unknown command " + cmd)
