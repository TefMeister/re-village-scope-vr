# The lens shader says exactly what slides the picture, and which two numbers stop it (2026-09-12 late afternoon, home PC `RTX`, `/pd`)

**The game was not launched and nothing here has been run.** The shader was read off disk.
One build was made, deployed and hash-stamped; it has not been executed.

Session: `/pd re-village-scope-vr`, second pass of the day. Claim taken 14:25.

Evidence, method and the reproduction recipe: `dev-archive/recon/2026-09-12-lens-shader-read/`.

---

## 1. ⚠️ First, a correction to this morning's build

The earlier pass today (`2026-09-12b`) found that `EyeDistortionRange` is a float4 that the
plugin had always written as a scalar, built a way to reach it, and shipped **`eyedist 0`
as the default** on the reading that zero meant "effect off".

**Zero does not mean off. It means maximum.** The shader guards a degenerate range:

```
if (EyeDistortionRange.y == EyeDistortionRange.x) hi = EyeDistortionRange.x + 1e-4
s = smoothstep(EyeDistortionRange.x, hi, distance(camera, lens pixel))
```

With all four lanes zero, `hi` becomes `1e-4`, so `s` saturates to **1 at any real
distance** — the far end of the sweep, pinned there permanently, which is the *largest*
offset the term can produce. Stock (0.1, 0.3) at least varies.

Fixed in the same session: **`eyedist` now defaults to `-1`** (leave the authored value
alone) and is kept only for sweeps. Nothing was ever run with the wrong default, because the
morning's build was never launched — but it was deployed and it was on the board as the
thing to wear next, which is exactly how a wrong default gets tested for real.

The morning's *other* two findings stand unchanged: the variable genuinely is a float4 that
had never been reached, and `crop_follow` genuinely cannot move the disc.

---

## 2. What the shader actually does

`weapon_sniperscopelens2.mmtr` came out of the pak; it is 7 MB and holds **378 ordinary
DXBC blobs with their reflection chunks intact**, nine of which mention this material's
variables. The main lit pixel shader disassembles cleanly. `[verified-numerically 2026-09-12]`

```
uv  = base_uv * Reticle_UV_Scale + Reticle_UV_Offset
    + (dot(T, d), -dot(B, d)) * k
d   = s * viewDir - (1 - s) * cameraForward
s   = smoothstep(EyeDistortionRange.x, EyeDistortionRange.y, distance(camera, lens pixel))
k   = lerp(Reticle_Depth_Max, Reticle_Depth_Min,
           pow(saturate(dot(cameraForward, N)), Reticle_DepthCurve))

colour = Reticle_BaseAlphaMap.Sample(uv)
```

`T`, `B`, `N` are the lens's own tangent frame, welded to the rifle. `Reticle_BaseAlphaMap`
is register `t18` — **the texture slot our picture is bound into.**

Every term in `d` moves with the head: `s` with how far the eye is from the glass,
`viewDir` with **where** the eye is — so it differs between the two eyes — and
`cameraForward` with where the head is pointed.

⇒ **The shipped lens shader offsets the sampling of our picture with the head. That is the
disc sliding in the tube.** It was never our compositor, and §9n's frozen-image test was
reading a real effect in Capcom's code. `[verified-numerically 2026-09-12]` for the shader
maths; that this is *the* cause of the wearer's complaint is still `[hypothesis]` until it
is worn, because nothing has been run.

And the offset is not subtle. The authored values are `Reticle_Depth_Min = 0.388`,
`Reticle_Depth_Max = 500.0`. Looking straight into the lens, `dot(cameraForward, N) ≈ 1`, so
`k ≈ 0.388` — a UV displacement of up to about **four tenths of the whole texture**.

---

## 3. The off switch, and why it works today when the float4 one did not

The entire offset is **multiplied** by `k`. Set `Reticle_Depth_Min` **and**
`Reticle_Depth_Max` to zero and `k` is zero, so the offset is exactly zero at every head
pose, for both eyes, regardless of what `EyeDistortionRange` holds.

Two properties make this the right lever rather than a lucky one:

- **Neither variable does anything else in this shader.** Searching the whole disassembly for
  their cbuffer registers finds `Reticle_Depth_Min` (`cb6[9].w`) on **one** instruction and
  `Reticle_Depth_Max` (`cb6[10].x`) on **two** — all three of them inside this term, and nothing
  else anywhere. Counted, not assumed. `[verified-numerically 2026-09-12]`
- **Both are plain scalar floats**, so the plugin's existing verified scalar writer already
  reaches them — the same writer that verifiably lands `ConvexNormal_Intenisty`,
  `FrontHole_Height` and the three `FakeSpecular_*`. This is precisely what
  `EyeDistortionRange` could not do, and why this route is available today.

The same excerpt shows `FrontHole_Height` (`cb6[11].y`) multiplying the *same* 2D offset for
the painted tube-hole. We already zero that one successfully — so one of the two consumers of
this offset has been switched off since August, and the one that carries our picture has not.

---

## 4. What was built (compile-verified, deployed, NOT run)

- **`retdepth`** — a live knob writing both `Reticle_Depth_Min` and `Reticle_Depth_Max`:
  `0` = the offset dead (the new default), `-1` = the authored `0.388` / `500.0` put back and
  left alone, absent or `-9` = not commanded. Harness → pane file → plugin, persisted in the
  settings file, exactly like `eyedist`.
- **`ret_depth_hold_tick`** — holds the pair at frame rate. The `Reticle_*` family is
  re-asserted by the game every frame; that is settled for `Reticle_Emissive` (2026-08-30),
  and these two are in the same family, so a bind-time write alone would be a coin flip.
- **The bind-time block logs the authored value before overwriting it**, per material, so the
  next launch reports `0.388` / `500.0` back as a live check on the file read.
- **`eyedist` default changed `0` → `-1`** (section 1).
- **`dev-archive/tools/mmtr_shaders.py`** — carves the DXBC blobs out of an `.mmtr`, lists
  their reflection names, finds the ones mentioning a variable, and disassembles one through
  `D3DDisassemble` via ctypes, so nothing has to be built. Generic to RE Engine; this is the
  first time this project has opened a master material.

Build clean, no warnings, `/Brepro`. `[compile-verified 2026-09-12]` Both Lua files pass
`luac -p`, and both `string.format` calls were run against dummy arguments to check their
arity, because a short argument list would only have failed at runtime inside the publish
path. **Nothing has been run in the game.**

**Interaction check:** `apply_glass_look` (once per bind) and `ret_depth_hold_tick` (every
tick) are the only writers of this pair anywhere in the plugin, so the hold has the last
word. `retdepth -1` restores **once** on the transition and then writes nothing, so an A/B
against stock is genuinely stock. The shipped-value capture happens on the first material
only and is latched, so a re-bind after we have already zeroed the pair cannot record `0` as
"authored".

---

## 5. The one wear, and what each outcome means

```
retdepth 0      <- the shader's eye-position offset dead   (this is the boot default now)
retdepth -1     <- authored 0.388 / 500.0 back, no restart
```

Judge **TUBE ALIGNMENT** only: does the disc of picture sit still in the tube as the head and
the rifle move? Not sharpness, not content, not what the picture shows.

| what the wearer sees | what it means |
| --- | --- |
| still at `0`, sliding at `-1` | ⭐ **solved.** Ship `retdepth 0`. |
| no difference, and the log shows both writes verifying | the shader term is off and something *else* moves the disc. The remaining candidate is plain geometry — a flat picture on a glass plane recessed behind the tube rim, which needs a per-eye image (§9n route b). |
| the log shows the writes **not** verifying | these two are re-asserted harder than `Reticle_Emissive`; the hold needs to move earlier in the frame. |

Log lines to read, both printed at bind time before anything is worn:

```
look: [2] Reticle_Depth_Min        authored 0.388 -> 0.000 reads back 0.000
look: [2] Reticle_Depth_Max        authored 500.000 -> 0.000 reads back 0.000
look: [2] EyeDistortionRange shipped (0.100,0.300,0.000,0.000) -> ...
```

`authored 0.388 / 500.000` confirms the material file read live; the `shipped` tuple confirms
§9k's.

---

## 6. What is NOT established

- **That this is the wearer's complaint.** The shader maths is read from the shipped
  bytecode; the *link* to "the scope moves around in the scope tube" is an inference, and it
  stays `[hypothesis]` until someone wears it. It is a strong one — the offset is up to ~0.4
  of the texture, it moves with the head, and it differs per eye — but it has not been run.
- **Which of the nine matching shader blobs the game runs for this material.** Blobs 46 and
  47 (the fully lit variants) carry the identical term and were both checked; the smaller
  variants were not disassembled. If the lens draws through one of those instead, the
  cbuffer layout is the same but the term's presence was not verified there.
- **Whether zeroing `k` costs anything visually.** `k` scales only this offset, so the
  expected cost is none — but "expected" is not "seen".
