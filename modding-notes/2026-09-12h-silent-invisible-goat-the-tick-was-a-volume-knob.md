# 2026-09-12h — Silent, invisible goat, live picture: the tick was a volume knob, not the swing (`/lm`, home PC `RTX`, 21:30–00:00, Tefa wearing)

**Where it ended (23:53, screenshot):** one goat on the rifle at ×0.001, **no ticking**, our picture live
on the glass, aimed at the well by the house. The picture still **rotates with head and rifle** — that is
the one problem left, and it is the next session's whole job. `[verified-live 2026-09-12, n=1 wearer]`

## What was learned tonight, in order

1. **The floating full-size goat was NOT a stray rig.** The 22:38 game run built exactly one goat (one
   `SPAWNED` line), shrank it (read back 0.001) — and Tefa still saw a full-size goat hanging in the air.
   The one thing that run did differently from the 22:04 run (tiny goat, riding) was **disabling
   `app.SimplePendulum`**, the swinging-neck component. Same picture after the 22:26 strip, which also
   disabled it. So: the visible goat is most likely a **child object the pendulum re-poses from the root
   every frame**; switch the pendulum off and the child keeps its last world pose, full size, wherever it
   was. `[hypothesis, n=2 consistent runs]` The "stray rig" story in the 22:34 code comment is withdrawn.
2. **The pendulum's fields, dumped live** (`fn goat_pend_dump`): `IsWwiseTrigger`, `TriggerHash`,
   `SoundMaxDistance` 14, `Gain` 1.0, `DistanceGain`, `Gravity`, `PendulumList`, `TargetTransform`,
   `MaxUpdateDist*`… — i.e. **the sound lives on the pendulum itself**, which is why muting the root's
   `WwiseContainerApp` never did anything.
3. **`Gain = 0` silences the tick** — and restoring it to 1 brought the tick straight back, so it is the
   knob and not a coincidence. `IsWwiseTrigger = false` alone did nothing. `SoundMaxDistance = 0` was
   tried and reverted (no effect seen either way). `[verified-live 2026-09-12 23:33 + 23:51, n=2 A→B→A]`
   Harness command: **`pendset Gain 0`**. Swing untouched, goat rides.
4. **The picture disappeared for a whole launch — and it was the bind, not the mirror.** Tefa spotted it:
   *"it's the stock glass, look at the crosshair on it."* The plugin logged `BOUND` on both lens materials,
   the mirror source was latched, the rig alive — and the glass still showed the game's own reticle. A
   **second numpad-`*` bind, sent after the shrink, stuck**. So the first bind was undone by something
   between bind and look (the bind-order trap the guard was written for; the guard is disabled because
   the texture has no stable identity). `[verified-live, n=1]` Bring-up order that worked: rig → drive →
   sliders → shrink → **bind (twice if needed)** → `pendset Gain 0`.
5. **Still open:** the picture rotates with head and rifle; the left/right split question (`mrollsym 1`)
   was armed but never answered — the glass was blank for the look that was meant to answer it.
6. **Tefa's question at midnight: can enemies break the goat?** Not checked. The totem is a breakable prop
   by design (the player shoots them), and the rig still carries its hit/damage parts (`app.HitController`,
   `app.ProcDamage`, `via.physics.Colliders`, all seen in the 22:26 strip list). Switching those three off
   was already done once by `goat_strip` without harming the rig — the harm that night was the pendulum.
   A narrow `goat_armour` (those three only) is the cheap insurance; whether an enemy hit would otherwise
   break it needs enemies. `[hypothesis]`

## What Tefa said

*"ticking is gone! nice another success today, it has been a good day."* And on the picture: *"the one
in scope does move around with both head and weapon movement still."*


---

## ⚠️ 00:28 — THE PICTURE IS FROZEN. Two screenshots, ten seconds and a long walk apart, show the SAME mountain and sky.

Tefa, unprompted, after the session had moved on to publishing: *"the picture does not change when i change locations. i only tested in one spot, so the goat must not be on the weapon i think."*
Evidence: `VirtualDesktop.Android-20260913-002850.jpg` and `-002900.jpg` — the player is in two clearly
different places (a yard with chairs and a gate; then under a hay cart by a fence), and the disc inside
the scope is pixel-for-pixel the same mountain ridge and sky in both. `[verified-live 2026-09-13, n=1 wearer, 2 stills]`

**This changes the reading of the whole evening.** Everything at 23:53 that looked like success — *"you can
see both wells, one in the world other in the scope"* — is also consistent with a **stale frame that happened
to match**, because the scene behind the rifle at that moment contained a well. The rotation we spent the
night chasing may therefore be the rotation of a **still picture being re-projected**, not of a live view.
⚠️ Do not treat "the picture rotates" as a live-view symptom again until this is settled.

### Three candidates, cheapest test first. None is checked.

1. **The engine stops updating the mirror because its host prop is 0.001 across.** Mirrors are expensive;
   RE Engine has screen-size and distance culling, and a prop that small has a near-zero bounding box. The
   prop's own pendulum even carries `IsMaxUpdateDist=true` / `MaxUpdateDistCommon=13.0`, so distance gating
   on this prefab is not hypothetical. **Test: `fn goat_unshrink`, walk two paces, look.** Alive ⇒ this is it,
   and the shrink needs replacing with something that hides without shrinking (`fn goat_hide`, or moving the
   mesh rather than scaling the object). `[hypothesis]` — the strongest of the three, because the shrink
   is new tonight and the freeze was not reported before it.
2. **The plugin's latched source texture is a stale allocation.** The plugin latches one engine texture by
   width and keeps it; if the engine re-allocated the mirror's target after our rig rebuild, we would hold a
   surface nothing writes to any more — which looks exactly like a frozen picture. The log already carries a
   warning from this launch: `rig rebuild #1: the latch had already followed 3 ticks before the rebuild counter
   was read`. **Test: numpad `.` (ask for the NEXT acceptable source), then look.** `[hypothesis]`
3. **The mirror camera is not being ticked at all** — e.g. our camera lost its target, or the component was
   switched off by one of the evening's strips. **Test: read `hb` in the log — `update=`/`draw=` on the rig —
   and watch whether the plugin's `first MIRROR-sourced scope frame` counter advances.** Weakest: the rig
   heartbeat was reading `update=true draw=true` and tracking the rifle all evening. `[hypothesis]`

⚠️ **`rt=false` in the heartbeat is NOT evidence for any of these.** It has printed `false` while the picture
was demonstrably live (23:32 onwards), so the Lua-side `get_RenderTarget` read says nothing about whether the
plugin's D3D-level latch is being written. Do not chase it.

### What to do first, next session

`fn goat_unshrink` ⇒ walk ⇒ look. One command, one answer, and it separates candidate 1 from the other two
before anything is rebuilt.
