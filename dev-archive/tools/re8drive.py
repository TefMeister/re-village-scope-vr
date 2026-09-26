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
    python re8drive.py boot [timeout]   launch if needed, then title -> Continue -> Yes -> F, by watching the screen
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


# The scope plugin polls GetAsyncKeyState, so numpad keys must go as VIRTUAL KEYS.
# Until 2026-09-05 this helper handled the DIGITS only (0x60+n), which meant the two
# keys the cold order actually needs -- numpad . (re-arm the mirror latch) and
# numpad * (bind the glass) -- had to be sent as the arithmetic "num 14" and
# "num 10". That works, and it is exactly the kind of thing that gets mistyped once
# and costs a launch, so they have names now. The old numeric form still works.
NUMPAD_VK = {
    ".": 0x6E, "decimal": 0x6E, "dot": 0x6E,
    "*": 0x6A, "multiply": 0x6A, "star": 0x6A,
    "+": 0x6B, "add": 0x6B, "plus": 0x6B,
    "-": 0x6D, "subtract": 0x6D, "minus": 0x6D,
    "/": 0x6F, "divide": 0x6F, "slash": 0x6F,
}


def num(n, hold=0.07):
    key = str(n).strip().lower()
    vk = NUMPAD_VK.get(key)
    if vk is None:
        vk = 0x60 + int(key)
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


# ---- boot: launch (if needed) and get into gameplay by WATCHING the screen (2026-09-26) ------------
# Tefa: "there is a lot of waiting time between button presses". The old route slept fixed 25 s / 30 s
# between keys. This one grabs the window every POLL_S and presses the key for the screen it sees, the
# moment it appears. Three small grey patches (cut from our own screenshots, kept OFF GitHub in
# TEMPLATE_DIR because they are pictures of the game's UI) tell the screens apart; measured mean
# differences: own screen 0.0-0.4, every other screen 25+ (logo: 15 on an animated menu frame).
TEMPLATE_DIR = r"D:\RE Village REFramework builds\driver-templates"
BOOT_SCREENS = {   # name: (box in the 1920-wide window grab, match threshold)
    "load_prompt": ((770, 545, 1150, 595), 8.0),     # "Load most recent saved data?" -> Yes = w, f
    "f_continue":  ((870, 1300, 1060, 1345), 8.0),   # the loading card's "F Continue" -> f
    "title_start":   ((870, 780, 1050, 830), 7.0),   # title screen "Start Game" -> enter
    "menu_continue": ((890, 845, 1030, 885), 7.0),   # main menu with Continue highlighted -> f
}   # (the VILLAGE logo alone matched both the title and the menu: not used)
POLL_S = 0.5
NUDGE_S = 2.0          # before the menu: press enter this often to skip the intro / title
GAMEPLAY_NEEDLES = ("rifle in hand", "autostart: DONE")   # log lines that mean we are playing
LAUNCH_BAT = os.path.join(GAME, "LAUNCH-VILLAGE.bat")


def which_screen(img, tpl):
    from PIL import ImageChops, ImageStat
    g = img.convert("L")
    for name, (box, thr) in BOOT_SCREENS.items():
        if ImageStat.Stat(ImageChops.difference(g.crop(box), tpl[name])).mean[0] < thr:
            return name
    return None


REF_MENU = ((60, 120, 400, 190), 10.0)   # REFramework's own menu, open on start (Insert toggles it)


def close_ref_menu(hwnd):
    from PIL import Image, ImageChops, ImageStat
    t = Image.open(os.path.join(TEMPLATE_DIR, "ref_menu.png"))
    box, thr = REF_MENU
    d = ImageStat.Stat(ImageChops.difference(H.grab(hwnd).convert("L").crop(box), t)).mean[0]
    if d < thr:
        H.tap("insert", settle=0.3); print("closed REFramework's menu (match %.1f)" % d)


def boot(timeout=180.0):
    from PIL import Image
    tpl = {k: Image.open(os.path.join(TEMPLATE_DIR, k + ".png")) for k in BOOT_SCREENS}
    t0 = time.time()
    mark()
    try:
        hwnd, _ = find_window()
    except SystemExit:
        import subprocess
        subprocess.Popen(["cmd", "/c", LAUNCH_BAT], cwd=GAME)
        print("launched")
        hwnd = None
    while hwnd is None and time.time() - t0 < timeout:
        time.sleep(1.0)
        try: hwnd, _ = find_window()
        except SystemExit: pass
    if hwnd is None: print("TIMEOUT no window"); sys.exit(1)
    # (no "LOCK" line exists in this build's log: the old route's wait-log for it always ran out)
    menu_seen, cont_pressed, last_nudge, last = False, None, 0.0, None
    while time.time() - t0 < timeout:
        log = since_mark()
        if any(n in log for n in GAMEPLAY_NEEDLES) and cont_pressed:
            close_ref_menu(hwnd); print("PLAYING after %.0f s" % (time.time() - t0)); return
        if u.GetForegroundWindow() != hwnd: H.focus(hwnd)   # focus costs 0.4 s: only when lost
        s = which_screen(H.grab(hwnd), tpl)
        if s != last: print("%5.1f s  screen: %s" % (time.time() - t0, s)); last = s
        if s == "load_prompt":
            H.tap("w", settle=0.3); H.tap("f", settle=0.8)
        elif s == "f_continue":
            H.tap("f", settle=0.8); cont_pressed = cont_pressed or time.time()
        elif s == "title_start":
            H.tap("enter", settle=1.0)
        elif s == "menu_continue":
            menu_seen = True; H.tap("f", settle=1.0)
        elif not menu_seen and time.time() - last_nudge > NUDGE_S:
            H.tap("enter", settle=0.2); last_nudge = time.time()
        elif cont_pressed and time.time() - cont_pressed > 8.0:
            close_ref_menu(hwnd); print("PLAYING (no gameplay log line; nothing on screen to press) after %.0f s" % (time.time() - t0)); return
        time.sleep(POLL_S)
    print("TIMEOUT at screen", last); sys.exit(1)


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
    if cmd == "boot":
        boot(float(rest[0]) if rest else 180.0); sys.exit()
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
