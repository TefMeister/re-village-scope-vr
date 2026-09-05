# 2026-09-05l — The control passes, the ladder tracks, and a target switch can strand the latch (`/lm`, home PC, one flat launch, resumed)

**Lane:** `/lm village scope`, home PC, 21:39 launch (Tefa), driven 21:52–22:22. Tefa's own session
closed by accident at about 22:05 while they were testing; this session picked the same process up
from the log at 22:13 — nothing was lost, because the log is the oracle. Tefa was at the game
throughout (co-op, not automation): they built the first rigs from the panel, took the 21:56
screenshot, and were firing while the last cycle ran. The game is **still running** at write-up.

Evidence: `dev-archive/recon/2026-09-05l-control-passes-ladder-tracks/` — every capture named below,
the filtered log, both driving scripts, and Tefa's screenshot. Plugin unchanged from 2026-09-05k
(150,528 B, deployed 21:34, first run tonight). Source `staging` `1abbb20`.

## 1. The corrected plugin passes its own control — all three readings, in one process

The 2026-09-05k OPEN row stated the pass criterion before the launch. Read against the log:

| reading | what the row demanded | what the log shows |
| --- | --- | --- |
| (a) the HDR upgrade still fires | a cycle logs `latched … fmt=29` AND `UPGRADED to raw-HDR` and shows the world | 21:54:19 — `REPLACED on pending re-arm (1280-wide): 1280x728 fmt=29 flags=0x1` then 4 ms later `UPGRADED to raw-HDR allocation: 1280x728 fmt=26`; the world on the glass (Tefa's 21:56 screenshot; my 22:19 capture, centre mean 150) |
| (b) pending re-arm replaces on the OTHER target | `REPLACED on pending re-arm` + a picture | the same 21:54:19 line — `.` at 21:53:42 (`re-arm PENDING -- current source kept`), then `fn rtex_1280` + `fn p10` on a process whose source had been 1920-wide since boot |
| (c) a non-allocating cycle KEEPS the picture | `mirror RT: using` with no latch line, and the scope does not go cream with a blue reticle | 22:04:09 `.` → 22:04:13 rebuild on 1280, **no latch line**; at 22:19 the scope still showed the world with a **green** square (`reading-c-1280-kept-after-non-allocating-rebuild.png`) |

All three `[verified-live 2026-09-05, n=1 each]`. The boot latch also behaves as designed under the
first-source gate: 21:39:25 latched `1920x1080 fmt=29 flags=0x1` and upgraded to a `1920x1080 fmt=26`
within 2 ms, before any rig existed. That boot pair is what the scope showed from 21:48 (first
MIRROR-sourced frame, `src=…C20`) until the 21:54 replacement.

Zero cream-with-blue in this process. The 21:13 regression is closed.

## 2. The snow-as-sky ladder test — the effect tracks the ladder exactly

Row: "correct at rung 0, white at rungs 8/12; whitening at rung 0 too kills this." Run on the 1280
raw-HDR source at one pose (village, snow bank and tree in the glass, grey sky above the crest).
Seven presses of numpad 9, one capture each, `top` = mean of the upper 420×170 px of the glass:

| press | compositor state | centre mean | top (sky band) |
| --- | --- | --- | --- |
| start | atmo=0 (left there by the 22:05 sweep) | 148.4 | 103.2 |
| 1 | atmo=1 skyThresh=0.5 | 157.8 | 131.8 |
| 2 | 1.5 | 163.8 | 130.6 |
| 3 | 3.0 | 171.2 | 120.4 |
| 4 | 5.0 | 184.0 | 165.6 |
| 5 | 8.0 | 192.1 | **192.1** |
| 6 | 12.0 | 198.7 | **201.2** |
| 7 | atmo=0 | 149.8 | 109.7 |

`[measured 2026-09-05, n=1 sweep, one spot]`. Rung 0 returns to the start values to within 6 units;
the band is near white at 8 and 12; the whole picture brightens monotonically with the threshold.
That is the shape the 2026-09-05 post-mortem predicted: the mirror renders with no atmosphere pass,
the mask reads dark-as-sky, and `skyGain` paints it. **The atmosphere package is the whitening,
and it is OFF-able with no other change** — which is also the state the ledger of 2026-09-04
already chose ("the sky package is retired"). Nothing here points at the white balance (wb stayed
0.0 throughout).

## 3. The sharpness comparison was not made — and why it cannot be made this way

The plan was 1280 (already latched, HDR path) then `.` + `fn destroy_rig` + `fn rtex_1920` +
`fn p10` + `*` at the same pose. The 1920 rebuild logged `mirror RT: using
movie/rtex/movie_1920_1080.rtex` and **no latch line** — the holder was reused, nothing was
allocated, the pending flag stayed pending — so the plugin kept the 1280 buffer. The scope then
showed **Ethan's jacket** (Tefa named it from the chair), centre mean 57.6.

That jacket is a **frozen frame**: rotating the pane by 25° (`dyaw 25`) left the glass identical
down to the folds (`frozen-test-dyaw25-before-after.png`) `[verified-live 2026-09-05, n=1]`. The
reading: the latched `fmt=26` allocation is the engine's pooled HDR intermediate for a
1280-wide mirror; a 1280 rig writes it (reading (c) above, and the 22:22 recovery rebuild on 1280
— again no latch line — brought the live world straight back, centre mean 147.9), a 1920 rig writes
a different one, and the old buffer keeps its last frame: the lowered rifle looking at the body.
`[hypothesis]` — consistent with every line tonight, not yet proved by reading the allocation.

**So "pending replace" has a cost the 2026-09-05k design did not name:** an allocation that
happens while nothing is pending is ignored *and does not recur in that process*. Tefa's first
1920 rig at 21:48 allocated (first use) with nothing pending; from then on 1920 never allocates
again, and the only way to a latched 1920 source in this process was gone before the session
started. The recipe that works is stated in the OPEN row: **press `.` before the FIRST rig on each
target**, in a fresh launch — 1920 first, capture, then `.` + 1280, capture — both first uses
allocate, both replace.

**The scope was left live on the 1280 source, world in the glass, `ads 0` released.**

## 4. What this leaves

- `[FLAT]` control row — **closed, passed.**
- `[FLAT]` snow-as-sky ladder row — **closed**: the diagnosis holds at n=1 spot; the package stays
  OFF (`atmo=0`).
- `[FLAT]` sharpness row — reworded with the recipe; still one launch.
- New `[PD]` row: the plugin should say when a rebuild switched target width without an
  allocation while the latch holds the other width — it already has both numbers — so a stranded
  buffer is a **loud** miss like every other, not a jacket in the glass.
- `[VR]` row unchanged and still the one that matters. This process is flat (OpenXR system creation
  failed at 21:39 with `XR_ERROR_FORM_FACTOR_UNAVAILABLE`, i.e. Virtual Desktop was not connected
  at launch), so VR needs its own cold start.
