# 2026-08-29 — The spawn wall falls: prefabs, the goat rig, and a steerable pane

**TL;DR: runtime mesh spawning in RE8 is SOLVED, and with it the mirror's pane is finally
steerable — the project's named linchpin. Recipe: shipped `.pfb` prefab + game thread +
non-item family. Working pane angles found by hand: pitch 90°, yaw 135° (baked as defaults).**

Full evidence trail: dev-archive `recon/2026-08-29-prefab-spawning-goat-rig-steerable-pane/`
(report + 6 screenshots). Code: staging `c4052d3` → HEAD (P-series buttons P0–P10).

## The mechanism (reusable in any RE Engine game)

`sdk.create_instance("via.Prefab", true)` + `.ctor()` → `set_Path("<game-relative .pfb>")`
→ `get_Exist` → reflect the `instantiate` overloads → `instantiate(via.vec3, via.Folder)`.
Three conditions, each proven by its own controlled failure:

1. **Call it on the GAME THREAD** (`re.on_pre_application_entry("UpdateBehavior")`).
   From the UI/render thread the shell spawns with an empty component list and the engine
   reaps it at frame 2 — construction of the prefab's contents never runs.
2. **Non-item prefabs only.** Item-family props (the `*_detailsearch` inspection models)
   build correctly on the game thread, draw for one frame, then the item system reaps them
   at frame 3. Environment props survive indefinitely.
3. **Wake it.** Cutscene/dynamic props can be born `DrawSelf=false`.

Death diagnosis pattern worth keeping: birth census (read components in the same instant
as the spawn) + a per-frame death-watch logging the exact frame `get_Valid` flips. The
frame number separates "rejected at registration" (2) from "reaped by a manager" (3) from
"survives" — three different suspects, one integer.

## The goat rig

`sm80_382_totemeveryware_00_swing.pfb` (the goat totem) spawns, survives, renders, adopts
as the rig, hosts the `via.render.Mirror`, and — the whole point — **the pane follows it**:
parked ahead of the barrel it photographs the rifle's own scope tube; pitch/yaw slider
changes change the image live. Position sliders barely matter (planar mirrors are all about
orientation — hand-mirror intuition holds). Mirror content reaches the glass through the
compositor at PiP-level perceived quality.

## Lessons

- **The host must be inert or hidden.** The goat carries real shatter logic; one accidental
  shot killed the pane and degraded the glass to stale viewer-dependent glitches. (Possible
  side effect flagged: the goat-challenge counter, if it is a plain counter and not
  per-location flags. User to check the records screen.)
- **A per-frame retry of a scene-wide scan needs a throttle**: rifle holstered + drive on =
  941-mesh snapshot scans at ~140/s until fixed. A cache miss must not mean "scan again
  next frame".
- **Research leads must be censused before celebrated**: the "Capcom-assembled mirror
  prefab" (`c22e500_00_mirror.pfb`) is a cutscene MOVIE PLAYER (`via.movie.Movie` +
  `app.MovieApp`). Its survival proved the recipe; its contents falsified the guess.
- **Button naming**: "P10" was mistaken for F10 mid-session (F10 = the plugin's flat-overlay
  toggle, which then "removed the PiP"). Menu buttons should not share names with key rows;
  the numpad-only hotkey rule earns its keep again.

## Open problems, ranked

1. **Grading** — the mirror is raw pre-tonemap HDR (darks fine, brights blown). Plan:
   reflect MainCamera's live exposure/tonemap component values per frame into the
   compositor shader. Interim: numpad 8/2 exposure in MIRROR mode.
2. **Host of record** — hide the goat mesh once aimed (does the RT survive a hidden host?
   the inherited M18 question) or find an inert prefab host.
3. **Zeroing** — park the clip plane behind the scope, bore-sight the view, then the
   in-headset pass.
