# Anomaly VR's hand / controller offsets, and what transfers to RE8

Author: modding session (static pass, NO LAUNCH), home PC `RTX`, 2026-09-19
Speaks to: dossier §9z (hand height), the `[PD]` OPEN row *"HAND AND CONTROLLER PLACEMENT"*,
and the `[PD]` row *"hand height: find what really places the hand"*.
Reference read: `C:\Anomaly` (S.T.A.L.K.E.R. Anomaly + the AoE VR mod). **Nothing from that
install is committed here** — only setting names, values and the engine's own help text, quoted.

---

## 0. The one-line answer

**In Anomaly, (a) and (b) are the SAME setting.** Its name in the mod's own tuning UI is
**"Secondary anti-occlusion offset (двуручный хват)"** — *secondary anti-occlusion offset
(two-handed grip)* — and it is applied **to the support controller's IK TARGET, in WORLD space,
BEFORE the weapon is solved onto the hands**. Not to the hand model, not to the weapon.
`[inferred-static 2026-09-19]` (read from config + the engine's embedded UI strings; not run)

---

## 1. What Anomaly actually does

### 1a. The files

| File | What it holds |
| --- | --- |
| `vr_mods\anomaly_aoe_vr\gamedata\configs\vr\weapon_grip_vr.ltx` (2,088 lines) | per-weapon grip sockets — where each hand sits **on the gun** |
| `vr_mods\anomaly_aoe_vr\gamedata\configs\vr\handpose_vr.ltx` (844 lines) | per-weapon finger poses (14 finger bones per hand, degrees) |
| `vr_mods\anomaly_aoe_vr\gamedata\configs\mod_system_vr.ltx` | includes both; per-item held-object offsets |
| `appdata\user.ltx` | the live console variables, ~190 of them prefixed `vr_` |
| `vr_mods\anomaly_aoe_vr\bin\AnomalyDX11.exe` | the logic itself, compiled — but it carries its full ImGui help text as readable strings, which is where the *why* comes from |

### 1b. The weapon-hold model (the part that answers (b))

Every weapon section names **two sockets**, both expressed relative to a **named bone of the
weapon**, in metres and degrees:

```
![wpn_mp5_hud]
primary_grip_bone   = wpn_body
primary_grip_pos    = -0.0037, -0.0172, 0.0015
primary_grip_rot    = 0.00, 76.00, 0.00
secondary_grip_bone = wpn_body
secondary_grip_pos  = -0.0105, 0.0595, 0.2155     ; 21.6 cm up the barrel
secondary_grip_rot  = -36.00, -5.00, 90.00
secondary_grip_hand_pose = wpn_foregrip_horizontal
```

Plus a default for every weapon that has no entry of its own:

```
[secondary_grip_base_config]
secondary_grip_bone = wpn_body
secondary_grip_pos  = -0.0135, 0.0460, 0.2625
secondary_grip_rot  = -36.00, 0.00, 90.00
```

`secondary_grip_bone` is often a **moving** bone, so the support hand rides the part it is
actually holding — `zatvor` (bolt/pump) on the Remington 870, `pompa` on the SPAS-12, `magazin`
on the Bizon, `bend_reload` on the break-actions. `*_pos_mirror = -1,1,1` / `*_rot_mirror =
-1,1,-1` are the left-handed-mode sign flips.

So: **the drawn support hand is not at the controller. It is at a socket on the gun.** That is
(b), and it is structural rather than a fudge.

### 1c. The anti-occlusion offset (the part that answers (a), and tunes (b))

Live values on this machine, `appdata\user.ltx` `[measured 2026-09-19]`:

```
vr_secondary_ik_enable   1
vr_secondary_ik_offset_x 0.
vr_secondary_ik_offset_y -0.04      <-- 4 cm DOWN
vr_secondary_ik_offset_z 0.
```

The engine's own help text for it, translated `[inferred-static 2026-09-19]`:

> **Secondary anti-occlusion offset (two-handed grip).** R2-rotation of the barrel about
> `ctrl_primary` after the two-point [solve] — barrel AND secondary hand travel together.
> Master switch (`vr_secondary_ik_enable`). OFF = feature fully disabled, no IK-target shifts.
> **Frame = WORLD: +X east, +Y up (gravity), +Z north. "Lower" = negative Y.**
> Default: 0, 0, 0 (feature off).

And the per-weapon override, `secondary_grip_ik_offset`:

> Per-weapon override of the base `vr_secondary_ik_offset_*`. **Shifts the secondary
> controller's target point in the WORLD frame BEFORE the two-point [solve].** Requires master
> switch `vr_secondary_ik_enable=1`. [Otherwise] the global cvars are used.

Exactly one weapon in the shipped file uses it — the RPG-7, `weapon_grip_vr.ltx:2047`:
`secondary_grip_ik_offset = 0.0000, 0.04, 0.0000` (4 cm **up**, cancelling the global −4 cm).

**Read that help text twice.** The offset moves the *target point the solver aims at*, in world
space, before the gun is placed. So pushing it down does two things at once: the support hand
stops sitting in front of / inside the right hand (**anti-occlusion — (a)**), and it ends up
below where your real hand is (**(b)**). One knob, both wants. `[inferred-static 2026-09-19]`

### 1d. The other offsets in the same family, for completeness

| cvar | Live value | Engine's own description (translated) |
| --- | --- | --- |
| `vr_palm_offset_x/y/z` | 0.04, 0.063, −0.015 | "Shift of the hand's IK target in the **controller's local** axes (metres). +X right, +Y toward the thumb, +Z toward the fingers. X is mirrored automatically for the left hand." |
| `vr_palm_rot_l_*` / `vr_palm_rot_r_*` | l: 162.5, 0, −95.5 · r: 133, 81.5, −57.5 | "Default hand orientation relative to the controller. **Tuned separately per hand — the bind poses of the l/r models are often not symmetric.**" |
| `vr_hands_offset_y` / `_z` / `vr_hands_spread_x` | −0.22, −0.105, 0 | "**Shoulder** offset (metres, camera-local axes)" — the IK root, not the hand |
| `vr_secondary_grip_force_engage` | 0 | forces the two-handed hold on |
| `vr_show_controllers` / `vr_draw_controllers` | 0 / 0 | debug only — "controller pose crosses" and "controller bounding boxes". **Not** a rendering-order feature. |

⚠️ I searched the whole binary for any depth / draw-order / render-order treatment of the hands.
There is none. The only occlusion feature in the mod is the offset above. **"Left controller
visible behind the right" is achieved by MOVING it, not by drawing it differently.**
`[inferred-static 2026-09-19]`

---

## 2. Does it transfer to RE Engine / REFramework?

**The idea transfers. The implementation does not, and one half of it is already in RE8.**

Source read: praydog's `src/mods/vr/games/RE8VR.cpp` at the exact commit our build reports
(`76298bd`, tag `v1.5.9.1`+671, build 12.09.2026 — from `re2_framework_log.txt:2-7`).
`update_hand_ik()` is lines 214–410. `[inferred-static 2026-09-19]`

### 2a. ⭐ RE8 ALREADY DOES (b) — and that is why our lever is disconnected

The core of `update_hand_ik()`:

```cpp
auto lh_pos = updated_camera_pos
            + ((original_camera_rotation * left_controller_offset)
            + (glm::normalize(original_camera_rotation * left_controller_rotation) * m_left_hand_position_offset));

auto lh_grip_position = rh_pos + (glm::normalize(rh_rotation) * original_left_pos_relative);
const auto lh_grip_distance = glm::length(lh_grip_position - lh_pos);

m_was_gripping_weapon = lh_grip_distance <= 0.1f || (m_was_gripping_weapon && m_is_holding_left_grip);

if (m_was_gripping_weapon && !m_is_reloading) {
    ...
    lh_pos = lh_grip_position;                          // <-- the offset is THROWN AWAY here
    lh_rotation = rh_rotation * original_left_rot_relative;
}
...
sdk::set_transform_position(m_left_hand_ik_transform, lh_pos);
sdk::set_transform_rotation(m_left_hand_ik_transform, lh_rotation);
*sdk::get_object_field<float>(m_left_hand_ik, "Transition") = 1.0f;
sdk::call_object_func_easy<void*>(m_left_hand_ik, "calc");
```

`original_left_pos_relative` is the game's **own animation's** left-hand position expressed
relative to its right hand, read that frame from `via.motion.Motion`. So when the left hand
comes within **10 cm** of where the animation says the support hand belongs, RE8VR latches into
"gripping" and **pins the drawn left hand to the weapon, discarding the left controller
entirely.** That is precisely Anomaly's `secondary_grip` socket — RE8 just derives the socket
from the animation instead of from an `.ltx`.

⭐ **This explains the OPEN row's dead end exactly.** `re8vr.left_hand_position_offset` feeds
only the `lh_pos` branch, and that branch is overwritten the instant the hand is on the gun.
Writing it while holding the rifle **cannot** move the drawn hand. It is not a broken binding;
it is a value the code stops using. `[inferred-static 2026-09-19]` — and it is consistent with
`[verified-live 2026-09-17, n=3 writes]` rather than contradicting it.

### 2b. ⚠️ There is a SECOND, simpler explanation and it must be ruled out first

```cpp
if (!vr->is_hmd_active() || !vr->is_using_controllers()) {   // second guard, line ~235
    m_was_gripping_weapon = false;
    m_is_holding_left_grip = false;
    return;                                                  // hands not updated AT ALL
}
```

and, from `VR.hpp:149-151`:

```cpp
bool is_using_controllers() const {
    return !m_controllers.empty()
        && (steady_clock::now() - m_last_controller_update) <= seconds(m_motion_controls_inactivity_timer->value());
}
```

`m_last_controller_update` is refreshed **only by button presses, stick movement and bound
actions** (`VR.cpp:3897, 3930, 4141, 4146`) — *not* by tracking motion. Our
`re2_fw_config.txt:99` has `VR_MotionControlsInactivityTimer=30.000000`.

⚠️ **So after 30 s with no button or stick input — e.g. controllers parked on a shelf, which is
exactly the standing unattended-VR condition in the dossier — `update_hand_ik()` returns at the
top and NO write to ANY offset can move the hand.** That is a complete alternative cause of the
2026-09-17 reading, indistinguishable from 2a with the evidence we have.
`[inferred-static 2026-09-19]`

**Both must be separated before anything is built.** Experiment §3a below does it for free.

### 2c. What does NOT transfer

- **No per-weapon grip table.** RE8 has no `weapon_grip_vr.ltx` equivalent and no authored
  sockets; the support-hand position comes from whatever animation is playing, live. We could
  *build* a per-weapon table, but that is a project, not a knob.
- **No finger-pose system.** `set_hand_joints_to_tpose()` flattens the hand and the IK solver
  does the rest. Anomaly's 14-bone-per-hand `handpose_vr.ltx` has no counterpart.
- **We cannot rotate the gun to follow the hand.** Anomaly's help says the anti-occlusion offset
  makes "barrel AND secondary hand travel together" (an R2 rotation about the primary grip).
  RE8VR does have the analogous `grip_rot_delta` term, but it is computed from the *controller*
  positions and is upstream of where we could inject. A world offset applied by us would move
  the hand **without** the gun following — i.e. a small visible detach. Keep it to a few cm.
  `[hypothesis]`

---

## 3. The cheapest experiments — one launch each, and what each one kills

### 3a. FIRST, and it is free: which of §2a / §2b is true

No code. Print four values once a second from any script already running (the harness):

```
vrmod:is_using_controllers()      re8vr.can_use_hands
re8vr.was_gripping_weapon          re8vr.left_hand_ik_transform:get_position()
```

- `is_using_controllers()` **false** → §2b. `update_hand_ik` is not running; every hand test
  since 2026-09-17 measured nothing. Fix: touch a stick/button, or raise
  `VR_MotionControlsInactivityTimer`. **The whole hand line re-opens.**
- `is_using_controllers()` true and `was_gripping_weapon` **true** → §2a confirmed. The offset
  is genuinely bypassed while the hand is on the gun; go to 3b/3c.
- `was_gripping_weapon` **false** while visibly holding the rifle → the grip latch never engages
  and the hand is at the controller pose; then `left_hand_position_offset` *should* work and the
  problem is somewhere else entirely.

⚠️ **The 2026-09-17 false pass was "the click never reached the mod".** Whatever is built here
must print an echo line before anything is believed — the existing `harness:` rule.

### 3b. For (b) — the support hand lower than the real controller — cheapest first

**Lever 1, one line, no maths: make the grip latch sticky.**

```lua
re8vr.is_holding_left_grip = true   -- from a callback that runs BEFORE re8_vr.lua's
```

`m_was_gripping_weapon = lh_grip_distance <= 0.1f || (m_was_gripping_weapon && m_is_holding_left_grip)`
— so with that flag held true, **once the hand has touched the forestock it stays on the gun
however far the real controller drops.** That IS "the hand sits lower than the controller", and
it is Anomaly's `vr_secondary_grip_force_engage`. Both fields are exposed to Lua
(`RE8VR.cpp:78-79`). One launch proves or kills it. `[hypothesis]`

⚠️ Ordering: `re8_vr.lua:396` writes this field every frame from the left grip button. Our
autorun file names (`re8_scope_*`) sort **before** `re8_vr.lua`, so a
`re.on_pre_application_entry("PrepareRendering", …)` we register runs first and is overwritten;
registering the force from the same entry but relying on our earlier registration is the wrong
way round. Use a hook that fires between `re8_vr.lua:396` and the `update_hand_ik()` at
`re8_vr.lua:1547-1549`. This ordering claim is `[hypothesis]` and the echo line must show the
flag's value as `update_hand_ik` sees it.

**Lever 2, the true Anomaly port: a world-space offset on the IK target, after the fact.**

```lua
re.on_application_entry("PrepareRendering", function()   -- POST; runs after re8_vr.lua's PRE
    local t = re8vr.left_hand_ik_transform
    if t == nil then return end
    local p = t:get_position(); p.y = p.y - d          -- d in metres, WORLD frame, exactly vr_secondary_ik_offset_y
    t:set_position(p, true)
    re8vr.left_hand_ik:call("calc")
end)
```

`left_hand_ik_transform` and `left_hand_ik` are both exposed to Lua (`RE8VR.cpp:66-68`), and
`calc` is the same call RE8VR itself makes. Start at **d = 0.04 m**, which is Anomaly's shipped
value, and which is small enough that the hand-off-the-gun detach in §2c should not read as a
fault. `[hypothesis]`

⚠️ **`re8_vr.lua`'s last `update_hand_ik()` of the frame is the `PrepareRendering` PRE at line
1547** (the others are `UpdateBehavior`, `UpdateMotion`, `LateUpdateBehavior`). The POST of the
same entry is therefore the correct and only clean slot. If the hand flickers, the ordering
assumption is wrong and that is the answer, not a bug.

### 3c. For (a) — the left controller visible behind the right

**There is nothing separate to test.** Anomaly's own name for the feature settles it: the fix
for occlusion IS the offset. Run 3b first. If the wearer still reports the left hand hidden or
clipping once it sits 4 cm lower, then and only then is (a) a distinct problem, and the next
thing to try is the sideways component (`vr_secondary_ik_offset_x`'s equivalent — the `x`/`z`
terms of the same write) before anything to do with drawing.

⚠️ **Do not go looking for a render-order or depth knob.** Anomaly has none, and RE Engine hands
the hands to the same renderer as everything else. `[inferred-static 2026-09-19]`

---

## 4. Does REFramework expose a hand/controller offset we are not using?

**No. We already found the only one there is.** `[inferred-static 2026-09-19]`

The complete `vrmod` Lua surface (`VR.cpp`, `lua.new_usertype<VR>`, ~50 entries) contains
`get_controllers`, `get_position`, `get_rotation`, `get_transform`, `get_velocity`,
`get_standing_origin` / `set_standing_origin`, `get_rotation_offset` / `set_rotation_offset`,
`get_gui_rotation_offset` / `set_gui_rotation_offset`, `recenter_view`, `recenter_gui`, the
`get_action_*` family, `is_using_controllers`, `apply_hmd_transform`,
`trigger_haptic_vibration`, `get_last_render_matrix`.

- `set_rotation_offset` is the **world yaw recentre**, not a hand offset.
- `set_gui_rotation_offset` is the **menu plane**.
- There is **no** controller-position offset, no per-hand offset, no grip offset.

The only hand offsets in the whole of REFramework are the four `re8vr.*_hand_position_offset` /
`*_hand_rotation_offset` fields — the ones §2a shows are bypassed while gripping. The
`re2_fw_config.txt` VR block has no hand entry either (`VR_JoystickDeadzone`,
`VR_MotionControlsInactivityTimer`, `VR_2DUIDistance`, `VR_WorldSpaceUIScale`, rendering flags —
nothing positional for the hands).

⚠️ **But three `re8vr` fields we have never touched are writable from Lua and matter here:**
`is_holding_left_grip`, `was_gripping_weapon` and `left_hand_ik_transform` (plus
`left_hand_ik`). Those are the levers. §3b uses them.

---

## 5. Confidence, plainly

| Claim | Tag |
| --- | --- |
| Anomaly's setting names, values and help text as quoted | `[inferred-static 2026-09-19]` — read from files on disk and strings in its binary; the mod was **not run** |
| `user.ltx` live values (`vr_secondary_ik_offset_y = -0.04` etc.) | `[measured 2026-09-19]` — they are that machine's saved settings |
| RE8VR's `update_hand_ik` discards the left offset while gripping | `[inferred-static 2026-09-19]` — read from praydog's source at our exact build commit |
| The 30 s controller-inactivity guard can freeze the hands entirely | `[inferred-static 2026-09-19]` |
| Which of those two caused the 2026-09-17 reading | **unknown** — §3a separates them |
| Every proposed fix in §3 | `[hypothesis]` — none has been run |

## 6. Sources

- `C:\Anomaly\vr_mods\anomaly_aoe_vr\gamedata\configs\vr\weapon_grip_vr.ltx`, `…\handpose_vr.ltx`,
  `…\gamedata\configs\mod_system_vr.ltx`, `C:\Anomaly\appdata\user.ltx`, and the embedded ImGui
  help strings in `C:\Anomaly\vr_mods\anomaly_aoe_vr\bin\AnomalyDX11.exe`. **Not committed.**
- praydog/REFramework @ `76298bd9796b2b32e67133ff0360a7993c2e1482`:
  `src/mods/vr/games/RE8VR.cpp` (lines 55–105 bindings, 214–410 `update_hand_ik`),
  `src/mods/VR.cpp` (Lua usertype ~line 920–977; `m_last_controller_update` refresh sites),
  `src/mods/VR.hpp:149-151`.
- Local: `…\Resident Evil Village BIOHAZARD VILLAGE\reframework\autorun\re8_vr.lua`
  (lines 23–54, 396, 579–582, 1547–1549), `re2_fw_config.txt`, `re2_framework_log.txt:1-10`.
