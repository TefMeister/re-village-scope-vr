# Shrink the prop instead of hiding it — Tefa's idea, and the one line of code that decides it (2026-09-12 night, home PC `RTX`, `/pd`)

**The game was not launched and nothing here has been run.** Built, parse-checked, deployed and
hash-stamped.

---

## 1. The idea, and why it cannot work as stated

Tefa, after the evening's wear, verbatim:

> *"maybe it doesn't have to ride the weapon, maybe it can be far enough high up and just enough out
> of view, maybe slightly behind the player and above the head, as no one really tilts their head up
> all the way to look past 90° upwards… so instead of hiding, maybe that is an idea and make sure it
> stays out of sight like this both while turning roomscale and with a left controller stick?"*

⚠️ **Parking it away cannot work, and the reason is one function in our own file.**
`rig_pose_once()` copies the **rifle's** transform onto the prop every frame. So the prop is not
merely *near* the mirror — **the prop's position IS the mirror's position.** Park it above the head
and the scope shows a reflection taken from above the head.

That is worth writing down plainly because the prop looks like scenery and behaves like scaffolding:
it is a **prefab borrowed from the game** (`sm80_382_totemeveryware_00_swing`, a hanging totem —
the "goat"), spawned only because the engine will not let us create a bare `via.render.Mirror` out
of nothing. We need a real object to bolt components onto. The prop is the object; the mirror is
the point.

## 2. ⭐ The same function gives the version that works

`rig_pose_once()` writes **`set_Position` and `set_Rotation`. Nothing else.**

And that is not a reading of one function — it is an exhaustive grep: **the only scale write
anywhere in the producer, the harness or the plugin is the one added today**
`[verified-numerically 2026-09-12]`. So a scale written once has nothing in our code to undo it.

A mirror plane is a point plus a normal. Neither has a size. ⇒ **shrink the prop to nothing and the
plane should not move** `[hypothesis]`.

**This is strictly better than `fn goat_hide`**, which was the previous plan: hiding disables the
mesh component, and whether the mirror keeps *producing* with its host mesh hidden has been an open
question in this file **since 2026-08-27, never tested by anyone**. Shrinking never touches the mesh.

## 3. What was built

- **`fn goat_shrink`** — ×0.001. **`fn goat_shrink2`** — ×0.05, deliberately *visible*: it tells
  "the shrink worked" apart from "the prop was never in view anyway", which a ×0.001 cannot.
- **`fn goat_unshrink`** — restores.
- **The prefab's own scale is captured on the first shrink**, not assumed to be `(1,1,1)` — these
  props are not all unit-scaled, and restoring a guess would be worse than not restoring. Captured
  **once**, so a second shrink cannot capture an already-shrunk value and strand the restore.
- **Refuses rather than guesses:** if the scale cannot be read, it does not write one it could not
  undo. If neither `set_LocalScale` nor `set_Scale` exists it says so and names the next step,
  rather than failing silently.
- **Every write is read back and logged**, with `<-- WRITE DID NOT LAND` when it disagrees — the
  file's standing discipline.
- **Re-assertion is made visible without a wear:** while a shrink is in force the periodic
  `sliders:` line echoes the live scale, with `<-- SCALE RE-ASSERTED` if it climbs back. If the game
  fights us, that shows up in the log rather than as a prop quietly reappearing in the headset.
- **`destroy_rig` forgets the captured scale** — a new rig is a new prefab, and a stale capture
  would restore the wrong number.

## 4. Verification

Parse-checked (`luac -p`, both files). The design's premise — that nothing else writes scale — is
the exhaustive grep in §2, which is the load-bearing check and the one that could have failed.
Deployed and re-stamped (4 files).

⚠️ **Not verified, and not verifiable without the game:** whether `via.render.Mirror`'s plane is
genuinely scale-invariant, and whether the game re-asserts the prop's scale. Both are the point of
the test below.

## 5. The test — three commands, any launch, in this order

```
fn goat_shrink2     <- x0.05: the prop should get small but stay visible
fn goat_shrink      <- x0.001: it should vanish
fn goat_unshrink    <- it should come back, at its own original size
```

| what happens | what it means |
| --- | --- |
| prop shrinks, **scope picture unchanged** | ⭐ **this is the fix.** Ship the shrink at rig build and the prop is gone for good, with the mesh never touched. |
| prop shrinks, **scope picture dies or distorts** | the mirror scales with its object after all. `fn goat_unshrink`, then fall back to `fn goat_hide` — and record that a plane in this engine is not scale-free, which is worth knowing beyond this project. |
| prop does not shrink, log says `WRITE DID NOT LAND` | the setter is wrong for this type; the log names what to run next. |
| it shrinks then the prop comes back, log says `SCALE RE-ASSERTED` | the game owns the scale. Then it is a per-frame hold, exactly like `Reticle_Emissive`. |

## 6. What is NOT established

- Everything in §5 — the whole point is that it has never been run.
- **Tefa's roomscale/stick constraint is recorded but not addressed**, because it does not apply
  while the prop rides the rifle. It becomes real the day anything is parked relative to the
  *player* rather than the weapon: it would then have to follow both smooth-turn and physical
  turning, and getting only one of those right looks fine standing still and wrong in play.
