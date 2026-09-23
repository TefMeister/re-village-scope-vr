# Move the scope's viewpoint right up against the rifle

Order: 4003
From: mod-ideas `games/re-village.md` (<https://github.com/TefMeister/mod-ideas/blob/main/games/re-village.md>), copied 2026-09-23

`[raw]` · `[looks doable]` — *not checked; this one is about the live project, so it is checkable soon*

> "can the hand ride closer to the weapon, as it's invisible. reason why, is right now it picks up
> picture through the ground and leaves and sometimes still shows Ethan's clothing, if it could be
> right next to the actual scope, maybe then none of these issues would exist"

Verbatim record: [`inbox/2026-09-14g-re8-scope-hand-rides-closer-to-weapon.md`](../inbox/2026-09-14g-re8-scope-hand-rides-closer-to-weapon.md)

The scope's picture is taken from a point that is currently sitting a little away from the rifle —
far enough that it sometimes sees **through the ground and through leaves**, and sometimes catches
**Ethan's own clothing**. The suggestion is to slide that point right up next to the real scope, and
expect all three faults to go away at once.

⭐ **This is a diagnosis, not just a request, and it is very likely the right one.** All three
complaints are the same complaint: *the picture is being taken from somewhere a scope is not.* Seeing
through the ground is what happens when the viewpoint has sunk below it; seeing your own clothes is
what happens when it is sitting inside the character. Move it to where the glass actually is and
there is nothing left for those faults to come from. It is worth flagging that this arrived **from
the headset**, from noticing three separate oddities and realising they were one — that is exactly
the kind of observation static analysis never produces.

**What it'd take:** the scope already renders from a chosen point each frame, so this is changing
**where that point is** — moving it to the rifle's own scope rather than an independent spot. The
piece that has to be found is what the picture should be pinned to: the weapon itself, so it follows
the rifle as it moves and tilts, rather than being pinned to the hand or to the room.

⚠️ **The one way this could disappoint:** if the viewpoint ends up *too* close to the rifle model, it
may start clipping into the rifle instead — trading "sees Ethan's sleeve" for "sees the inside of the
barrel". There is likely a small sweet spot rather than a simply-better position, and finding it is a
wear-it-and-look job, not a calculation.

⚠️ **Unchecked**, but this is on the live project with the code already in hand, so it is one of the
cheaper things on this page to actually try.
