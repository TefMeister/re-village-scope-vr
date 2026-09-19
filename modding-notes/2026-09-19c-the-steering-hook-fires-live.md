# The steering hook fires live — and two ways an automated session can fool itself

**2026-09-19, home PC (RTX), one launch, flat.** Follows on from
`2026-09-19b-the-steering-code-is-written-and-builds.md`.

## The result

**The steering code runs, in the real game, inside the real mirror pass.**
`[verified-live 2026-09-19, n=1 launch]`

```
[VR] Mirror steering #6600: base=eye yaw=0.00 pitch=0.00 deg (source=slider)
     m00=0.9848 m11=1.1696 m20 -0.1736->-0.0000 m21 -0.2111->-0.0000 invert=false hmd=true
```

6,600 projections rewritten in about a minute. Three things fall out of that one line:

- **The hook is the right lever.** §9aq reasoned that the mirror pass goes through
  `VR::on_camera_get_projection_matrix` and that writing there would reach the scope's picture.
  It does. That was the first thing that could have been wrong and it is not.
- **The base matrix is exactly the one predicted.** `m00=0.9848`, `m11=1.1696`,
  `m20=-0.1736`, `m21=-0.2111` — the HMD eye projection §9aq derived the whole smear argument
  from, measured live on 2026-09-12 and now seen again from inside the steering path.
  `[verified-live 2026-09-19, n=1]`
- ⭐ **The placement decision paid for itself.** `VR_ExemptMirrorCameras` is still `true` in the
  config, and the steer ran anyway — because it is checked *before* the exemption. Behind it,
  the exemption's early `return` would have swallowed every write, and the session would have
  recorded "steering does nothing" about code that never executed.

**Also confirmed in passing, from the plugin's own projection dump:** the two eyes really do
carry **mirrored** off-centre shifts, `m20 = -0.1736` and `+0.1736`. That is the exact asymmetry
§9aq says produces a band where one eye smears and the other does not. `[verified-live 2026-09-19, n=1]`

## What is still NOT known

**Whether the drawn frame actually MOVES when the angle changes.** Everything above was captured
with the sliders at 0, where the steer writes `m20 -> 0` — a real change to the matrix, but not a
test of direction. The sweep is still the thing that decides it, and with it the sign, which
remains `[hypothesis]`. Culling is untested too.

## Two traps that made this session look like it was working when it was not

Both matter beyond this project: they are the shape of failure where **a script reports success
and has done nothing**, which is exactly what an unattended session cannot survive.

### 1. `timeout` refuses to run when stdin is redirected

`VR-TRUE-SCOPE.bat` paces itself with `timeout /t N`. Run from a tool with stdin redirected,
`timeout` fails instantly with *"ERROR: Input redirection is not supported"* — **every wait is
skipped**. All four steps then write to `reframework\data\re_scope_cmd.txt` inside one second and
overwrite each other before the plugin polls it, so the `bringup` never happens.

⚠️ **And it still prints every `[n/4]` progress line and exits 0.** Nothing in the output says the
waits did not happen. First run this way produced no rig at all; the log showed the re-arm and the
pane sliders 0.5 s apart when they should have been 48 s apart.

**Fixed by:** a warning block at the top of the `.bat`, and driving the sequence with real sleeps
when it has to run from a script rather than a double-click.

### 2. The window lookup used a title that does not exist

The re-arm step focused the game with `FindWindow(null, 'RESIDENT EVIL VILLAGE')`. The real title
is **`Resident Evil Village`**, so the lookup returned zero, the focus was skipped, and the
keystroke went to whatever window happened to have focus.

⚠️ **It worked anyway — which is worse than failing.** The plugin polls that key globally
(`polled key 0x6E (VR route)`), so the re-arm landed regardless and the bug stayed invisible. On
any machine or any game where the key is read by window message instead, it would simply not work,
with nothing in the log to say why.

**Fixed by:** `scope-rearm-key.ps1`, which finds the game by **process** and says out loud when it
cannot focus it. Related, and the reason this is worth writing down: the standing rule that input
automation should always **layer several methods** rather than trust one — see
`claude-memory/PREFERENCES.md`.

## What was run, for the record

`fn rtex_2560` → numpad `.` (re-arm) → `bringup` → `pitch 90 / yaw 90 / propf 0 / propu 0 /
propr 0.20`, with real waits. `bringup: DONE` at 23:00:03, mirror source latched at
**2560x1448** and upgraded to raw-HDR `fmt=26`, `mirror=1` on the frame lines afterwards.

⚠️ One thing in that log is **not** understood and should not be glossed: at `22:59:35.582` the
source latched at 2560x1448, yet at `.655` the rig-rebuild watcher reported *"latched source is 0
wide"* and then *"no mirror source latched at all … the glass shows the fallback source"*. The two
readings contradict each other inside 80 ms. Either the watcher samples something the latch has not
published yet, or the picture on the glass is not the source we think it is. **Unresolved
`[hypothesis]`** — and it decides whether picture judgements from this session are about the right
texture at all.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
