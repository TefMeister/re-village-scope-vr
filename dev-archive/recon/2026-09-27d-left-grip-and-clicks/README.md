# 2026-09-27 evening — the left hand's grip, and the weapon "clicks"

## The grip: fixed `[reported 2026-09-27]`

praydog's RE8VR `update_hand_ik` docks the left hand at the game ANIMATION's left-hand spot relative to the right hand, so
every hold animation moved it. New `re8_vrz_scope_left_grip.lua` (staging) re-places the left IK target after REFramework's
last `update_hand_ik` of the frame at ONE captured spot, and freezes the 15 finger joints (L_Thumb1..L_PinkyF3) captured
with it. Captured spot (right-hand frame): (-0.367, -0.142, -0.001), saved in `reframework/data/re_scope_left_grip.txt`.
Tefa: *"the hand stays put now"*, then fingers frozen too.

## The clicks: cause found, not yet silenced

The anim probe (motion layer 1, the upper body) shows the game switching by the rifle's pitch
`[verified-live 2026-09-27, n=2 sessions]`:

| motion | state | when |
| --- | --- | --- |
| 2420 / 2421 | relaxed hold | default; ~2 s after a ready |
| 2305 → 2300 → 2306 | weapon LOWERED | muzzle up < about -0.6 (pointing at the ground) — Tefa's louder click |
| 2100 / 2101 → 2106 | weapon READY | coming back up / to eye level — the fainter click |
| 2002 | walking | layer 0 goes 0 → 1 |
| 2205 / 2207 | (seen once, before a ready) | |

Sounds: `app.WwiseContainerApp.triggered(GameObject, RequestInfo, UInt32 trigger, UInt32 playing)` fires for the player's
sounds (`via.wwise.WwiseContainer.trigger*` is never called). Rare ids near the switches: 1549972489, 315581468,
3992101857. **`stopTriggered(UInt32)` from the `triggered` post-hook does NOT stop anything** — the four suspected footstep
ids kept playing (Tefa) `[reported 2026-09-27]` — so the test says nothing yet about which id is the click.

## Next

Either stop the game from entering the LOWERED/READY upper-body states while the rifle is docked (find what reads the pitch),
or find the sound path that can actually be blocked (the motion's sound track / the request before it plays), then bisect
the ids with Tefa listening. The probes stay in the script, off by default (`grip anim`, `grip sound`).

## 🏆 20:35 — the clicks are silenced, and the scope is done

Two false leads first, both measured live: `app.PlayerGun` stays in `processIdle` throughout (not the switcher), and
`UnshootableDistance` 0.5 / `UnshootableCheckDistance` 10 set to 0 changed nothing (restored). Head pitch does nothing; the
RIFLE's pitch drives it (Tefa's A/B) `[reported 2026-09-27]`.

The sounds: `app.WwiseWeaponMotionSequence` on the player plays the weapon foley of every motion. Disabling it silenced the
clicks AND the aim-button sound AND the bolt (Tefa). So `weaponTrigger(GameObject, TreeLayer, tracks, UInt32)` /
`manualTrigger(TreeLayer, tracks, UInt32)` are hooked and skipped only when the TreeLayer's motion is 2100-2399 or 2421
`[verified-live 2026-09-27, n=1 session]`: skipped 2105/2106/2110 (ready), 2226/2227 (aim), 2305/2306 (lowered); played
2422 (fire + bolt, 108 triggers), 2500 (reload), 2002 (walk) and the rest. Motion map from the same session: aim button =
2205/2206 → 2421 hold → 2207 → 2100 ready; fire = 2422; reload = 2500.

Built into `re8_vrz_scope_left_grip.lua` (staging `cc20943`), only while the rifle camera exists (sniper out).

**Tefa, 20:36:** *"all works as it should now, the unwanted sounds are gone! i think, i really think.... this is it. the
brightness is perfect, the sounds are perfect, the hand stays on the gun in one spot, the occlusion drift is no more, the
scope it pointing where the bullets land, zoom is perfect, performance without the mirror is so much better and the picture
is nice and crisp. we really have done it. it is a major win!"*

Full working set archived: `D:\claude video game stuff\builds\re-village-scope-vr\2026-09-27_2040_WORKING-SCOPE-golden-beaten-grip-clicks\`
(32 files, MANIFEST.sha256).
