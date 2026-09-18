# The flat scope is black because the mirror latch grabs a BOOT allocation, and the tell is 1080 vs 1088

Supersedes: modding-notes/2026-09-18i-the-scope-picture-is-black-on-the-home-pc-flat-and-it-is-not-todays-build.md § "lead worth chasing first" (the `[hypothesis]` that the mirror source may only be produced when REFramework VR is active, and that flat may never have worked)

Author: `/lm` static reader (re-village-scope-vr), 2026-09-18, home PC `RTX`. **Nothing was launched to write this.** Every number below is read from logs and screenshots the live session had already captured, or from our own source.

---

## 1. The answer in one line

The picture is black because **`mirror_committed` is latched onto one of the game's own 1920×1080 render targets, grabbed 1–2 ms after `REFramework initialized` during D3D12 (re)init — minutes before any rig exists** — and the hook then closes and never looks at the rig's real `.rtex` allocation at all. It is a mis-latch, not a missing buffer. `[inferred-static 2026-09-18, from n=4 launch logs + source]`

**The discriminator is eight pixels.** The shipped mirror `.rtex` files carry name + 8 rows, so the real mirror source always allocates at a **padded** height:

| Source | Allocation | Is it the mirror? |
| --- | --- | --- |
| `movie_1920_1080.rtex` | **1920×1088** | yes |
| `movie_1280_720.rtex` | **1280×728** | yes |
| authored 2560 | **2560×1448** | yes |
| the desktop backbuffer / engine targets at 1080p | **1920×1080** | **no** |

`scripts/re8scope/rig.lua:125-127` says this in our own words: *"the shipped files carry name + 8 rows (1920x1088, 1280x728 — so the 'padded' heights the latch sees were never runtime rounding)"*. `[inferred-static 2026-09-16, pre-existing]`

Counted across every archived log in `dev-archive/` plus today's five: **15 latches at 1920×1088, 5 at 1280×728, 1 at 2560×1448 — and a separate anomalous class at exactly 1920×1080.** `[measured 2026-09-18, n=46 latch lines]`

**So: a `MIRROR SOURCE latched: 1920x1080` line means the latch is on the wrong resource. Grep that one number.**

## 2. The evidence, measured

Today, flat, five launches, four of which reached the latch. In **every one** the latch fires 1–2 ms after `REFramework initialized`, inside the D3D12 (re)initialisation block, while REFramework is "Creating render targets..." and the TemporalUpscaler is about to bring DLSS up at "Upscaled texture size: 1920x1080":

```
[22:10:46.019] Attempting to initialize DirectX 12
[22:10:46.019] [D3D12] Creating render targets...
[22:10:46.019] [D3D12] Back buffer format is 28
[22:10:46.019] REFramework initialized
[22:10:46.021] MIRROR SOURCE latched: 1920x1080 fmt=29 flags=0x1 -> 0000016F1A398040
[22:10:46.022] MIRROR SOURCE UPGRADED to raw-HDR allocation: 1920x1080 fmt=26 -> 000001733BE5FE10
[22:10:46.051] [TemporalUpscaler] Initializing upscale features...
```

The rig was not built until **22:14:46** — four minutes later. Same shape at 22:24:23, 22:28:46 and 22:33:02. `[measured 2026-09-18, n=4 launches]`

**Contrast, same machine, the night before, in the headset** (`re2_framework_log-2026-09-18_22-10-15.txt` holds the 2026-09-17 session):

```
[2026-09-17 23:30:38.447] [VR] OpenXR system Name: Meta Quest 3
[2026-09-17 23:31:07.817] MIRROR SOURCE latched: 1920x1088 fmt=29 flags=0x1
[2026-09-17 23:31:07.824] MIRROR SOURCE UPGRADED to raw-HDR allocation: 1920x1088 fmt=26
```

**1088, and 30 seconds after init — i.e. at rig time, not boot time.** `[measured 2026-09-18, n=1]`

## 3. Why the hook never recovers

Four separate mechanisms combine, and each one alone is survivable:

1. **`looks_like_mirror_target()` accepts 1080.** `d3d12_hooks.cpp:238` — `if (d->Width == 1920) return d->Height >= 1050 && d->Height <= 1100;`. The window was widened to catch the padded 1088; it also catches the unpadded 1080. `[inferred-static 2026-09-18]`
2. **The first-source test passes.** `first_ok` wants fmt=29 (`R8G8B8A8_UNORM_SRGB`), flags with no UAV. A backbuffer-sized SRGB resolve created at device reset satisfies that exactly. The 2026-09-05 format/flags fix closed the fmt-26-flags-0x5 hole; it does not separate 1080 from 1088. `[inferred-static 2026-09-18]`
3. **The mirror latch is armed from process start.** Unlike the scope-target latch, which is gated on `armed`, the mirror branch at `d3d12_hooks.cpp:345` fires on the first match whenever `!mirror_latched`. There is no "wait until the Lua has rigged" gate, so a boot allocation always wins the race. `[inferred-static 2026-09-18]`
4. **Then the hook goes blind.** `d3d12_hooks.cpp:300` early-returns on every later allocation once both latches are closed and `mirror_is_hdr` is set. Today both were true by 22:13:49; the rig's real 1920×1088 allocation at 22:14:46 **was never even examined**. `[inferred-static 2026-09-18]`

And that is why the documented recovery failed. `numpad .` sets `mirror_rearm_pending`, which re-opens the hook — but by then the 1920 `.rtex` exists for that path, and `sdk.create_resource` returns the engine's **cached** resource, so no `CreateCommittedResource` ever fires again. `rerig` re-uses the same cached path. The re-arm can never be satisfied in that process, which is exactly what the live session saw: *"the re-arm went PENDING, no new `MIRROR SOURCE latched` line ever arrived"*. `rebuild_gate.h`'s own header already describes this caching behaviour for the save-reload case. `[inferred-static 2026-09-18]`

## 4. Why it worked before, and what actually regressed

**It is not "flat has never worked".** Flat has worked repeatedly and is screenshot-proven — 2026-08-26 (the Duke through the scope), 2026-08-27, 2026-09-04 (aspect, white balance, GT curve and the zeroing, all judged by eye on the flat picture, 33 minutes before the headset went on), 2026-09-05l (`XR_ERROR_FORM_FACTOR_UNAVAILABLE` in the same note as "the world on the glass", centre mean 150), 2026-09-06b ("ONE FLAT LAUNCH … headset charging … Live world"), and **2026-09-17, one day before this failure, on this machine, flat: "The picture on the glass looked the same in both captures."** `[verified-live, various dates; re-read 2026-09-18]`

**The boot mis-latch is also not new** — 1920×1080 boot latches appear in the 2026-09-05 and 2026-09-06 logs. What is new is that they are now *unrecoverable*:

- Historically the rig preferred, or fell back to, the **1280**-wide target. Its allocation is **1280×728**, a width no boot allocation matches, so the rig's own `.rtex` creation was a fresh, unambiguous allocation the re-arm could catch — the archives hold `REPLACED 1280x728` lines doing precisely that.
- `rig.lua:122-124` now lists `movie_1920_1080.rtex` **first**, so the default rig is 1920-wide. That width **collides exactly** with the flat desktop's own 1920×1080 buffers, so the boot latch already looks correct, the re-arm has nothing new to catch, and the width-based rebuild check cannot tell them apart. `[inferred-static 2026-09-18]`

**Why VR is immune:** in VR the backbuffer is 2688×2880 and REFramework's targets are VR-sized, so nothing allocated at boot lands in the 1920×1050–1100 window. The first match of the process is the rig's genuine 1920×1088 `.rtex`. `[inferred-static 2026-09-18, supported by the 2026-09-17 VR log]`

⚠️ **This predicts a VR failure too.** Nothing here is about VR as such — it is about whether the game's own targets collide with the rigged width. A VR configuration whose per-eye or mirror-window targets happen to allocate at 1920×1050–1100 would strand the latch the same way. The immunity is a coincidence of resolution, not a property of VR. `[hypothesis]`

## 5. Falsifiable predictions, cheapest first

1. **`fn rtex_1280` before the first `fn p10`, then `bringup`.** Predict: `MIRROR SOURCE REPLACED … 1280x728` (or a fresh latch at that size) and **a live picture in flat**. This is the whole claim in one launch, and it needs no code change. If the picture comes back, §4 is confirmed.
2. **Run the game windowed at 1280×720.** Predict: the boot allocations become 1280-wide and now collide with the *1280* branch instead — so this should make things **worse**, not better, and the 1920 rig should then work. A clean double-dissociation if both hold.
3. **The log tell.** In any future session, `MIRROR SOURCE latched: 1920x1080` (or any unpadded height) = mis-latch. `1088` / `728` / `1448` = the real thing.

## 6. What this withdraws

- The `[hypothesis]` in `2026-09-18i` that the mirror source may require REFramework VR to be active is **`[disproved 2026-09-18]`**: the buffer is produced in flat (it is what the rig creates), and flat pictures are screenshot-proven on at least six dates including the day before.
- Any move to re-gate board rows from FLAT to VR on that basis should be reverted. The flat rows (C2 sharpness, the `framev 2` / `framevneg` up-or-down judgement) are correctly gated; they were blocked by a mis-latch, not by a missing capability.

## 7. Two side findings from the same read

**(a) `holddiag` cannot report the failure it was built for, and the flicker measure has never measured anything.** Armed at 22:16:36 (`hold_diag -> 120` echoed once), then 66,600 frames ran — 37 `hold: summary` lines — and **not one `holddiag:` line, and not one decrement** (a decrement would have re-armed the pane check and logged a second `hold_diag ->`). `[measured 2026-09-18, n=1 session]`

The `hold:` summary sits *downstream* of the diag print inside the same `if (g.rt_prev_valid)` block, so `rt_prev_valid` is true and the diff path is running. The only gate between them is `present.cpp:666` — `if (SUCCEEDED(g.diff_rb->Map(0, &rr, &p)) && p != nullptr)`. **That Map is failing**, `d` therefore keeps its initialiser `0.0f`, and `holdm::decide` at line 695 runs on a zero it was never given. `[inferred-static 2026-09-18]`

That is a better explanation of the 2026-09-17 "exactly zero across 23,400 VR frames" than "the shader computed zero", and it means **`avg=0.0000` is not evidence that the picture is constant** — the number was never computed. The design flaw is that holddiag's print is nested *inside* the very `Map()` it exists to test, so its four verdicts can never include "the readback could not be mapped". A fifth branch, and a log line on Map failure, are needed before holddiag can settle anything.

⚠️ One concrete suspect, unverified: the read range is `{0, RowPitch * kDiffH}`. For a 16×12 R32_FLOAT with a 256-byte aligned row pitch that is 3072 bytes, while `GetCopyableFootprints` sizes the buffer at 2880 — a read range past the end of the resource. `[hypothesis]`

**(b) The `crop-follow … DERIVATION error` warning is independent of the black picture.** It fired four times on **2026-09-17 in VR while the picture was working**, at 3.0, 4.6, 4.3 and 4.2 degrees. Today's single 7.3-degree firing is the same pre-existing discrepancy, larger. It is a real open defect and should keep its own row, but it is not a lead on the blackness. `[measured 2026-09-18, n=5 firings across 2 sessions]`

---

**Confidence summary.** The observations in §2, §4 and §7 are `[measured 2026-09-18]` from logs and archived logs. The causal chain in §1 and §3 is `[inferred-static 2026-09-18]` — read off the source against those logs, **not run**. §5.1 is the one-launch test that would promote it to `[verified-live]`, and it needs no code change. Nothing in this file has been tested in the game.
