# The flat steering sweep: the mirror's normal is the rig's local Y, pitch rolls the image, yaw does nothing (2026-09-05 late morning, home PC, `/lm`, two launches driven from outside)

Tefa away, launching authorised. Everything below was driven with nobody at the mouse:
`dev-archive/tools/re8drive.py` for keys and captures, and a new **command-file harness**
(`staging/re-village-scope-vr/scripts/re8_scope_harness.lua`, `02770c5`) that steps the sliders,
toggles steering, calls the producer's start path by name and **holds ADS through the gamepad
seam**. Evidence: `dev-archive/recon/2026-09-05-steering-sweep-flat/` (two logs, 14 captures).

## 1. The sweep result

Baked pose pitch 180 / yaw 90, steer OFF, ADS held, the village reeds in view. Five +5° pitch steps,
back to 180, five +5° yaw steps, back to 90; one capture and one `sliders:` line per step
(`captures/montage.jpg` shows all thirteen centre circles side by side, brightened).

| sweep | what the mirror picture did |
| --- | --- |
| **pitch 180 → 205** | the content **rolls** progressively and the view **shifts** (a diagonal reed band appears by 195, brighter ground enters bottom-left by 200–205); back to 180 restores the baseline |
| **yaw 90 → 115** | **nothing** — the thirteen frames are the same picture to within reed sway; the gradient-orientation measure reads 0 ± 7° across all five steps at coherence ≈ 0.1 (noise) |

`[verified-live 2026-09-05, n=1 scene, 5 steps each way]`

**Reading.** A rotation of the plane about an axis that leaves the reflection unchanged can only be
a rotation about the plane's own normal. Yaw is the rotation about the rig's local Y, so **the
mirror's normal is the rig's local Y axis** — candidate 2 of the 09-05 ledger, now settled. The
steering build of 2026-09-05 00:30 learned the axis as **local +Z at dot 0.79** and rotated *that*
onto `n`; it was rotating the wrong axis, which alone explains a reflection that "looks back at
the body" whatever the model. Pitch is the rotation about local X, i.e. an in-plane axis: it tilts
the normal, the reflected direction sweeps, and the image rolls with it — candidate 3 (roll varies
with the normal) is confirmed as real, not hypothetical.

**The roll law is NOT pinned.** The gradient-orientation measure gives +31°, +39°, +47°, +53°,
+53° for pitch 185…205, but the baseline frame has coherence 0.06 (reeds, no dominant edge), so
the first number is an artefact of an ill-defined reference and only the *trend* (~+5° of roll per
+5° of pitch from 185 on) is trustworthy. A scene with a straight edge (a wall, a roofline) would
give it cleanly; queued.

**The imaging-model question (reflect the eye→mirror ray vs. reflect the camera forward) is not
separated by this sweep** — with a fixed eye both predict the same sweep direction; only a moving
eye tells them apart, and that is the headset. But the practical order is now: fix the axis first
(local Y), add roll compensation, then test the model in VR. Both models with the wrong axis look
identical, and wrong.

## 2. Three other results, for free

- **`[FLAT, free]` row: the ownership-token line reads `DIFFERENT`** on every bind
  (`holder=…5D1020 read-back=…0C14A0`, then `…5D2E0`, `…0C9000`, … a **new pointer on every
  re-bind**, about every 1.15 s). So the 09-04 diagnosis was right — the holder is not the token —
  **and the 09-05 fix's premise was also wrong**: `getMaterialTexture` returns a fresh managed
  wrapper per call, so no pointer identity can ever match, and the guard still re-asserts every
  1.15 s (54 lines in a 60 s window). Harmless as before (restore + bind inside one tick, the
  picture is steady in every capture), but the check needs a different token — the wrapper's
  underlying resource pointer, or simply rate-limiting the re-assert to the E press.
  `[verified-live 2026-09-05, n=2 launches]`
- **Cold-start order matters, and a rebuilt rig does not render.** First launch: P10 → glass → `.`
  re-arm → `*` gave `mirror_latched=0` (the latch is not armed at boot, so the first mirror's RT
  was never caught); destroying the rig, arming, and P10 again gave `mirror_latched=1` but a
  **black mirror** — the HDR probe read 0.000 in every block of the 1280×728 source, ADS or not,
  and the log shows the second mirror got **no `LAYER captured` and no `AUTO-NOCLIP`** while the
  first one had both. Second launch, order **`.` → P10 → drive → `*`**: layers captured, latch,
  source max 4737, picture on the glass. `[verified-live 2026-09-05, n=1 each]` The harness
  encodes this order; a stale rig in the session means relaunch, not rebuild.
- **The scope at this spot is far too dark on the tuned settings** — our RT averaged 0.02–0.05
  with the source at 2–6 raw luminance, GT knob 0.134, game EV 3.0. Six numpad-8 presses (≈3.8×)
  made the content readable for the sweep. Whether that is this spot (EV 3 vs the 09-04 evening)
  or a regression is not established; the 09-04 pair was "about the same as the game". Recorded,
  not chased.

## 3. Automation on RE Village, scored (§5a) — first profile written today

menu → gameplay **PROVEN** (title Enter → Continue F → dialog defaults to **No**, Up then F →
Stronghold splash F; n=2) · commands **PROVEN** (numpad by VK for the plugin; the command file for
the Lua; **ADS via `app.HIDPadManager.doUpdate` injecting `LTrigBottom` + `AnalogL` — fov 51.3 →
49.3, camera into the tube, aim pixel centred**) · character movement **not exercised** · camera
**not proven** (mouse dead for the game, alive for the REFramework overlay — a click on
"Reset scripts" reloaded the Lua in-session) · self-close **PROVEN by `WM_CLOSE`** (window gone in
~2 s, process ~12 s later, twice; the game's own quit route from gameplay is unmapped). With no
headset, OpenXR fails `XR_ERROR_FORM_FACTOR_UNAVAILABLE` and the game runs flat — no config change
needed for a flat session on the VR install.

## Not established

- The roll law (needs a straight-edged scene) and the imaging model (needs the headset).
- Whether the dark scope at this spot is scene EV or a regression.
- The game's own quit route from gameplay.
