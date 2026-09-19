# The steering writes the numbers and the picture ignores them — and the smear is in both eyes

**2026-09-19, home PC (RTX), one launch, flat, wearer present.** The evening's third note, and the
one that matters. Two independent results, both pointing the same way, and both against §9aq.

---

## 1. The steer was driven hard, and the picture did not move `[verified-live 2026-09-19, n=1]`

Tefa dragged the manual yaw and pitch sliders and reported: **"manual steer did nothing to the
picture."**

The log says the numbers arrived:

```
[VR] Mirror steering #56400: base=eye yaw=-28.51 pitch=-24.30 deg (source=slider)
     m00=0.9848 m11=1.1696 m20 -0.1736->+0.5349 m21 -0.2111->+0.5280 invert=false hmd=true
```

That is not a subtle nudge. `m20` went from −0.17 to +0.53 — the frame's centre thrown most of a
frame-width sideways. **56,400 of those writes, and nothing on the glass changed.**

**So the hook fires, inside a genuinely mirror-bearing scene layer, and what it returns is not what
the scope draws with.** Yesterday's conclusion — "the hook is the right lever" — was too strong: it
proved the hook *reaches the pass*, which is not the same thing and I should have written it that
way. Corrected here.

⚠️ **This is not a sign problem.** Invert flips which way the frame would go; it cannot turn *no
movement* into movement. Do not reach for it as the explanation.

### What the counters say about where we are

```
Mirror-bearing scene layer seen (update): layer=1e5b8bddbc0 mirror=1e5a0ae1f50
    camera=1e5a9b6c7d0 primary=1e5a9b6c7d0 camera_is_primary=true camera_go="MainCamera"
Mirror layer windows=1200  get_ProjectionMatrix calls inside=600  get_ViewMatrix calls inside=600
```

The window is real and the getter is called inside it. Two candidates remain, and this session
cannot separate them:

- **(a) The mirror renders from a projection captured somewhere other than this getter** — already
  baked into a constant buffer by the time the layer draws, so the getter is observational for this
  pass. `[hypothesis]`
- **(b) The calls caught inside the window are not the mirror's own render** — some other consumer
  asking the camera a question while the window happens to be open. `[hypothesis]`

### ⭐ Corroboration that was sitting on a filename the whole time

The 2026-09-12 exemption build is on disk as
`dinput8_pd-upscaler_76298bd_mirror-exemption_2026-09-12_TESTED-swing-unchanged-double-eye.dll`.
**"swing unchanged"** — that patch also wrote this getter inside the mirror window, also fired, and
also changed nothing about the picture. Two independent attempts, two months apart, same site, same
null result. That is a pattern, not a coincidence, and it should have been read that way before
today's build was made.

## 2. The smear is in BOTH eyes `[reported 2026-09-19, n=1 wearer]`

Tefa, unprompted: **"smear happens with both eyes"**, seen "when first looking into it and turning
the scope far left and far right."

§9aq §3 predicted a band roughly 10° wide in which **one eye smears and the other is clean**,
because the two eyes carry mirrored off-centre shifts and therefore clamp at +38.71° and +49.09° on
the same side. **That band was not observed.** The dossier itself said a `no` here "is a real
problem for it" — so it is recorded as one, not explained away.

⚠️ **What this does and does not prove.** The band is narrow and the picture is busy, so a wearer
sweeping past it could miss it; this is `n=1` and not a controlled sweep. But it is the second
independent result today pointing away from §9aq, and the first one (above) is not subtle at all.

**Closes** `owed/HOME/2026-09-19-re-village-scope-does-the-scope-smear-ever-show-in-one-eye-o.md`.

## 3. So §9aq's premise is now itself in question

§9aq's whole argument starts from *"the mirror is drawn at the HMD eye's field of view (90.88°)"*.
That was read **from this same getter** `[verified-live 2026-09-12, n=1]`. If the mirror does not
render with what this getter returns, then the getter's 90.88° describes something other than the
scope's picture — and the crop-clamp arithmetic, the 38.71°/49.09° onsets, and the match to the
measured 20–44° bore range all lose their foundation. The arithmetic was never wrong; **what it was
arithmetic *about* is now unclear.**

The match to 20–44° remains striking and may still mean something. It is no longer evidence.

## 4. The next test, built and waiting: SHOUT mode

One question, unmissable answer: **does the projection written at this hook reach the scope picture
at all?**

`VR_MirrorProjectionShout` halves `m00`/`m11` inside the mirror window, which **doubles the drawn
field of view**. Not a nudge — the picture either visibly pulls back or it does not.

- **Picture zooms out** → the projection IS ours, and the steer's failure is something narrower
  (how the plugin crops it, most likely). §9aq survives.
- **Picture unchanged** → the projection is NOT ours, §9aq's premise falls, and the whole approach
  moves somewhere else. Everything built today becomes a dead end, cleanly and cheaply.

Built and compile-verified (MSBuild RE8.vcxproj Release x64, 0 warnings 0 errors), staged as
`dinput8_pd-upscaler_76298bd_mirror-steering-plus-shout_2026-09-19_NOT-YET-TESTED.dll`, and
`SCOPE-STEER-ON.bat` now points at it. Needs the game closed and relaunched.
⚠️ **Diagnostic only — never ship it on.**

## 5. Separately: the 35-second wait is almost entirely waiting

Tefa asked whether the bring-up could be shorter for players. From the log:

| | |
| --- | --- |
| `bringup: START` | 22:59:35.518 |
| rig spawned, mirror component created | 22:59:35.577 — **59 ms later** |
| first `bind` press | 22:59:43.6 (+8 s) |
| re-press 1 | 22:59:48.6 (+13 s) |
| re-press 2 | 23:00:03.7 (+28 s) |
| `bringup: DONE` | 23:00:03.708 |

**The work takes 59 milliseconds. The remaining 28 seconds is the harness pressing "bind" three
times with long gaps, because a single press does not reliably take.** `[measured 2026-09-19, n=1]`

So it is not slow — it is *cautious*, and it is cautious in the most expensive possible way: a fixed
worst-case wait paid by every player on every launch, whether or not it was needed.

**The fix is to make it react rather than wait**: bind once, check whether it took, and press again
only if it did not. The bind already logs its own outcome, so the check exists. That would make a
successful bring-up **effectively instant** and leave the long path only for the cases that need it.
⚠️ Not attempted; the "did it take?" check is the part that needs proving, and the session log
already shows one bind reporting *"no stable identity for the bound texture — the bind-order guard
is DISABLED this session"*, which is exactly the signal that would have to be made trustworthy first.

Credit: **praydog** (REFramework), **gmankab** (the `pd-upscaler` fork).
