# When the scope picture would smear, show the lens glass instead

Order: 4004
From: mod-ideas `games/re-village.md` (<https://github.com/TefMeister/mod-ideas/blob/main/games/re-village.md>), copied 2026-09-23

`[raw]` · `[looks doable]` — *not tried; this is a way of HIDING the fault, not fixing it*

> "still something to look at or mask somehow, maybe the weapon glass with the reflection on it can
> be introduced back on the lens at these angles?" — 2026-09-20, mid-test

The scope picture streaks into dragged lines when the rifle is tilted a long way to one side, or the
head is turned well away from it. The cause is understood: the picture is a window cut out of what
your head can see, and past a certain angle the part it wants **was never drawn**, so it smears the
edge instead.

This idea does not try to get that picture back — it accepts that it is gone and **puts something
believable there instead**: the scope's own glass, catching the light, the way a real scope goes
opaque and glary when your eye is not lined up behind it.

⭐ **Why it is a good instinct:** it is not a cheat, it is what actually happens. A real telescopic
sight shows you a useless bright disc the moment your eye leaves the exit pupil. So the failure
angle and the effect coincide with something a player already expects — the mod would stop looking
broken and start looking like a scope.

**What it'd take:** the game ships lens materials for this rifle
(`it02_070_sniperrifle_01`, `Weapon_SniperScopeLens2.mmtr`, with `EyeDistortionRange` and
`ConvexNormal_CenterPos` among its variables), and the mod already swaps what is drawn on the glass,
so the pieces exist. The work is knowing **when** to swap: the mod can already tell how far off the
usable angle it is, so the trigger is available. Blending in rather than snapping would matter a lot
here — a hard cut would read as a bug of its own.

⚠️ **Unchecked.** Nothing here has been tried, and whether the stock lens material can be shown on
demand at a chosen moment is not known.

Verbatim record: [`inbox/2026-09-20-re-village-mask-the-scope-streak-with-lens-glare.md`](../inbox/2026-09-20-re-village-mask-the-scope-streak-with-lens-glare.md)
