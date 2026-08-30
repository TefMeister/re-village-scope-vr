# 2026-08-30 — Grading recon: the game's live exposure found

**Question:** the mirror renders raw pre-tonemap HDR (2026-08-26 finding); the
compositor faked the game's grading with a hand knob (plugin numpad 8/2).
Where does the game keep its OWN live exposure, so the scope can copy it?

**Method:** GR1/GR2 probe added to `re8_scope_m6_mirror_producer.lua`
(staging `6288c48`). GR1 censuses every component on the MainCamera
GameObject, flags grading-suspect type names, dumps their APIs, and snapshots
every zero-param numeric/bool getter (27 found). GR2 re-reads them at 2 Hz
and logs only changes. The user then walked: bright outdoors → dark interior
(scoped) → bright outdoors (scoped).

**Answer: `via.render.ToneMapping.get_EV`.**

- EV = **3.0 outdoors**, glides smoothly to **2.0 in the dark interior** over
  ~1.5 s (the game's eye-adaptation), back to 3.0 outside. `get_SnappedRealEV`
  mirrors it exactly.
- Zone changes also step `MinWhitePoint` (5.6 outdoor / 8.0 indoor) and
  `WhiteRange` (0.9 / 0.8) — instant, not adapted; `app.ColorCorrectController.
  isAnimationBlendInternalExecution` pulses true during zone transitions.
- Grading suspects on the camera GO: `via.render.LDRPostProcess`,
  `app.ColorCorrectController`, `via.render.ToneMapping`,
  `app.ToneMapController`. Full APIs + one-shot values in the log extract.
- Adaptation speeds are published too: `BrightAdaptationRate=0.035`,
  `DarkAdaptationRate=0.05`; tonemap curve params (triple-section, toes,
  linear section) all readable if a closer curve match is ever wanted.

**Consumed by:** plugin auto-grading (staging `3294b0a`) — `world_tick` reads
get_EV per frame, compositor scales shader exposure by `2^(3 − EV)` (3.0 =
outdoor reference where the numpad 8/2 calibration passes through unchanged).
Numpad 5 in MIRROR mode toggles auto-grading for A/B. Deployed 2026-08-30,
awaiting the next game launch for the visual check.

**Files:** `gr-recon-log-extract.txt` — every `[m6_mirror]` log line from the
GR1 press to session end (component census, API dumps, 27-getter snapshot,
all GR2 change events with timestamps).
