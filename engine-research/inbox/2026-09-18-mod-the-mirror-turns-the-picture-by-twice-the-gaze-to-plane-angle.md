# The mirror turns the picture by TWICE the gaze-to-plane angle — the direction law §9ai never asked about

Supersedes: ENGINE-DOSSIER.md §9ai (completeness of, not its arithmetic) — and see "What this does NOT
withdraw" below, which is longer than what it does.

**2026-09-18, `/lm` home PC `RTX`, STATIC ONLY — the game was not launched, nothing was deployed.**
Derived by reading, then verified numerically against the shipped `cf_pane_from_rig` and the shipped
`mground` helpers by a new offline tool, `plugin/tools/bore_plane_check.cpp` (23 checks, 0 failed,
proved able to fail on a mutant: proposed yaw 90 → 45 fails 7 of them)
`[verified-numerically 2026-09-18]`.

Triggered by the wearer, unprompted, 2026-09-18: *"picture is coming from above, like the camera is
pointing down from the sky"* `[reported 2026-09-18, n=1 wearer]` — and by a live `ground:` reading the
same day: `pane = -32.17`, `head = -33.07`, viewpoint `y = -33.03`, `off_u lever` **−0.38 to −0.68**
`[measured 2026-09-18]`.

---

## 1. The finding

§9ai established where the viewpoint sits. **It never asked where the picture POINTS.** A planar
mirror reflects the view direction as well as the view position:

```
    v' = v - 2 (v · n) n            and therefore      v · v' = 1 - 2 sin²α = cos 2α
```

where **α is the angle between the head's gaze and the mirror plane**. So:

> **⭐ The picture's direction error is exactly TWICE the angle between the gaze and the plane, and it
> is zero only while the gaze lies IN the plane.**

`[verified-numerically 2026-09-18, bore_plane_check §2 — 0/5/10/…/40° in, 0/10/20/…/80° out, exact]`

**This is independent of where the plane is.** The reflection of a direction uses only the normal. So
the picture can be taken from precisely the right spot and still point at the sky — which is what the
wearer is describing, and **no value of `off_u` can touch it.**

The position law, restated correctly while we are here: the viewpoint moves **2× the eye's
PERPENDICULAR distance from the plane** `[verified-numerically 2026-09-18, §3]`. §9ai's "2× the
height" is the same law seen through a plane that happens to be horizontal.

## 2. Three things that were already true and had not been put together

- **⭐ The pane normal is ALREADY perpendicular to the bore, and always has been.** The normal is the
  rig's local +Y, which through `cf_pane_from_rig` is the rifle's own up axis; a transform's axes are
  orthonormal, so `normal · bore = 0` at every pitch, yaw and roll
  `[verified-numerically 2026-09-18, §1, swept 15° over the full pitch×yaw grid]`. **"Make the normal
  perpendicular to the barrel" is not an available improvement — it is the starting state.**
- **The shipped pose makes the plane HORIZONTAL** (normal = the rifle's −Y). A horizontal plane
  contains a level gaze — so it is correct exactly when the head and the rifle agree in pitch, and
  **doubles every degree of disagreement**. §9h measured the hip carry as *the bore ~40° off the gaze*,
  and §9g found that pose on **29 of 41 VR samples**. Forty degrees of mismatch is eighty degrees of
  thrown picture. That is the "from the sky" complaint, quantitatively.
- **`off_u` is a framing knob that moves the viewpoint, and `pitch`/`yaw` are aiming knobs that move
  the DIRECTION at 2× gain.** Nobody has ever tuned the second pair for VR. The shipped
  `pitch 180 / yaw 90` are recorded as *"the user's refined working angles (2026-08-30)"* — tuned by eye
  **in FLAT**, where the viewing camera sits on the bore and gaze-to-plane mismatch is zero by
  construction. They were carried into VR unchanged and never re-derived `[inferred-static 2026-09-18]`.

## 3. The proposed pose, and its arithmetic

Put the normal on the rifle's **right** axis, so the plane is the rifle's own **vertical centre
plane** — containing the bore *and* the up axis.

```
    pitch 90    yaw 90     ->  normal = (+1, 0, 0) in the rifle frame
    propf 0     propu 0    ->  both now lie IN the plane and are inert
    propr 0                ->  the plane passes through the rifle's centre line
```

`[verified-numerically 2026-09-18, §4]` — run through the shipped function, not hand-derived.

Why it is better: a cheeked scope holds the **left/right** relationship between eye and rifle tightly
and the **up/down** one loosely. A horizontal plane doubles the loose axis; a vertical plane is blind
to it and doubles the tight one instead. With the rifle pitched away from a level gaze by 0/10/20/30/40°
the shipped pane throws the picture **0/20/40/60/80°** and the proposed pane throws it **0.00°
throughout** `[verified-numerically 2026-09-18, §5]`.

And with the eye on the plane *and* the gaze in it, the reflection is the **identity**: viewpoint moved
0.0000 m, direction turned 0.0000° `[verified-numerically 2026-09-18, §6]`. The mirror then hands us a
second render of the player's own forward view, and `present.cpp:283` crops it to magnify — the zoom
was always ours, never the mirror's.

**A deliberate few-centimetre offset is nearly free**, and is the recommended safety margin against a
plane passing exactly through the camera: at 0.02/0.04/0.06 m off-plane the viewpoint moves
0.040/0.080/0.120 m and **the direction stays exact to 0.0000°** `[verified-numerically 2026-09-18, §6]`.

### Two side effects, both good

- **The bore's far point lies in the plane, so it reflects to itself** (0.000000 m at 50 m)
  `[verified-numerically 2026-09-18, §7]` ⇒ **§9g's crop candidates `reflect=0` and `reflect=1` collapse
  to the same number.** Four candidates become two. This is conditional on the pose, not a withdrawal
  of §9g.
- **`off_u` stops moving the viewpoint at all**: `height_lever` goes from −2.000 to +0.000, and
  `mground::pane_move_for_margin`'s existing divide-by-nothing guard fires and returns 0
  `[verified-numerically 2026-09-18, §8]`. The guard was written for an edge case and becomes the
  everyday case. **Nothing blows up**: the reflection is a subtraction, and walking the eye from −0.05 m
  through 0 to +0.05 m produces no NaN and no discontinuity `[verified-numerically 2026-09-18, §8]`.

## 4. ⚠️ Two corrections to expectations that would otherwise be read as failures

- **`IMPROPER` will NOT go away.** A reflection has determinant −1 by definition, so any mirror pose
  reads improper against an unmirrored baseline. What changes is *which axis* flips: the shipped pane
  flips the picture **vertically** (`up → -up`), the proposed pane flips it **horizontally**
  (`right → -right`) `[verified-numerically 2026-09-18, §9]`. The win is that it becomes a single
  **constant** flip, cancellable once by `glass_flip_h`, instead of a vertical flip riding the aim.
  `sg_rebase()` against a horizontally-flipped baseline should then read proper — that is the thing to
  watch, not the raw flag.
- **The muzzle remains unreachable, and now there is arithmetic for it.** Every plane that *does*
  deliver the viewpoint to the muzzle delivers it **exactly** (miss 0.0000 m at 0.4/0.8/1.2 m) **and
  turns the picture a full 180.0°, every time** `[verified-numerically 2026-09-18, §11]`. A reflection
  moves a point only along its normal and turns a direction by twice its angle to that same normal; one
  buys the other. **Geometrically impossible, not untried.**

## 5. What the live `off_u lever` actually tells us — and an open question

`lever = 2·n_y`, and `n` is the rifle's own up axis, so **the lever is a direct readout of the rifle's
attitude and nothing else**: −2.00 = plane horizontal, 0.00 = plane vertical. The tool prints the full
table `[verified-numerically 2026-09-18, §10]`.

⚠️ **The measured −0.38…−0.68 says the plane was already 75–83° from horizontal** — i.e. much closer to
the proposed vertical pose than to a horizontal one. **That does not fit a "ceiling mirror" reading of
the symptom.** Two candidates, both `[hypothesis]`:

1. the rifle model's local Y is not "up" in the intuitive sense, so the plane was already near-vertical
   and the residual junk is gaze-to-plane mismatch (§1) rather than plane placement;
2. the reading was taken with the rifle at an unnatural attitude — §9m's standing warning that on
   unattended VR runs *"the motion controllers are parked side by side on a shelf"*, so every
   controller-derived number is meaningless.

**One live line settles it**, and it is free: read `off_u lever` with the rifle genuinely shouldered.

## 6. ⭐ The prediction, stated BEFORE the launch

Five live harness words, no rebuild, no relaunch: `pitch 90` · `yaw 90` · `propf 0` · `propu 0` · `propr 0`.

1. **The differential test, which depends on no assumption of mine:** sweep `propu` afterwards. Under the
   shipped pose it moved the viewpoint (measured 2026-09-18: `propu -0.2` → −32.98, `propu +0.3` → −32.85).
   Under the proposed pose **the viewpoint must move by less than 0.02 m across the same sweep**, because
   `off_u` now lies in the plane. If it still moves, the pose did not take and nothing else here applies.
2. `ground:` **`off_u lever` → |lever| < 0.1** (from −0.38…−0.68).
3. `ground:` **"the picture is taken from y=" within 0.05 m of `head`**, and staying there as the rifle
   is raised and lowered.
4. `geom:` **still IMPROPER** (see §4) — but `rot` should settle near a constant instead of riding the aim.
5. The wearer's test: hold the rifle off the line of sight and look level. **The picture must stop
   tipping.** Under the shipped pose it tips by twice the mismatch.

**If 1 and 2 pass and 5 fails, the direction law is right and something else is aiming the picture.**
**If 1 fails, ignore everything else in this drop for that run.**

## 7. What this does NOT withdraw

- **§9f is not contradicted — it is the enabling fact.** §9f measured that `via.render.Mirror` looks
  where the *viewing* camera looks, and tagged pane steering `[disproved 2026-09-05]` **as a way to
  decouple the picture from the head**. That disproof is of a specific proposition and stands. The
  proposal here is the opposite goal — make the reflection the *identity*, so following the head is
  exactly what we want. ⚠️ Claim-hygiene note worth keeping: a `[disproved]` tag disproves the
  proposition it was attached to, not the mechanism it was measured on.
- **§9ai's arithmetic stands**; only its completeness is superseded. The 2× lever, the `off_u` reading
  and the "no prop height is clean" conclusion are all correct — for a horizontal plane, and for the
  position half of the problem.
- **§9g is narrowed, not withdrawn**: two of four crop candidates coincide *under this pose only*.
- **§9ac (the body cannot be masked per-pass) is untouched**, and its one untested bet — does the mirror
  honour per-mesh `DrawDefault` — is still the cheapest thing on the board. `bodyhide 2 all` with the
  picture working settles it in one look; it could not be judged on 2026-09-18 only because the picture
  was black, and §9am fixed that later the same day.
- **The `framev` / `framevneg` / `mrollsym` machinery is still needed.** Mirrors always flip.

## 8. Not established

- That the wearer's complaint IS gaze-to-plane mismatch. The law is exact; that it is the dominant term
  in what he is seeing is `[hypothesis]` until §6 runs.
- Whether `via.render.Mirror` refuses to produce when its plane is near edge-on to the viewing camera.
  **Nothing in the component can express it** — it has zero fields and eight methods, none geometric
  `[verified-live 2026-08-25, n=1]` — and we never sample it as a surface, only take its render target.
  The engine *does* gate production on something about the host (`goat_hide` froze the mirror
  `[verified-live 2026-09-13]`, while shrinking to ×0.001 did not), so host visibility looks like the
  real gate, not plane orientation `[inferred-static 2026-09-18]`. And `set_ClippingEnable(false)` —
  already applied automatically since 2026-08-30 — removes the half-space clip that would otherwise make
  a plane through the camera catastrophic. **Untested, and it is the main risk.**
- **The feedback risk.** If the mirror render becomes the player's own view, the scope glass sits near
  the centre of it, and the glass is showing our picture. The mirror renders during the scene pass while
  our blit lands at present time, so any feedback is one frame delayed and attenuated rather than
  instantaneous — but a visible hall-of-mirrors is possible and has never been observed either way
  `[hypothesis]`. Cheap mitigation if it appears: the open-tube material toggle already exists
  (`setMaterialsEnable`, proven on this mesh).

Tool: `staging/re-village-scope-vr/plugin/tools/bore_plane_check.cpp`. Nothing was deployed and the game
was not launched.
