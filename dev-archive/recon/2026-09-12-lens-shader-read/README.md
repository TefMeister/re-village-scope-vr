# The sniper-scope lens shader, read (2026-09-12, home PC `RTX`, `/pd`, no launch)

What this folder records: the **mechanism** behind the picture sliding in the scope tube,
read out of the shipped pixel shader. Nothing here was run; the game was not launched.

⚠️ **No game content is committed.** The `.mmtr`, the `.mdf2` and the full disassembly stay
off git. What is kept is the cbuffer layout (names and offsets), the authored parameter
values, a twenty-line annotated instruction excerpt, and the formula they decode to — the
same class of interface metadata as an export-name dump.

## How to reproduce it

```
# 1. the in-pak path comes from the community file list that ships with REE.PAK.Tool
grep -i sniperscopelens <REE.PAK.Tool>/Projects/RE8_STM_Release.list
#    -> natives/stm/mastermaterial/master/weapon_sniperscopelens2.mmtr.2102188797

# 2. pull it (and the rifle's material file) out of the archive
python dev-archive/tools/ree_pak_extract.py "<game dir>" <out> \
    natives/stm/mastermaterial/master/weapon_sniperscopelens2.mmtr.2102188797 \
    natives/stm/character/it/it02/070/it02_070_sniperrifle_01.mdf2.19

# 3. the master material is 7 MB and holds 378 ordinary DXBC blobs, reflection intact
python dev-archive/tools/mmtr_shaders.py find   <mmtr> EyeDistortionRange   # -> 9 blobs
python dev-archive/tools/mmtr_shaders.py disasm <mmtr> 46 > blob46.asm      # the lit PS

# 4. the authored values
python <visceral-re2-vr>/dev-archive/tools/re-engine/mdf_dump.py --params <mdf2>
```

⚠️ The version suffix is a 10-digit number (`.2102188797`), not a small one — guessing
`.1`…`.79` misses every time, which is what cost the first attempt. **The file list is the
entry point, and it is already on this machine** inside the REE.PAK.Tool checkout.

## The `UserMaterial` cbuffer (cb6), as the shader declares it

| offset | register | variable |
| ---: | --- | --- |
| 0 | `cb6[0]` | `VAR_TransparentColor` |
| 16 | `cb6[1]` | `VAR_ConvexNormal_CenterPos` |
| 32 | `cb6[2]` | `VAR_Reticle_UV_Scale_Offset` (`.xy` scale, `.zw` offset) |
| 48 | `cb6[3]` | `VAR_FrontHole_PosUV_Rad_Blur` |
| 64 / 80 | `cb6[4]` / `cb6[5]` | `VAR_FrontHole_Color_Inner` / `_Outer` |
| **96** | **`cb6[6]`** | **`VAR_EyeDistortionRange`** |
| 112–124 | `cb6[7]` | `Metallic`, `Roughness`, `Translucency`, `AlphaValue` |
| 128–140 | `cb6[8]` | `ConvexNormal_Intenisty`, `FakeSpecular_AddColor/Height/RangeLimit` |
| 144–156 | `cb6[9]` | `Reticle_VariableScale`, `_Min`, `_Max`, **`Reticle_Depth_Min`** (`.w`) |
| 160–172 | `cb6[10]` | **`Reticle_Depth_Max`** (`.x`), `DepthCurve`, `_StartRange`, `_EndRange` |
| 176–180 | `cb6[11]` | `Reticle_Emissive` (`.x`), `FrontHole_Height` (`.y`) |

`Reticle_BaseAlphaMap` is `t18` — **the slot our picture is bound into**.

## Authored values, from the rifle's own material file

Both lens materials (`it02_070_Sniperrifle_01_Lens_Mat` and `…_Lens2_Mat`) carry:

```
EyeDistortionRange   [0.1, 0.3, 0.0, 0.0]      <- a float4, exactly as 9k read it
Reticle_Depth_Min    [0.388]
Reticle_Depth_Max    [500.0]
Reticle_DepthCurve   [0.5243]
Reticle_Emissive     [0.02]
```

`[verified-numerically 2026-09-12, n=2 materials]`, and an independent second read of
§9k's float4 claim.

## The decoded formula

```
uv  = base_uv * Reticle_UV_Scale + Reticle_UV_Offset
    + (dot(T, d), -dot(B, d)) * k
d   = s * viewDir - (1 - s) * cameraForward
s   = smoothstep(EyeDistortionRange.x, EyeDistortionRange.y, distance(camera, lens pixel))
k   = lerp(Reticle_Depth_Max, Reticle_Depth_Min, pow(saturate(dot(cameraForward, N)),
                                                     Reticle_DepthCurve))
colour = Reticle_BaseAlphaMap.Sample(uv)
```

`T`, `B`, `N` are the lens's own tangent frame, welded to the rifle. Every term in `d`
moves with the head — `s` with how far the eye is from the glass, `viewDir` with where the
eye is (so it differs per eye), `cameraForward` with where the head is pointed. **That is
the picture sliding in the tube, and it is in Capcom's shader, not in ours.**

Annotated excerpt (register names are the disassembler's):

```
;  s = smoothstep(EDR.x, EDR.y, dist)          -- EDR = cb6[6] = EyeDistortionRange
   mul_sat r4.x, r4.x, r5.w                    ; t = saturate((dist - EDR.x) / span)
   mad     r5.w, r4.x, l(-2.0), l(3.0)         ; 3 - 2t
   mul     r4.x, r4.x, r4.x                    ; t*t
   mul     r4.x, r4.x, r5.w                    ; s = t*t*(3-2t)

;  k = lerp(Reticle_Depth_Max, Reticle_Depth_Min, ...)
   add     r2.z, cb6[9].w, -cb6[10].x          ; Depth_Min - Depth_Max
   mad     r0.x, r0.x,  r2.z, cb6[10].x        ; k

;  the offset, and the sample
   mul     r8.zw, r2.xxxy, r0.xxxx             ; (dot(T,d), dot(B,d)) * k
   mad     r0.xy, -r8.zwzz, l(-1.0, 1.0, ...), r0.yzyy      ; uv += offset
   sample_d ... r0.xyxx, t18 ...               ; Reticle_BaseAlphaMap  <-- OUR picture
```

## The two conclusions

1. **`Reticle_Depth_Min` and `Reticle_Depth_Max` are the off switch.** The whole offset is
   multiplied by `k`; set both to 0 and `k` is 0 and the offset is exactly zero at every
   head pose. Neither variable appears anywhere else in the shader: `Reticle_Depth_Min`
   (`cb6[9].w`) on one instruction, `Reticle_Depth_Max` (`cb6[10].x`) on two, all three of
   them inside this term. Counted in the disassembly, not assumed.
   `[verified-numerically 2026-09-12]` They are plain scalars, so the
   plugin's already-verified scalar writer reaches them today.

2. **Zeroing `EyeDistortionRange` is the wrong direction**, and the build made earlier this
   same session got it wrong. The shader guards the degenerate range with
   `if (EDR.y == EDR.x) hi = EDR.x + 1e-4`, so `(0,0,0,0)` makes the smoothstep saturate to
   `s = 1` at any distance — the far end of the sweep, held there permanently. Corrected the
   same session: `eyedist` now defaults to `-1` (leave the authored value alone).
