# 2026-09-05i — Two probes built, so one launch answers more (`/lm`, home PC, NO LAUNCH)

**Lane:** `/lm re village scope`, home PC, 20:10–20:55. **The game was not launched.** Nothing in
this note was run; every claim here is `[compile-verified]` or static reasoning, and it is written
that way on purpose.

Source: `staging` `683ac5a`. Deployed to the game folder with dated backups
(`*.pre-rx-probe-backup-2026-09-05i`) and hash-verified — producer **315,534 B**, harness
**9,047 B**. **Plugin untouched** (149,504 B), so no rebuild and no relaunch cost.

## Why this exists

The board came into this session with **no `[PD]` rows and six `[FLAT]` rows**, i.e. nothing could
move without the game running. That is true of the *questions*, but it was not true of the
*instruments*: two of those rows could only be answered by a human staring at the scope glass, and
one of them could not be reached from a driven session at all. So the work available with the game
closed was to make the next launch answer more per launch — which is the whole economics of this
project, where a launch costs a cold start and, in VR, costs Tefa putting a headset on.

## RX — a reflection read that says what `mirror_env.rtex` actually is

`fn probe_rtex`, published on the harness command table.

The row it serves: the shipped inventory contains
`mastermaterial/textures/rendertarget/mirror_env.rtex`, a target **the engine already owns**, named
for mirror rendering. The `via.render.Mirror` candidate's stated weak point has always been that a
render target *we* create shows nothing — "backing needs pipeline registration not yet found"
(2026-08-24). A target the engine registers itself is exactly the trick that made the movie `.rtex`
route work, pointed at the lead that most needs it.

What it does, path by path — `mirror_env`, the six `systems/rendering/{xn,xp,yn,yp,zn,zp}` cube
faces, and both movie targets:

- **It enumerates the getters instead of guessing them.** It walks the type's methods and calls only
  the zero-argument ones returning a value type or a string. This is a direct lesson from earlier
  today, when a probe guessed seven accessor names on `via.render.TextureResourceHolder` and found
  **all seven absent** — a result that says nothing about the object and everything about the guess.
- **The value-type restriction is a safety rule, not a style one.** A zero-arg getter returning a
  primitive is a field read; one returning an object may construct. `pcall` catches a Lua error, but
  it does not catch an access violation, and a recon probe must not be the thing that takes the game
  down.
- **`movie_1280_720` is read LAST, as a control.** Its true descriptor is already known from the
  native D3D12 hook: **1280×728, `R8G8B8A8_UNORM_SRGB`, `ALLOW_RENDER_TARGET`**
  `[verified-live 2026-08-24]`. If that line comes back nil, or disagrees with those numbers, the
  probe is reading nothing and **every negative above it is void**. The log says so in as many
  words, because the reader will be me at some later date, in a hurry.

**⚠️ What it cannot see, stated rather than glossed.** The D3D12 `ALLOW_RENDER_TARGET` flag does
not come through reflection — it lives on the allocation, and the only thing that reads it is the
plugin's `CreateCommittedResource` hook (F6, `hook::arm_and_trigger`). For an **engine-owned**
resource that is already resident, `create_resource` hands back the engine's copy and **allocates
nothing**, so F6 would see nothing either. That absence is suggestive but it is an absence, and
absences are not evidence on their own. **Dimensions and format are the discriminator this probe can
honestly give:** a screen-shaped 2D target is the Mirror lead alive; a small square matching the
cube faces is a static environment capture and the lead dies.

Also worth recording: the release list writes these as `<path>.rtex.5`. The `.5` is the resource
version and `create_resource` does not take it — the known-good `movie_1280_720` path proves the
un-suffixed form is right.

## RT switch — the sharpness comparison inside one launch

`fn rtex_1920` / `fn rtex_1280`.

The row asks whether the 1920×1080 target looks **sharper** than 1280×720. It is in use and latched
`[verified-live 2026-09-05, n=2]`, but nobody has yet looked at *detail* rather than geometry. Until
now the only way to see the other one was to edit the script and relaunch — and **an eye comparing
two pictures ten minutes apart across a reload is not comparing much.** This reorders the existing
candidate list, so it is two commands in one launch.

Deliberately narrow: both entries are 16:9, both already pass the plugin's `looks_like_mirror_target`
latch, so the aspect path and the latch are untouched. The fallback still applies either way, so a
bad path cannot leave the scope with no source.

**⚠️ `movie_1144_1048.rtex` is NOT offered, and that is the considered call.** The dossier suggests
it, and the arithmetic is genuinely attractive — a circular scope picture wastes most of a 16:9
target's pixels, and 1144×1048 inscribes a ~1048 px circle against 1920×1080's ~1080, near-identical
detail from **half** the pixels. But it is near-square, and both `st.aspect_val` and the latch's
size window are written around 16:9. That is a change to the **working display path**, on the day
the display path first started working, immediately before the VR run that tests something else
entirely. It gets its own session and its own row, not a ride-along on a knob.

## And one gap closed that nobody had noticed

`sc_bind_next` — the SC module that cycles candidate engine textures onto the glass, the *by-eye*
version of the same `mirror_env` question — **was a panel button only.** A driven session, which is
every `/lm` session now, could not reach it. It is on the fn table as `sc_next`.

This is a small thing with a general shape worth keeping: **the automation profile grew faster than
the script's own entry points did.** Anything reachable only from the REFramework panel is invisible
to a session where nobody is at the mouse, and there is no error to tell you so.

## What is NOT established

- **Nothing here has been run.** `luac` clean on both files and both numerical suites still green
  (61 and 71 checks, 0 failed) `[compile-verified 2026-09-05]` — that is a statement about syntax
  and about the steering maths, and about nothing else.
- Whether `mirror_env.rtex` resolves at all is unknown. `create_resource` may return nil for it, in
  which case the lead dies cheaply, which is still a result.
- The RT switch's teardown path (`fn destroy_rig` → `numpad .` → cold order) is **assembled from
  steps each proven separately**, never run as this sequence `[hypothesis]`.

## Automation capabilities (§5a), unchanged this session — none were exercised

1. **menu→gameplay** — proven in flat `[verified-live 2026-09-05, n=2]`; **not proven in VR**.
2. **commands** — proven, flat and VR `[verified-live 2026-09-05]`.
3. **character + camera** — partial; the rig drive is proven, general movement is not.
4. **self-close** — proven via `WM_CLOSE` `[verified-live 2026-09-05, n=2]`.

**Screenshots remain dead in VR** — the desktop window never repaints, so the log is the only
oracle there `[verified-live 2026-09-05, n=1]`. That is precisely why RX reports to the log.
