# The wearer found it: it is the HEAD, not the rifle — and it clips on two sides only

**2026-09-20, home PC (RTX), live, wearer present.** The best data of the whole project, and none
of it came from an instrument.

## What Tefa reported, unprompted

> "it's not about the weapon being raised i now think, it's about my headset being lowered while
> looking at the scope. even eye level, when i point the hmd downwards and still keep looking at the
> scope, the same lines appear. they appear top of the scope and right of the scope, but i could not
> produce them at all at the bottom of the scope and on the left side of the scope, tried pointing
> hmd left right up down."

Three separate findings in that, and the log confirms all three.

## 1. ⭐⭐⭐ It is driven by the HEAD, not the rifle — and that is structurally right

The crop centre is computed **in the camera's frame** (`sg_compute_P` reflects the bore, then rotates
it by the inverse of the eye's rotation). So turning the head moves the crop just as surely as
moving the rifle — and the head moves faster and further than a shouldered rifle ever does.

The code has always said so, in a comment nobody had connected to the symptom: *"the mirror can only
show what the (reflected) head camera sees, so this is the usage limit"*. **The wearer derived that
limit from the outside, by moving their head and watching.** `[reported 2026-09-20, n=1 wearer]`

⚠️ **This also retires the test design.** Both A/B scripts asked them to raise the RIFLE. The rifle
was never the variable, so "C produced the same result" says nothing about C — the test could not
have separated them. Not a result; a void one.

## 2. ⭐⭐⭐ Top and right only — and the log says exactly that

Sampled from the same session `[measured 2026-09-20, n=1 launch]`:

```
centre=(0.789,-0.077)   centre=(1.055,-0.073)   centre=(0.750,0.007)
centre=(1.238, 0.141)   centre=(2.699, 7.442)   centre=(1.848,3.492)
```

Valid range is 0..1 in both. **`v` goes NEGATIVE — off the top. `u` goes ABOVE 1 — off the right.**
In the whole sample neither `v > 1` (bottom) nor `u < 0` (left) occurs.

**That is the wearer's report, in numbers, from the other side.** Top and right clip; bottom and left
do not. And it is precisely what §9ax predicted from the resting place: the crop rests **up and to
the right**, so it has almost no room on those two sides and plenty on the other two.

⭐ **Two independent confirmations of §9ax's resting-point finding in one evening** — the arithmetic
and the wearer, agreeing without either being told the other's answer.

## 3. The map goes fully degenerate, not just off-centre

`centre=(2.699, 7.442)` with `stretch 12.42 skew 78` is not "slightly outside" — it is a collapsed
map. That is what produces dragged lines rather than a merely mis-aimed picture: the crop is clamped
to an edge and the homography is stretching a sliver across the whole lens.

## 4. Test C is void, and its numbers were worse anyway

`geomusep 0` was applied at 00:30:11 and the centres after it are **wilder**, not tamer
(`(2.699,7.442)`, `(1.848,3.492)`) than before (`(0.789,-0.077)`). So even setting aside the void
test design, §9ax's suggestion that dropping the eye-projection term would buy headroom is
**not supported** — if anything the opposite. `[measured 2026-09-20, n=1]` ⚠️ Recorded as a
disappointment, not quietly dropped: it was my suggestion and it looks wrong.

## 5. ⚠️ The weapon fired itself during START-SCOPE step 2

Reported by the wearer. Step 2 is the re-arm keypress and nothing else. That step called
`SetForegroundWindow` before sending the key; stealing focus while a VR runtime holds the window is
the only thing in it capable of producing a stray input.

**Removed** — and it was never needed: on 2026-09-19 the same key landed while the window lookup had
failed outright, because the plugin polls it globally (`polled key 0x6E (VR route)`)
`[verified-live 2026-09-19, n=1]`. A focus call that bought nothing and cost a round.

## 6. ⭐ Where the effort goes now — Tefa's call

> "so can we not try and get the scope shooting right and pointing at the right thing?"

Yes, and there is a concrete suspect. **The zero was measured on 2026-09-13**
(`re8_scope_harness.lua:697`, `zeroup 14.4` / `zeroright 9.5`, *"the values are accurate"*
`[verified-live 2026-09-13, n=1 wearer, one spot]`) — **under the pane pose that §9ar replaced on
2026-09-18**, which moved the mirror viewpoint from roughly 0.9 m below the head to exactly at the
eye.

**A zero calibrated before that change has no reason to hold after it**, and "aimed lower and to the
left" is the shape of error it would leave. `[hypothesis]`

Shipped to test it: `ZERO-A-OFF`, `ZERO-B-SHIPPED` and four 2° nudges, with `READ-ME-ZEROING.txt`
written to the numbered-steps rules (lanes `PROTOCOL.md` §10) — preconditions, a raw baseline with
zeroing off, the old values for comparison, a nudge rule in the wearer's terms, and a check from a
second position because a zero fitted to one spot is not a zero.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
