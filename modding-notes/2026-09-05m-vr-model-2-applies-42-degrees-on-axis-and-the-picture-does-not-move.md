# 2026-09-05m — VR: model 2 applies 42° on axis and the picture does not move (`/lm`, home PC, Quest 3, one VR launch)

**Lane:** `/lm village scope`, home PC, 22:31 launch by Tefa with Virtual Desktop connected, driven
22:34–22:42, Tefa in the headset reporting by voice-to-text and one headset screenshot. Steering
turned OFF at 22:42 and the game left running with a clean on-axis scope. Last test of the night
(rest window 23:00).

Evidence: `dev-archive/recon/2026-09-05m-vr-model2-steering/` — Tefa's headset screenshot
(22:37:33, steering on, k=+0.5, scope held off axis), filtered log, full log. Plugin unchanged
(150,528 B); producer + harness unchanged.

## What was run and what came back

| step | log | Tefa |
| --- | --- | --- |
| launch with VD connected | `OpenXR system Name: Meta Quest 3`, session + space created — VR for the process lifetime `[verified-live, n=1]` | — |
| cold order `.` → `fn p10` → `fn drive_on` → `*` | re-arm PENDING (latched=0 — **no boot latch in the VR process**), then `latched (1280-wide): 1920x1088 fmt=29 flags=0x1` and `UPGRADED to raw-HDR 1920x1088 fmt=26` on the first rig, glass bound 2 slots. Same plugin behaviour as flat `[verified-live 2026-09-05, n=2 processes]` | — |
| **control: steer OFF, on axis** | — | *"yes, same as it was when I last saw the game in VR"* — right way round, right way up, shots-land pose carries `[verified-live 2026-09-05, n=2 VR launches]` |
| `model 2` (corr), `steerk 0.5`, `steer 1` | while aiming (LOCK, 22:39:30 →): **`arc=84–85 deg -> applied 42 deg`, constant** — in flat ADS the same read was `arc=0.7 deg` | *"still the same as far as I can tell by eye"* on axis. Moving head OR weapon moves the image out of view; weapon forward/back sends the picture "inside the pipe"; **head left-right moves the picture inside the scope left-right** |
| `steerk -0.5` | `arc=84.9 deg -> applied -42.4 deg`, constant | headset screenshot: off-axis, the glass shows **Ethan's jacket, zip and button**, the eye-box hole a crescent; *"I can still see Ethan's clothing and other bits"* |

## Three findings, stated carefully

1. **Model 2 is not the identity on axis in VR.** The model was built on the flat control's
   `arc=0.7°`; in the headset the anchor→mirror ray sits **84–85° off the bore while aiming on
   axis**, so "the correction from the baked pose" applies a constant 42° `[measured 2026-09-05,
   n=1 VR run, ~70 samples]`. The premise the row rested on — the arc is near zero on axis — is
   false in VR, and the reason is static: the lens anchor is built as *Body joint + mount offset*,
   and in VR the mirror pane's baked pose (fwd 1.0, up −0.2, right −0.715 from the rig) is not on
   the bore from that anchor. Which of the two (anchor or pane pose) is the VR-specific part is
   `[hypothesis]` and readable from the producer with the game closed.
2. **A constant 42° applied rotation did not visibly change the on-axis picture.** That is not
   what a 42° rotation of a mirror does. Either the applied rotation is not reaching the pane, or
   it rotates about the pane's own normal-adjacent axis where the reflected view barely changes
   `[hypothesis]`. Read the producer's `steer` apply path before the next VR run — this is the
   cheaper question and it decides whether finding 1 matters yet.
3. **Late answer to question 3 (Tefa, 22:45): at k=-0.5 the picture inside the scope "leans with me" - it moves in the SAME direction as the head lean** `[reported 2026-09-05, n=1]`. The +0.5 direction was described only as "moves left-right", so the two signs are not yet compared, and finding 2 still says the applied rotation may not be what moves it.
3b. **Before that answer, the sign question stood as not answered.** With k=+0.5 Tefa saw the picture follow head lean
   left-right (parallax exists); with −0.5 the report was the jacket, not a direction. Given
   finding 2, a sign judgement would not have meant much tonight anyway.

Two known problems reproduced unchanged in VR `[verified-live 2026-09-05, n=2 VR launches]`: the
**eye-box** (image leaves the glass on small head or weapon moves; fore-aft puts it "inside the
pipe"; the crescent in the screenshot) and the **jacket crop** (off axis the mirror sees the body).

## Left running

Steering OFF (`steer 0`), scope on axis correct, model setting still `corr` in the harness state
(harmless while `steer=false`; a fresh launch resets it). Tefa can play.
