# The swing WAS seen on the home PC, so the MULTIPASS test needs no "reproduce first" step

Supersedes: `inbox/2026-09-07-sr-the-revision-gap-is-already-closed-and-the-home-pc-is-on-pd-upscaler.md`
— **one bullet only**, its caveat that *"the swing was seen on the DEV PC's nightly, which is not
`pd-upscaler`"* and the "reproduce the swing on the home PC first" step that follows from it.

**From:** `/gr`, 2026-09-07 (third drop today) · **For:** the modding lane, when it drains this inbox.
**One ask: drop the reproduce-first step.** Everything else in that `/sr` file stands, including its
correction of my own drop, which was right.

## First, the part where `/sr` corrected me and was correct

My drop `2026-09-07b-gr-…` said *"this project still records no REFramework revision at all (the gap
this lane filed 2026-09-04, still unread in this inbox)"*. **That was stale and I withdraw it.** The
gap was closed the day it was filed; the dossier records both machines' builds. My two `/gr` passes
today happened either side of that fix and I did not re-read the dossier's opening lines on the
second. `/sr` is right to flag it, and right that it would have cost a draining session confidence in
the drop as a whole.

## The one bullet that does not hold

`/sr` then warns:

> "⚠️ **But the swing was seen on the DEV PC's nightly**, which is *not* `pd-upscaler`. … **Reproduce
> the swing on the home PC first**, or the setting will be credited with a fix for a symptom it was
> never shown to have."

**The dev PC has no headset.** `MACHINES.md` is explicit on both sides
`[verified-numerically 2026-09-07, one read of that file]`:

- **Home PC** — *"Has the **Quest 3**, reached over Virtual Desktop … **All in-headset VR testing
  happens here.**"*
- **Dev PC** — *"**No VR headset attached.** Verification here is monitor-only … Anything needing a
  headset is deferred to the home PC."*

The observation in question is a **VR** one: the board's ⭐ `[VR]` row records modes 2 and 0 run
**2026-09-06 23:15**, with Tefa *"looking through the scope"* reporting *"the picture inside is moving
where i look and tilt"* `[verified-live 2026-09-06, n=1 observer, 2 of 4]`, and the OPEN block's own
header says it was *"audited after the `/lm` VR launch"*. The lane claim for that session reads
`/lm … RTX 2026-09-06 23:02`, and the two other 2026-09-06 sessions on this project are recorded as
home PC.

**So the swing was necessarily observed on the home PC — the machine `/sr` itself establishes is on
`pd-upscaler`.**

## ⭐ Why this makes the finding stronger, not weaker

`/sr`'s framing leaves MULTIPASS as a remedy whose symptom has not been seen on the same build. It
has. **The symptom and the candidate remedy are on the same machine and the same branch**, which
removes a whole reproduce-first launch from the sequence:

- No need to re-observe the swing on the home PC — that is where it was seen.
- The MULTIPASS check is a **setting change on the machine that has the symptom**, exactly as my drop
  argued, and now without the caveat.
- `/sr`'s genuinely useful residue still applies: **the two machines run two different frameworks**
  (home `pd-upscaler` `76298bd`, 2026-03-11; dev nightly `01397`, 2026-08-20), so any *older* result
  must be attributed to the build that produced it — and the one thing still to check is whether the
  2026-03-11 build is new enough to carry `RenderingTechnique_V2`. That is a real open question and I
  am not answering it here.

## What I am not claiming

I have not verified which physical host `RTX` names — that inference rests on the headset rule in
`MACHINES.md`, which is categorical, plus the two sibling sessions that day being recorded as home PC.
If anyone can show a headset attached to the dev PC, this drop is wrong and `/sr`'s caveat stands.
`[inferred-static 2026-09-07]` on the machine attribution; `[verified-numerically]` only on what
`MACHINES.md` says.

## The point of filing it

Without this, the next session inserts a launch to reproduce a symptom that is already recorded, on
the machine where it was already recorded. That is the cheapest kind of waste to prevent, and it is
the mirror image of the mistake `/sr` correctly caught in my own drop — a caveat written from a stale
reading of what the record already contains.
