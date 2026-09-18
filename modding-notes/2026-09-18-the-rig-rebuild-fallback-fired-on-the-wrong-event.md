# The rig-rebuild fallback was firing on the wrong event — and could never undo itself

**2026-09-18, dev PC `DESKTOP-V8GTSIR`, `/pd`.**
**The game was NOT launched. Nothing in this note has been run in the game.** Everything below is
static reading, a clean build, and a numeric test suite. The one live claim quoted is the home PC's
headset session of 2026-09-17.

Closes the board row *"the save-reload fallback must tell a reload from `bringup`'s own rig
rebuild"*. Predecessor: `2026-09-17c-the-nine-builds-checked-in-the-headset-two-work-and-one-broke-the-sky.md`
§ the `rb_fb` bullet. Dossier §9aa.

---

## 1. What went wrong, in one paragraph

The Lua bumps a counter (`rig_gen`) whenever it builds the mirror rig's holder. **Two completely
different events do that**, and the 2026-09-16 build could not tell them apart:

| event | does the engine allocate? | does our latch move? | is anything stranded? |
| --- | --- | --- | --- |
| `bringup` — the first rig of a process | **yes** | yes, and the raw-HDR upgrade lands behind it | **no** |
| a save reload | **no** — `sdk.create_resource` returns the engine's cached resource for that path | no | **yes** — the upgraded buffer is a pooled intermediate that may now belong to the old pass |

The rescue written for the second case — drop back to the kept 8-bit resolve, which is path-bound
and therefore follows the new rig — was applied to **both**. On `bringup` it threw away a buffer
that was correct and current: black sky, golden colours, 123 ms after every upgrade
`[verified-live 2026-09-17, n=1 wearer; log n=3 launches]`.

## 2. The part that made it expensive: it could not be undone

`rbfb 0` typed live did not recover the picture, and neither did the panel's latch re-arm. Only a
relaunch did. That was reported on 2026-09-17 as a puzzle; it has a plain structural cause
`[inferred-static 2026-09-18]`:

**The raw-HDR upgrade lives inside the resource-CREATION hook** (`d3d12_hooks.cpp`, the
`else if (!mirror_is_hdr && format == R11G11B10_FLOAT)` branch). It can only run when the engine
*creates* a resource. So "re-arming the upgrade watch" is not a request the plugin can satisfy on
its own — it is a bet that the engine will allocate another fmt-26 target. Once the engine has
finished allocating its pooled HDR intermediates, that call never comes, and the watch waits
forever.

**The lesson, and it generalises past this project:** a fallback that gives something up must be
able to get it back through a path *it* controls. This one gave up the HDR buffer and depended on
the engine volunteering a replacement. That is not a recovery path, it is a hope.

## 3. Why it fired on `bringup` at all — a known race, weaponised

The plugin reads the Lua's pane file on a **~0.25 s poll** (`pane_file.cpp`, `(n % 15) == 7`). The
allocation happens inside the Lua's rig call. So on a *healthy* rebuild the latch has **always**
already moved by the time the rebuild counter reaches the reader.

That race was already documented in the same file, five lines above the fallback, and the rebuild
watch below it already had a test for it — `s_latch_change_frame > 0 && since <= 150 && rigged
width == source width`, which logs *"the latch had already followed … not stranded"*.

**The fallback simply ran first, unconditionally, ahead of that test.** It demoted the source and
then the very next lines classified the same rebuild as healthy. Two correct pieces of code in the
wrong order.

## 4. The fix

The verdict is computed **first**, and everything is gated on it. It now lives in its own pure
header, `plugin/src/rebuild_gate.h` → `rgate::decide()`, following this project's existing pattern
(`hold_math.h`, `crop_follow_math.h`, `scope_geom_math.h`): no D3D, no globals, so the test compiles
**the shipped logic** rather than a transcription of it.

```
already_followed  <=>  the latch moved within kRebuildLatchFollowTicks (150 ticks, ~2.5 s)
                       AND the latched source is the width the Lua says it rigged

fall_back         <=>  NOT already_followed  AND  rb_fb armed
                       AND  the source is the HDR buffer  AND  a kept 8-bit resolve exists
```

The width test is a second, independent signal, not a redundant one: a latch that moved recently
for some unrelated reason but sits at the wrong width is not this rig's.

A rebuild that is held now says so in the log — *"the fallback is armed but HELD … this is what
bringup looks like"* — so the next session can see the discrimination working rather than infer it
from the absence of a line.

### The tests

`plugin/tools/rebuild_gate_test.cpp`, **22 checks, 0 failed** `[verified-numerically 2026-09-18]`:
the bringup timeline, the save-reload timeline, both sides of the window boundary, the wrong-width
case, never-latched, `rbfb 0`, both halves of "nothing to rescue", and that the *reporting* watch
stays independent of the knob.

**⚠️ The test was shown to be able to fail.** The gate was temporarily reverted to the old
unconditional logic and re-run: it failed exactly two checks, *"bringup: NO fallback — this is the
2026-09-17 regression"* and the boundary case that shares its shape. Then restored and re-run
clean. A green suite that has never been red proves nothing.

All nine pre-existing suites still pass unchanged (hold 16, crop_follow 40, geom 124, roll_math 20,
mirror_roll 176, eye_parallax 14, frame_v2 25, tone_curve, prop_offset 5) `[verified-numerically
2026-09-18]`.

## 5. Two shipped defaults changed

- **`rb_fb` 1 → 0.** Off by default even with the rework in place. The rework is compile-verified
  and has never run; the failure it guards against costs a relaunch; and whether the fallback cures
  the save-reload security camera is *still* untested, so there is nothing being given up. `rbfb 1`
  now arms it safely for an A/B inside one launch — which is the thing that was not possible before.
- **`sw_delay` 0 → 1500 ms.** This was one of only two of the nine 2026-09-16 builds that worked in
  the headset, and the wearer made it the boot value on the home PC by hand. **The dev PC's settings
  file has no `sw_delay` line, so this machine was still booting at 0** — the fix existed and was not
  in effect here. Making it the compiled default fixes both machines and any release.

Both numbers are now named constants in `rsv.h` (`kRebuildLatchFollowTicks`,
`kSwitchRestoreDelayMs`) rather than literals, per the code-shape rule.

## 6. What is NOT established

- **The fallback has still never been observed doing its job.** Nothing here tests whether it cures
  the save-reload security camera; it only stops it firing on the wrong event. That test still needs
  a live save reload.
- **A save reload landing within ~2.5 s of an unrelated latch change** would read as "already
  followed" and the fallback would be held. Deliberate trade — holding is recoverable and still
  reported by the watch, firing wrongly is not — but it is untested and unobserved `[hypothesis]`.
- **The diagnostic that would show this rework is wrong rather than merely untuned:** run `bringup`
  with `rbfb 1` and read the log. The expected line is *"rig rebuild #1: the fallback is armed but
  HELD"*. If instead it says *"the latch did NOT follow"* on a fresh `bringup`, the window or the
  width comparison is wrong, not the idea — and `since` is printed in that line, which is the number
  to read.

## 7. Build and deploy

Built with the Visual Studio 2022 toolchain. ⚠️ `cmake` on PATH on this machine is 4.4 while the
cache was generated by VS's bundled 3.31, and the mix fails to configure (`No preprocessor test for
"Renesas"`). Use the bundled one:
`D:/VSBuildTools/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe --build build --config Release`.

Deployed to this machine's install, previous DLL kept alongside as `.bak-2026-09-18`, and
re-stamped with `deployed.sh record`.

⚠️ **`deployed.sh record` REPLACES the whole record, it does not merge.** Passing it one file left
the other thirteen unstamped; recovered from git and re-recorded all fourteen in one call. Worth
knowing before the next single-file deploy — the tool is behaving as written, the trap is that a
partial record still reports `ALL 1 FILE(S) MATCH` and reads like a pass.
