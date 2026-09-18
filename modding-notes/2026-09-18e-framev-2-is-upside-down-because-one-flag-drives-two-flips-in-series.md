# `framev 2` is upside down because one flag drives two flips in series — and that is also why numpad 7 does nothing

**2026-09-18, dev PC `DESKTOP-V8GTSIR`, `/pd`, Opus. THE GAME WAS NOT LAUNCHED AND NOTHING HERE HAS BEEN RUN.**

The board carried this as a `[PD]` row with two candidate explanations: *"either `glass_flip_v` does not
reach the picture under `framev 2`, or the 09-16h note puts the v-flip in the wrong place."* It is the
second, and more precisely than that phrasing suggests.

---

## 1. The two complaints are one fault

The 2026-09-17 headset session reported two things about `framev 2`, and they read as separate:

* the picture is **upside down, with vertical motion inverted**;
* pressing **`7 Glass flip V` flips `glassFlipV` in the log with no visible change**
  `[verified-live 2026-09-17, n=1]`.

`glass_flip_v` is read **twice, on the same path, in series**:

| where | what it does |
| --- | --- |
| `crop_follow.cpp` | derives `vneg`, which negates the frame's `ry` — it flips the **content** of the scope image, through `H` |
| `present.cpp` → `ps_blit` | uploaded as `_pad.x`; the shader does `uv.y = 1.0 - uv.y` — it flips the **finished image** as it is pushed into the glass material |

Two flips in series multiply:

```
              frame ry sign     ps_blit sign      product
glass_flip_v 0      -1        ×      +1         =   -1
glass_flip_v 1      +1        ×      -1         =   -1
```

**The product is constant.** So under `framev 2` the picture's vertical orientation is fixed by the
code and numpad 7 cannot move it — which is complaint two — and it is fixed at whichever orientation
that constant is, which the wearer found to be the wrong one, which is complaint one. Under
`framev 1` the frame never reads the flag, so only `ps_blit` moves and 7 works normally. **That is why
only v2 showed it.**

## 2. What is proved, and what deliberately is not

⭐ **That the product is constant is proved, and it needs nothing at all about the lens material.**
`tools/frame_v2_test.cpp` §6 runs the shipped `sg_rifle_frame_rh` for both knob states and multiplies
by `ps_blit`'s one line: **38/38, was 25** `[verified-numerically 2026-09-18]`. So *"7 cannot fix it"*
is settled, not suspected.

⚠️ **Which constant it lands on is NOT proved and is not guessable from here.** Whether that fixed
orientation is upright or upside down depends on the lens material's own sampling sign — a property of
the game's shipped material, not of our code. Two internally consistent models of that sign both exist
and they disagree about which way up `framev 2` should look; the headset says one of them is wrong, and
nothing static distinguishes them `[hypothesis]`.

**So this session did not change a sign.** Picking one would have been a coin flip dressed as a fix,
and a wrong one costs a whole wear to discover. Instead:

## 3. `framevneg` — break the coupling and let one launch decide

A new knob, `framevneg -1 | 0 | 1`:

* **`-1` (the shipped default)** — `vneg` follows `glass_flip_v` exactly as before. Nothing changes for
  anyone who does not use the word, and `framev 1` is untouched either way.
* **`0` / `1`** — force the frame's half of the coupling. The frame then stops following
  `glass_flip_v`, so the product varies again and **numpad 7 works under `framev 2`**.

§6 also proves the two forced states are exact opposites, so **between `framevneg 0` and `framevneg 1`
one of them is the right way up, whatever the lens turns out to do.** That converts an unresolvable
symptom into a two-click A/B inside one launch.

It is wired end to end — harness word, producer state field, pane-file key and argument position,
plugin key — and `knob_chain_test` checks all four links: **46/46, was 41** `[verified-numerically 2026-09-18]`.
It is also persisted, so it went into the boot-value registry from §9ae, which `boot_values_test`
picked up by itself: **157/157, was 152**, with no edit to that test. That is the registry's re-derive
doing its job.

The three words also have **panel buttons**, so the A/B costs no trip out to the desktop.

## 4. ⚠️ A model is not the shipped code — §7 exists because §6 alone would rot

§6 computes the coupling from a model written inside the test file. Change `crop_follow.cpp` or
`ps_blit` and §6 goes on passing while describing a plugin that no longer exists — a green test
asserting something about code that is gone.

So §7 reads the three joins as text from `crop_follow.cpp`, `present.cpp` and `shader_src.cpp`: the
frame's coupling, the `framevneg` override, and `ps_blit`'s own flip. **Proved able to fail on five
mutants, one per join plus the frame function itself** `[verified-numerically 2026-09-18]`:

| break | caught by |
| --- | --- |
| the frame stops honouring `vneg` | 5 (§5, 6b, 6d, 6g) |
| the shipped coupling is rewritten | 7b |
| the `framevneg` override is dropped | 7c |
| `ps_blit` stops flipping `uv.y` | 7e |
| `present.cpp` stops sending the flag | 7d |

This is the same lesson as the mutation run earlier today, arriving from the other direction: there,
a suite of pure-logic checks did not cover the wire joining them; here, a proof about the maths would
not have noticed the maths being disconnected from the plugin.

## 5. What the next launch should do

One launch, `framev 2` on, and the three buttons:

1. **`framevneg 0`** — is the picture the right way up?
2. **`framevneg 1`** — is it the right way up now?

Exactly one of them should be. Then:

* **One is upright** → that value becomes `frame_vneg`'s shipped default and the row closes. Put the
  line in `re_scope_vr_settings.txt` to keep it for the session, because since §9ae a harness word is
  no longer persisted by a numpad press.
* **Neither is upright** → the fault is not the frame's vertical baseline at all, and §6's arithmetic
  says it cannot be the knob either. Look downstream of `H`.
* **Both look the same** → `framevneg` is not reaching the plugin. Check for the
  `frame_vneg -> ...` line in the log; no line means the word never arrived, and no echo means no test.

⚠️ While `framevneg` is at `-1`, **numpad 7 is inert under `framev 2` by construction.** That is not a
bug to re-report; it is the thing this note is about.

## 6. Deployed, and what is not established

Rebuilt with the bundled VS CMake, four files deployed with dated `.bak-2026-09-18c` backups — the
DLL, `panel.lua`, `pane.lua` and the harness — and all 28 files re-stamped and hash-verified. Twelve
plugin suites and nine producer suites pass.

**Nothing here has been run.** The constant-product proof is arithmetic on the shipped code, not an
observation; the knob is `[compile-verified 2026-09-18]` and has never moved a picture.

Credit: **praydog** (REFramework).
