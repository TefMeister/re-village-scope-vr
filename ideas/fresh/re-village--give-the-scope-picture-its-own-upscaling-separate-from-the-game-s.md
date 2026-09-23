# Give the scope picture its own upscaling, separate from the game's

Order: 4007
From: mod-ideas `games/re-village.md` (<https://github.com/TefMeister/mod-ideas/blob/main/games/re-village.md>), copied 2026-09-23

`[raw]` · `[looks doable]` — *not tried; the sums below are from our own notes, not from a test*

> "is there any other way to, maybe upscale the scope picture differently to the game itself? i
> doubt it, so yeah it has to be lower resolution. i have a beast of a pc and it is still showing
> that it can't handle it well in open areas" — 2026-09-21

The doubt is understandable but there **is** a way, because of how the scope is made. The scope
picture is the whole scene drawn a second time, and the mod then cuts the middle out of it and
blows that up to make the zoom. That last step is entirely ours — so it can sharpen while it
enlarges, the same trick the game's own upscalers use, applied to the scope alone. A smaller,
cheaper second drawing could then look close to the big one.

Three separate ways to make the scope cheaper, cheapest first:

1. **Draw it smaller and sharpen it ourselves** (this idea). Costs a small amount of work per
   frame in a step the mod already runs.
2. **Only draw it while the rifle is actually up.** The second drawing is what costs the frames in
   open areas; if the scope is nowhere near the eye, nobody is looking at it. Probably the biggest
   win of the three for ordinary play, and nothing to do with picture quality.
3. **Stop drawing the parts that get thrown away.** Most of the second drawing is cut off to make
   the zoom. Drawing only the narrow part the scope shows would make even a small picture sharp —
   but it means changing the second camera's field of view, which the notes say is the hard one.

**What it'd take:** (1) a sharpening pass in the mod's own draw step; (2) a rule for "rifle is up"
— the mod already knows where the scope is relative to the eye — plus making sure switching the
second drawing off and on does not bring back the black-picture problem; (3) real engine work.

⚠️ **Unchecked.** None of the three has been tried. (2) in particular depends on whether the
second drawing can be paused and resumed cleanly on this engine, which is exactly the area that
has bitten before.

Verbatim record: [`inbox/2026-09-21c-re-village-upscale-the-scope-picture-separately.md`](../inbox/2026-09-21c-re-village-upscale-the-scope-picture-separately.md)
