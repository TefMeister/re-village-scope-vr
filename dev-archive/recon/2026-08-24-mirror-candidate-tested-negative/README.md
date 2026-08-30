# 2026-08-24 — Dev PC setup + candidate 1 (`via.render.Mirror`) tested, negative

**Where:** dev PC (previously thought to not have RE Village installed — it does, that note was
stale). REFramework nightly 01397 (`684ca77`) + VR pack installed fresh, `re_scope_vr.dll` built
clean first try from `plugin/CMakeLists.txt` via the VS-bundled CMake + VS2022 Build Tools, deployed
alongside the companion Lua. Plugin confirmed loading and running (per-frame world-state log lines
matched the M2a-era format).

**Goal:** resolve the open RT-GPU-backing problem (see `STATUS.md` §7 / modding-notes
`2026-08-23-m3-recon-glass-hijack-proven-rt-backing-open.md`) by trying candidate 1 —
`via.render.Mirror` as an RT producer — all testable flat, no headset needed.

## What the scripts do, in order

- `re8_scope_m4_mirror_recon.lua` — first pass: does `via.render.Mirror` even exist in this game's
  TDB, and what methods/fields does it expose? **Result: yes, and it has exactly the API we wanted**
  (`isRegisteredScene`, `registerScene`, `unregisterScene`, `get_Visible`, `get_LightWeightMode`/
  `set_LightWeightMode`, `get_RenderTarget`/`set_RenderTarget`). Also checked `app.RecordSys`
  (candidate 3): **does not exist in this TDB at all** — dead, don't pursue.
- `re8_scope_m4_mirror_recon2.lua` — tried to create a GameObject + attach a Mirror component.
  `via.Scene` has no `createGameObject`-family method reachable this way; `via.GameObject.
  createComponent` DOES exist but the naive `"createComponent(System.Type)"` signature guess threw
  (`ok=false`) — REFramework's `:call()` needs the *exact* reflected overload string.
- `re8_scope_m4_mirror_recon3.lua` — reflected the exact `createComponent` overload via
  `method:get_param_types()` instead of guessing, and attached the Mirror to an **already-in-scene**
  GameObject (`FadeInOutBlack`, present at the title screen) rather than an orphan
  `sdk.create_instance` object. **Attach succeeded. `set_RenderTarget` and `registerScene` both
  succeeded (`ok=true`), `get_Visible` reports `true`.** Redirected one GUI element
  (`GUIMouseCursor`) to the resulting RT as a visibility test — screenshot showed no visible change,
  but the cursor icon is tiny/easy to miss, so not conclusive on its own.
- `re8_scope_m4_mirror_recon4.lua` — same attach, this time redirecting a much larger element
  (`BackColor`) for a clearer visual test. Still no visible change (`screenshot1-title-screen-
  baseline.png` vs. the equivalent capture — indistinguishable).
- `re8_scope_m4_mirror_recon5.lua` — decisive round: redirected **all 41 GUI components** present at
  the title screen to the Mirror's RT simultaneously, and separately checked whether REFramework's
  Lua API has any higher-level render-target-creation helper we'd overlooked (`re.*`/`sdk.*` tables
  scanned for anything matching `render`/`texture`/`target`). **Screenshot
  `screenshot3-41-gui-redirected-no-change.png`: zero visible change anywhere on screen** despite 41
  simultaneous redirects. Confirmed there's no missing "proper" API — `sdk.create_resource` +
  `create_holder` (the technique already used since M3) is genuinely the only resource-creation path
  Lua exposes; no `re.create_render_target`-style helper exists.

## Conclusion

**Candidate 1 is a dead end, for the same underlying reason as M3's GUI-producer attempts**: a
render-target resource created via `sdk.create_resource("via.render.RenderTargetTextureResource",
...)` never gets real GPU backing / pipeline registration, regardless of what "produces" into it —
neither an existing GUI's own render pass (M3) nor a `via.render.Mirror` component with a
successfully-`registerScene`'d live scene (this session). The API surface is real and callable at
every step; the actual pixel data never materializes.

**This also corrects an over-broad claim from the 2026-08-22 session** (`STATUS.md`/modding-notes:
"REFramework Lua API has NO render-target/second-camera/render-pass functions — reflection + 2D
draw only"). That's not quite right — `via.render.Mirror`'s render-target API is real and fully
reachable from Lua reflection. It was just never tried against this specific type before, and trying
it doesn't actually solve the problem, so the *practical* conclusion (native C++ plugin needed) ends
up the same — but the *reason* was mis-stated. Worth keeping in mind for future recon: absence of a
capability from a project's own past exploration isn't the same as absence from the engine.

## Recommendation

**Candidate 2 (plugin-side native GPU hijack of the confirmed-working reticle texture)** is now the
clearly strongest remaining lead. Unlike candidates 1 and 3, it doesn't depend on getting a *new* RT
backed at all — it reuses an existing texture slot already proven to display real content (the
glass-hijack test, M3). This project's own M1 milestone already proved the exact underlying native
mechanism this would need: plugin-side D3D12 `CopyTextureRegion` into an existing GPU resource
(that's literally how M1 gets our own RT into the backbuffer). The remaining work is native-only:
from `Plugin.cpp`, resolve the reticle texture's live `ID3D12Resource*` (via the native reflection
SDK, not Lua) and `CopyTextureRegion` real rendered content into it directly.

Cleanup: all recon scripts here were removed from the deployed `reframework/autorun/` after each
round (title-screen-only recon, no gameplay/save touched); only the real companion script + built
plugin remain deployed. Game process killed cleanly at the end of the session.
