# The swing is REFramework's projection override — and the proposed fix was already switched on, and failing

**2026-09-09, home PC (`RTX`), `/lm`, NO LAUNCH.** The game was not started. Everything here is a
drained inbox, a config read and a log read.

## What was done

1. **Deployed the 2026-09-08 plugin and stamped the install.** The board's own preamble warned the
   two log-defect fixes were `[compile-verified]` and **not deployed**, and `deployed.sh check`
   confirmed worse: this project had **never been stamped on this machine at all**. The installed
   DLL was 164,864 B (the 2026-09-06 build). Rebuilt from `origin/main` in the modding lane's own
   clone — not lifted from the `/pd` root — and checked against the `/pd` build with
   `same-build.py`: **6 differing bytes, all linker timestamps ⇒ same source**
   `[verified-numerically 2026-09-09]`. Deployed 165,888 B with backup
   `.pre-2026-09-08-logfixes-backup-2026-09-09`, then recorded all seven installed files.
2. **Added `/Brepro` to the plugin's `CMakeLists.txt`** — two builds of identical source differed in
   6 bytes before, **0** after `[verified-numerically 2026-09-09]`. Tenth project in the estate to
   need this.
3. **Checked every Lua against staging.** `re8_scope_m3_recon.lua` and `re8_scope_recon_probe.lua`
   are identical ignoring line endings; `re8_scope_vr_companion.lua` differs in exactly one line,
   `keep_weapon_visible = true`, which is the deliberate local edit the 2026-09-06 entry records.
   **Left alone.** Harness and producer already matched.
4. **Drained the four-file inbox** (a supersedes chain, read in full first) into dossier **§9j**.

## ⭐⭐ The finding: crop-follow was never the lever

Folded from three `/gr` drops and one `/sr` correction. **§9g asked the wrong question.** It asked
whether the Mirror renders with the viewing camera's projection or its own. The answer is *its own —
and then REFramework overwrites it*: `VR::on_camera_get_projection_matrix` has its primary-camera
guard **commented out** while the matching guard in `on_camera_get_view_matrix` is **live**. The
mirror render therefore gets the current eye's asymmetric off-centre HMD projection sitting on top of
the mirror camera's own non-eye view matrix. `[inferred-static 2026-09-07]`

**A projection that changes with head pose over a view matrix that does not is precisely "the picture
inside is moving where I look and tilt."**

So every one of the four candidate mappings was trying to *describe* a projection that is being
rewritten each frame. Both headset launches swinging is the **predicted** outcome, not a puzzle.
praydog hit the same thing on RE4's scope and fixed it by **exemption** (commit `20a3ec5442`: match
the camera GameObject name prefix `ScopeCamera`, return without overriding). RE8 uses a Mirror where
RE4 uses a ScopeCamera, so the match condition differs; the remedy does not.

## ⚠️ And the remedy the chain proposed was ALREADY ON during the swing

The drops' best paragraph was that `pd-upscaler`'s `RenderingTechnique_V2` **MULTIPASS** mode erases
mirror-bearing layers from the override list, and `/sr` confirmed this machine runs that branch. The
implied next step was "switch to MULTIPASS and look."

**It is already switched on.** `re2_fw_config.txt` line 99 is `VR_RenderingTechnique_V2=2`, and the
framework log of the **23:03:59 launch on 2026-09-06 — the swing session itself** — carries eight
warnings between 23:04:04.9 and 23:04:26.6:

```
[VR] Multipass textures are not setup correctly.
[VR] Multipass textures are not setup correctly: Re-using backbuffer.
```

`[verified-live 2026-09-06, n=1 log]` The multipass path was selected and running while the swing was
observed, and it **fell back to re-using the backbuffer**.

This is the difference between "the fix is untried" and "the fix is failing", and it changes the next
test completely. ⚠️ **Do not write a row that says "try MULTIPASS".**

⚠️ **What is NOT established:** whether that fallback persisted. The warnings appear only in the
first 22 seconds of an 11-minute session and never repeat — consistent with a startup stumble that
later succeeded *or* with a silent permanent fallback. That is one log read on the next launch, not
a headset judgement, and it must be settled before any headset time is spent.

## ⭐⭐ The lead that may matter more than the whole crop-follow line

**RE8 ships Capcom's own VR sniper scope.** `app.VrWeaponSniperScopeLensUpdater` (hash `e6d05808`) is
in RE8's type DB with `DistortionBegin`, `ExpansionRate`, `ReticlePosition`, and — the point —
**`LensLeftPosition`** and **`LensRightPosition`**, both `via.GameObjectRef`. `[reported 2026-09-07]`

That is **per-eye lens position anchors against a fixed rendered image**, with a radial distortion
term. Not a per-eye reprojection. And it addresses Tefa's **first** symptom — *"moving around the
pipe of the scope"* — which **none of our four candidates ever addressed**. Every one of them went
at the second symptom only.

## A second suspect for head-tracked lag, kept separate

The right eye replays `WaitRendering`→`EndRendering` with an erase list containing **`UpdateMovie`**
(praydog: *"Causes movies to play twice as fast if ran again"*), and **our target is a `movie/rtex`
target**. If its refresh runs under `UpdateMovie`, the right eye sees a stale image — lag that
tracks head motion. `[hypothesis]` Separated cheaply by logging the target or a frame counter on
both passes.

## One engine fact to re-read our own instrumentation against

praydog: *"the game **always** uses the main camera when calling this function, even though it's
rendering the other camera."* **The camera a pass calls a getter on does not identify the camera that
pass is rendering.** Worth checking the `crop-follow:` instrumentation against that before trusting
another of its verdicts.

## Automation

Not applicable — no launch this session. The install is now current and, for the first time on this
machine, stamped.
