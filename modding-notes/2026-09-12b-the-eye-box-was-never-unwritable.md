# The eye-box was never unwritable — it is a float4 and we kept writing it as a float; and crop-follow cannot move the disc (2026-09-12 afternoon, home PC `RTX`, `/pd`)

**The game was not launched and nothing here has been run.** Everything below is read out of
shipped code, our own source, and logs already on disk. One build was made and deployed; it has
not been executed.

Session: `/pd re-village-scope-vr`. Claim taken 13:50, released at the end of the write-up.

---

## 1. The headline: `EyeDistortionRange` is a **float4**, and every write we ever aimed at it used the scalar setter

`ENGINE-DOSSIER.md` §8d closed a row on 2026-09-05 with this, marked ⭐ and read as settled:

> **`EyeDistortionRange` CANNOT BE WRITTEN through `setMaterialFloat`** … Holding `0.5` at frame
> rate for ~1.5 s reads back **`0.100`** on both lens materials … **There is no writer to hunt** —
> the row is closed.

The *reading* was right. The *conclusion* was not, and the thing that disproves it was written into
this repo seven days later by a different session, in a different section, for a different reason.
§9k, 2026-09-12 morning, pulled the rifle's master material out of the pak and listed its full
variable set:

> `ConvexNormal_CenterPos`, **`EyeDistortionRange` (float4, 0.1/0.3)** and `Reticle_*` only.
> `[verified-numerically 2026-09-12]`

`Plugin.cpp` has written that variable through `setMaterialFloat` — the **scalar** setter — since
2026-08-28, and read it back through `getMaterialFloat`. A scalar write into a float4 slot lands
nowhere, and the read hands back the variable's x lane. **`0.100` was never our value being
refused. It is Capcom's authored `x`, reported back to us unchanged, every single time.**
`[inferred-static 2026-09-12]`

### The corroboration that needs no file read

The same plugin, in the same loop, on the same mesh and material and with the same learned ABI
encoding, writes six other scalars and **verifies every one of them**:

| variable | written | reads back |
| --- | --- | --- |
| `ConvexNormal_Intenisty` | 0.000 | 0.000 ✅ |
| `FrontHole_Height` | 0.000 | 0.000 ✅ |
| `FakeSpecular_AddColor` | 0.000 | 0.000 ✅ |
| `FakeSpecular_Height` | 0.000 | 0.000 ✅ |
| `FakeSpecular_RangeLimit` | 0.000 | 0.000 ✅ |
| **`EyeDistortionRange`** | 0.000 / 0.050 / 0.500 | **0.100 every time** ❌ |

`[verified-live 2026-09-05, n=2 materials x 3 launches]`, logs in
`dev-archive/recon/2026-09-05e-flat-control-and-eyebox-ladder/` and four later runs. One variable
out of six failing, under machinery that proves itself on the other five, is a **type** mismatch,
not a fight. And the plugin's float4 path is already known good in the same logs:
`FrontHole_Color_Inner -> (0,0,0,0) reads back (0,0,0,0)`.

### Why this is not a footnote

§8 recorded, from the headset:

> **The lens material simulates an exit pupil.** Off-axis the visible disc **shrinks and slides**
> and the slot-1 picture is shifted and scaled **with view angle**. `[verified-live 2026-09-05, n=2]`

§9n recorded, from the headset, with our image **frozen**:

> *"the scope still moves around in the scope tube when i move my head or the weapon, but the image
> inside the scope is still."* `[verified-live 2026-09-12, n=1 wearer]`

Those are the same sentence written twice, a week apart, and the second one is the ⭐⭐⭐ row.
The mechanism joins up end to end:

1. Our picture is bound into the lens material's **`Reticle_BaseAlphaMap`** slot (`bind_scope_glass`).
2. The shipped lens shader carries an **eye-direction term scaled by `EyeDistortionRange`** —
   noted 2026-09-12 as a side remark: *"the flat lens shader does carry a per-eye term,
   `EyeDistortionRange` with `eye_dir`, i.e. the look-through 'eye box' of the flat scope."*
3. That term perturbs the lens UV with the view angle, and our picture is what is on that UV.
4. We have been trying to switch it off since 2026-08-28 and **not one of those writes reached it.**

⚠️ **What is NOT established.** Which sampler's UV the `eye_dir` term actually perturbs is read from
a note, not from the shader `[reported 2026-09-12]`. So "zeroing it removes the swing" is
`[hypothesis]`, full stop. What this session establishes is only that **the write can now reach the
variable at all** — which is the thing five headset sessions assumed and none of them had.

---

## 2. The row's own "cheapest first step" cannot pass its own test

The ⭐⭐⭐ row orders the work as *"(a) cheapest — turn `cropfollow` ON and judge it against TUBE
ALIGNMENT, not content"*. Read from the shipped shaders, **`crop_follow` cannot move the disc in the
tube, at any setting**:

- In `ps_main`, the lens circle, its soft edge, the reticle and the source-mode tab are all drawn
  from `float2 c = i.uv - 0.5` — the **destination** pixel's own coordinate. Fixed in the render
  target, by construction.
- The only thing `crop_follow` changes is `uvCenter`, and `uvCenter` appears in exactly one place:
  `float2 suv = uvCenter + pr * 2.0 * uvHalf;`, the **source** sample. It chooses *what scene* lands
  under the circle.
- `blit_rt_into_target` then stretches that render target into the engine's lens texture through
  `ps_blit`, at a viewport of `{0, 0, target.Width, target.Height}` — a 1:1 fill with no offset and
  no second mask.

So the disc is nailed to the glass texture, the glass texture is nailed to the glass mesh, and the
mesh is nailed to the rifle. `crop_follow` moves the picture *inside* the hole; it cannot move the
hole. `[inferred-static 2026-09-12]` — read directly from `Plugin.cpp`'s HLSL, not transcribed.

**That is a headset launch saved.** Step (a) would have come back "no change" and been read as one
more negative.

---

## 3. What was built (compile-verified, NOT run)

`plugin/src/Plugin.cpp`, `scripts/re8_scope_m6_mirror_producer.lua`, `scripts/re8_scope_harness.lua`
in `staging/re-village-scope-vr/`.

- **`get_material_float4` / `set_material_float4_verified`** — the float4 twins of the scalar
  helper, with the same contract: a write is "verified" only when the read-back matches, so a
  silent failure can never be logged as a success.
- **`EyeDistortionRange` moved out of the scalar table into its own float4 block** in
  `apply_glass_look`. At every bind it now **reads the authored value as a float4 and logs all four
  lanes** (that alone decides §9k's file read against a live read), remembers it, then writes and
  verifies.
- **`eyedist_hold_tick`** replaces the retired 2026-09-05 eye-box ladder and its 1.5 s hold window.
  The ladder asked "min clamp, re-assert, or late overwrite?" — it had no fourth box for *"you are
  writing a float4 as a float"*, which is the answer. The new tick holds the value at frame rate,
  the way `Reticle_Emissive` has to be held.
- **One live knob, `eyedist`**, through the harness → pane file → plugin, persisted in the settings
  file:

  | `eyedist` | meaning |
  | --- | --- |
  | `0` | all four lanes zero, held every frame — the lens shader's eye-position term **off** |
  | `-1` | the **authored** value restored once and then left alone — the A/B control |
  | `0..4` | any intermediate strength, for a sweep |
  | (absent, or `-9`) | not commanded; the settings-file value stands |

  Default `0`, which is what this plugin has been *trying* to do since 2026-08-28.

**Interaction checked:** `apply_glass_look` and `eyedist_hold_tick` are now the only two writers of
this variable anywhere in the plugin; the first runs once per bind, the second every tick, so the
hold always has the last word. The old scalar ladder that used to write it is gone rather than left
to fight. `eyedist -1` restores **once** on the transition and then writes nothing, so the stock
eye-box during an A/B is genuinely stock and not re-imposed by us at frame rate.

Build: clean, no warnings, `/Brepro` so the hash is reproducible. `[compile-verified 2026-09-12]`
Both Lua files pass `luac -p`. **Nothing has been run.**

---

## 4. The next launch, and what each outcome means

Deployed and ready; this needs the headset, and it is **one wear, two commands**:

```
eyedist 0     <- the lens shader's eye-position term off  (this is also the boot default now)
eyedist -1    <- the authored value back, without a relaunch
```

Judge **TUBE ALIGNMENT** — does the disc of picture sit still in the tube — not sharpness, not
content, not what the picture shows.

| what the wearer sees | what it means |
| --- | --- |
| `eyedist 0` the disc **sits still**, `-1` it slides again | ⭐ **the swing is the lens material's own eye-box, and it is solved.** Ship `eyedist 0`. |
| no difference between `0` and `-1`, and the log says the float4 write **verified** | the variable is reachable and is **not** the cause. The remaining candidate is geometric: our picture is a flat sticker on a glass plane recessed behind the tube rim, so the rim occludes a different part of it from each eye. That needs a per-eye image, i.e. §9n's route (b). |
| the log says the float4 write **still fails** | the variable is not reachable through this API either, and §8d's conclusion survives for a better reason than it had. |

**The log line to read either way** (it prints once per lens material at bind time, before anything
is worn):

```
[re-scope-vr] look: [2] EyeDistortionRange shipped (0.100,0.300,?,?) -> (0.000,...) reads back (0.000,...)
```

`shipped (0.100,0.300, …)` matching §9k's pak read is the independent confirmation that the variable
really is a float4 authored 0.1/0.3. Anything else there, and section 1 of this note is wrong and
should be corrected rather than argued with.

---

## 5. Smaller things found on the way

- **`mdf_dump.py`, used for the §9k pak read, is not in this repo.** It lives in
  `visceral-re2-vr/dev-archive/tools/re-engine/mdf_dump.py` and is committed there, so nothing is at
  risk — but a Village note cites a tool that a Village session will not find. Worth knowing before
  someone re-writes it.
- The deployed `re_scope_vr.dll` before this session hashed **identical** to a fresh build of
  `origin/main`, so `/Brepro` is doing its job and the "is the install current?" check works here.
  `[verified-numerically 2026-09-12]`
