# Nothing clips the mirror — the viewpoint goes under the ground, and `off_u` drives it at double speed

**2026-09-18, dev PC `DESKTOP-V8GTSIR`, `/pd`, Opus. THE GAME WAS NOT LAUNCHED AND NOTHING HERE HAS BEEN RUN.**

The board row was *"(c) what clips the mirror, for the ground when crouched"* — split out of the
clothing row as the one part still unanswered, and filed as geometry. Reading the shipped geometry
says **the premise is wrong: nothing clips it.** The point the picture is *rendered from* descends
below the terrain, so the engine draws the world from underneath, which is what reads as "half under
the ground".

---

## 1. Three facts that were already proved, never put together

1. **The scope's picture is an engine planar reflection** off a `via.render.Mirror`. A planar
   reflection renders the scene from the camera **mirrored across the plane** — that is how a floor
   mirror shows you the ceiling. So the picture is not a view from the rifle; it is a view from a
   point on the far side of the pane.
2. **The worn pane's normal is the rifle's own up/down axis** — `(-0.0000, -1.0000, 0.0000)` in the
   rifle frame, i.e. the plane is **horizontal** `[verified-numerically 2026-09-16,
   tools/prop_offset_check.cpp]`.
3. **Of the three prop offsets, only `off_u` moves that plane.** `off_f` and `off_r` slide the pane
   *within* its own plane, and a planar mirror depends only on its plane, so they cannot move the
   viewpoint at all; `off_u 1 m` moves the plane a full metre along its normal `[verified-numerically
   2026-09-16, same tool]`.

Each has been in the repo for two days. Put together they say something none of them says alone.

## 2. ⭐ The lever

Reflecting across a plane that has moved by *d* along its normal moves the reflected point by **2d**.

So **every centimetre `off_u` lowers the pane costs two centimetres of viewpoint height.** The parked
`off_u = -0.2` is not a 20 cm framing tweak — it drops the eye the picture is taken from by **40 cm**.

The test walks the wearer's own scenario and prints it:

```
  standing  off_u +0.0 -> pane 1.20 m, viewpoint +0.80 m, above the floor by 0.80 m
  standing  off_u -0.2 -> pane 1.00 m, viewpoint +0.40 m, above the floor by 0.40 m
  crouched  off_u +0.0 -> pane 0.75 m, viewpoint +0.50 m, above the floor by 0.50 m
  crouched  off_u -0.2 -> pane 0.55 m, viewpoint +0.10 m, above the floor by 0.10 m
```

Standing has 0.80 m of headroom. The parked offset halves it. Crouching spends most of the rest.
**Crouched with the offset leaves 0.10 m — the picture is being taken from the wearer's ankles**, and
another 0.1 m of pane puts it through the floor. (Heights are illustrative; the *relationship* is
what is being shown, and it is the shipped reflection that computes it.)

### ⚠️ And this is why "no prop height is clean"

`off_u` has been used as a framing knob all along. It is not one. It is **the only offset that moves
the viewpoint, and it does so at 2× gain**, while the two that *are* safe to frame with — `off_f`
and `off_r` — provably cannot move the viewpoint at all. Every attempt to frame the picture with
`off_u` has been walking the viewpoint towards the floor, and the closer the wearer was to crouching
the sooner it arrived. That reframes the knob rather than tuning it.

## 3. What was built

* `plugin/src/mirror_ground.h` — pure, no D3D, so the test runs the shipped code: the reflection,
  the height lever, the margin above the floor, and *"how much `off_u` would buy"*.
* **The floor is now published and reported.** The producer sends the player's own root Y (`foot_y`)
  in the pane file, reached by the same `re8vr.player` handle `body.lua` uses. The plugin reads it
  and the `crop-follow` block prints one line: where the picture is taken from, the floor, the margin,
  the lever, and the `off_u` change that would leave 0.50 m of clearance. Without it, "half under the
  ground" stays a judgement by eye.

**mirror_ground_test: 28/28, proved able to fail on seven mutants** `[verified-numerically 2026-09-18]`
— the reflection's factor of two, the lever's factor of two, a degenerate normal returning junk, the
edge-on plane dividing by nothing, the producer not publishing the floor, the plugin not parsing it,
and the log not saying when it is missing.

⚠️ §6 of the test exists for the same reason `frame_v2_test` §7 and `jitter_test` §7 do: **sections
1–5 are arithmetic and would all keep passing with the floor never published, never parsed and never
printed.** The first sign would be a wasted launch whose log says nothing about the ground.

## 4. ⚠️ Reported, never enforced — and what is not established

**No clamp was added**, and that is deliberate. That the wearer's "half under the ground" *is* a sunken
viewpoint rather than a clip is `[hypothesis]` — strongly supported by the geometry, and not observed.
Clamping a knob on a hypothesis is how a knob becomes a mystery, and this project has two of those
already. The line reports; the next launch decides.

**The discriminator is in the picture and costs nothing:**

| what you see | what it is |
| --- | --- |
| a hard cut, with correct content above it | a **clip** — the hypothesis is wrong and §2's arithmetic is beside the point |
| the underside of the terrain, horizon moving the wrong way as you look around | a **sunken viewpoint** — as derived |

And the log answers it directly: the `ground:` line gives the margin as a number. Negative is
underground.

Also not established: the illustrative heights in §2. The *lever* is exact and comes from the shipped
reflection; the specific 0.80 / 0.10 figures assume plausible standing and crouched heights and will
be replaced by the real ones the moment the line prints.

## 5. Deployed

Rebuilt with the bundled VS CMake; the DLL and `pane.lua` deployed with dated `.bak-2026-09-18e`
backups; 28 files re-stamped and hash-verified. **Fourteen** plugin suites and nine producer suites
pass.

**Nothing here has been run.** Next launch, no extra trip — with the scope up and `cropfollow 1`, read
the `ground:` line standing, then crouched. If the margin goes negative when crouched, the row is
answered and the fix is a clamp on `off_u`, whose exact size the same line already prints.

Credit: **praydog** (REFramework).
