# 2026-09-16c — the weapon-switch glass flash: a restore that waits (`/pd`, dev PC, Opus, NO LAUNCH)

**The game was not launched and nothing here has been run.**

## 1. The row

*The stock glass flashes for about a second on a weapon switch.* The game registers the new weapon at
once, so the plugin put the stock glass back at once, but the rifle stays in view for about a second
while it is put away `[reported 2026-09-14, n=1 wearer]`. Two ideas were on the board: make weapon
switches instant (a game change), or delay the restore until the rifle is gone. Tefa decides.

## 2. Why it happens (from the code, `[inferred-static 2026-09-16]`)

The world tick compares the equipped weapon object each tick. The moment it changes it calls
`restore_scope_glass()` and `set_lens_materials(true)`, because our binds belong to the old rifle's
mesh and the code wanted to hand the originals back "before we lose the handle to it". Nothing waits
for the put-away animation, so for that second the rifle shows the stock lens.

## 3. What was built (compile-verified, deployed on the dev PC, NOT run)

The second idea, as a knob, **off by default** so the shipped behaviour is unchanged until Tefa picks:

- **`swdelay <ms>`** (harness; settings key `sw_delay`; live through the pane file). When the scoped
  rifle leaves the hands and the delay is above 0, the restore is **scheduled** instead of done. The
  glass keeps our picture, frozen on its last frame, since the compositor only draws while a scoped
  rifle is in hand.
- When the delay runs out, the stock glass goes back exactly as before.
- **If the same rifle comes back before then, nothing is restored at all.** The bind records which rifle
  it belongs to, so a quick switch away and back never touches the glass. The existing auto re-bind
  still fires and is harmless.
- A different scoped rifle, or a second switch, restores at once, the old way. A load screen that
  drops the binds cancels the pending restore.
- Try **`swdelay 1500`**. Range 0 to 5000.

Plugin 0 errors, 0 warnings; all six suites still pass (16 / 124 / 40 / 176 / 20 / tone); fxc 5/5;
three Lua files compile; `bringup_sequence_test` 29/29. Dev-PC install re-stamped 14/14.

## 4. What is NOT established

- **That the old rifle's mesh is still alive when the delayed restore runs** `[hypothesis]`. The binds
  hold no reference on the mesh. If the game destroys the rifle object on a switch instead of keeping
  it, a restore 1.5 s later touches a dead object. The immediate restore never had that exposure.
  If a switch with `swdelay` on ever crashes the game, this is why; set it back to 0.
- The right delay. "About a second" is one wearer's estimate.
- Whether a frozen last frame on the glass for that second looks better than the stock lens. It should,
  but that is the wear's call.

**The diagnostic that would show the idea is wrong rather than the number:** with `swdelay 3000` the
stock lens still appears during the put-away. Then something other than our restore puts it back —
the game re-applying the rifle's materials on unequip — and a delay cannot help. The log shows
`switch: rifle leaving the hands -- glass restore deferred` first, so the order is checkable.

## 5. NEXT (headset, home PC)

1. `swdelay 1500`, switch from the rifle to the pistol: is the flash gone?
2. Switch away and straight back within a second: the log should say `the same rifle came back before
   the deferred restore`, and the glass should never flicker.
3. If the flash is gone and nothing crashed, write `sw_delay=1500` into the settings file, or tell the
   next session to make it the default.
