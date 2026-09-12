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
