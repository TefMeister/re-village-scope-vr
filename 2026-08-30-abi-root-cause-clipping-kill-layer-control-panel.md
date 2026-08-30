# 2026-08-30 — The ABI root cause, the clipping kill, and the mirror's real control panel

One session, three project-shaping discoveries. Home PC, flat testing, user driving.

## 1. Auto-grading shipped (morning)

- Found the game's live exposure: **`via.render.ToneMapping.get_EV`** on the MainCamera
  GameObject (GR1/GR2 probe; user's bright→dark→bright tour: EV 3.0 outdoors → 2.0 dark
  interior, ~1.5s adaptation glide). Full recon: dev-archive
  `recon/2026-08-30-grading-ev-recon/`.
- Compositor now scales shader exposure by `2^(slope·(2−EV))` — anchored at the indoor
  EV where the user confirmed 1:1; numpad 0 cycles the sunlight slope, 8/2 calibrates.
- Numpad settings (flips, exposure, slope, evAuto, crop) now **persist** to
  `reframework\re_scope_vr_settings.txt` — the recurring "upside down again" was the
  per-session atomics resetting every launch, not wrong values.
- In-scope source indicator (tab at the top of the lens): blue=backbuffer, green=mirror
  live, red=mirror wanted but not latched.
- Pane pose re-tuned + baked: pitch 180 / yaw 90, fwd 1.0 / up −0.2 / right −0.715.
  Mirror H-flip defaults ON.

## 2. 💥 THE ABI ROOT CAUSE (the day's biggest lesson)

**Every scalar `setMaterialFloat` the native plugin ever issued silently wrote 0.0.**
The "golden veil" chase (paint-kill rounds, "the game re-asserts emissive", the
FakeSpecular-layer pivot) was all shaped by this: writes of 0 "succeeded" by
coincidence, writes of anything else landed as 0 and read back as "failure".
The tell: all float4 writes (passed as pointer-to-value) verified; all scalar floats
(raw bits in the void* arg slot) landed 0.

**Fix: `set_material_float_verified()`** — tries four encodings in order, read-back
after each, locks the first that verifies. **Winner: encoding 0 = DOUBLE BITS IN THE
ARG SLOT.** In the REFramework plugin C++ SDK, floats double-promote in BOTH
directions (argument path mirrors the long-known get_FOV return-path promotion).

Result, user-verified: **"much brighter image!"** — the scope image had been displaying
at the stock `Reticle_Emissive` 0.02 instead of 1.0 (a 50× dimming) for the entire
compositor era. Indoors now acceptable without retuning.

**Standing rule:** never trust a material write without read-back — and a read-back of
0.0 proves nothing when 0.0 is what a broken write produces. Audit any plugin invoke
passing scalar floats.

## 3. Sky hunt — closed doors, then the treasure room

- LightWeightMode: already false (dead end). Mirror API is a stub: registerScene /
  unregisterScene / isRegisteredScene / Visible / LightWeightMode / RenderTarget.
- The numpad-+ TDB sweep captured the **complete render-layer catalog (291 types):
  RE Engine has NO sky layer.** Scene family: `Scene`, `SmallScene`, `SubScene`.
- Layer instances are unreachable by lookup: via.SceneView and via.Scene expose ZERO
  layer methods. (Corrects 08-24: "scene layer found" never happened — that session
  logged registerScene SKIPPED, which is why set_RenderTarget-alone became the recipe.)
- **The gold strike: `via.render.layer.Scene`'s own API.** Every mirror gets its own
  Scene-layer instance, and that layer is the mirror's REAL control panel:
  `get_/set_Mirror`, `set_BackgroundColor`, `set_ClippingEnable`, `set_ClipPlane`,
  `set_ImageQuality`, `get_LightWeightMode`, `set_Camera(via.Camera)`,
  `set_OutputRenderTarget`, `get_Size/Region`…
- Capture method (since no lookup exists): **observe-only `sdk.hook` on the layer's
  `set_Mirror`/`get_Mirror`, keep every `this`** (add_ref'd, keyed by address); match
  OURS via `get_Mirror` address == our mirror.

## 4. 🏆 THE CLIPPING KILL (user: "we got the biggest win then!")

`set_ClippingEnable(false)` on our mirror's Scene layer **removes the clip-plane grey
half, live** — the structural blocker that forced the crop-slide compromise and
un-zeroed the shots (08-28: "accuracy vs clip-dodge is structural"). One property.
Now **auto-applied** whenever the layer is captured (quiet per-frame resolver,
read-back gated). Zeroing is unblocked.

## 5. Sky verdict + the far-clip plan (deployed, not yet tested)

- L2 painted our layer's background sky-blue (read-back verified, right layer proven
  by the clipping kill) and the sky stayed BLACK ⇒ **the sky dome IS drawn in the
  mirror but SHADES black** (bg never shows because dome geometry covers it; the main
  view's own bg is (0.3,0.3,1.0), equally hidden behind its working sky).
- Can't relight Capcom's sky shader in a mirror pass ⇒ **cull the dome instead**:
  the layer camera's far clip pulled in past the mountains culls the black dome and
  the background color shows through = fake sky in a controllable hue.
- L5 reads the layer camera first and **refuses to write if it's shared with the main
  camera** (would wreck the main view; fallback = set_Camera with our own).
  L6 applies a tunable far clip (slider, ~8000m start).

## State at session end

Deployed = staging HEAD (`7690e62`): plugin (ABI fix, auto-grading v2, persistence,
indicator, dual-layer glass bind) + Lua (LAYER capture hooks, auto-noclip, L1–L6,
SKY buttons, GR probe). All runtime-only; auto-noclip and the glass bind act only on
our own spawned rig/mirror. Remaining ranked: far-clip sky test → host cleanup (hide
the goat) → zeroing (now unblocked) → Quest 3 pass.
