# 2026-09-25 — the lights follow the scope's aim, and the render layer order says why it could (home PC, VR, Tefa in the headset; Opus then Fable)

## What Tefa saw
- Lights switch on and off with head direction, only while the scope exists; worse over a week. Plain DLSS install: fine `[reported 2026-09-25]`.
- Afternoon bisect (one switch at a time, Tefa judging): glass unbound, rig parked, exemption unticked, goat host, pane tilt — all still bad;
  rig destroyed — ok `[reported 2026-09-25, n=1 session]`.
- 15:30, the real pattern: *"areas that the scope is pointing at light up, when i turn the rifle away the lighting in world just goes dark where
  i'm looking at … i pointed the rifle backwards and nearly every light source stopped producing light"*; the head matters less than the rifle
  `[reported 2026-09-25]`. Screenshots 14:11–14:12: the Duke's key light goes out, the candles stay.

## What was tried and failed
- Layer `ClippingEnable` true — still bad. Layer `LightWeightMode` / `Independent` — no setter, do not stick.
- Mirror `LightWeightMode` true, LIVE — crashed within 30 ms `[verified-live 2026-09-25, n=1]` (dump on D:).
- Mirror `LightWeightMode` true AT CREATION (pre-hook of `set_RenderTarget`, before any draw) — also crashed at the rig build
  `[verified-live 2026-09-25, n=1]` (`crash-mirror-lightweight-at-creation-2026-09-25-1603.dmp`). The window-is-safe idea is `[disproved 2026-09-25]`.
- In-game Shadow Cache off — still bad (Tefa: it was meant to be off with DLSS anyway).

## What was read
The `layerorder` word (rifle out, 16:05) printed the Output layer's children in order `[verified-live 2026-09-25, n=1]`:
OutputCommon · Scene view=2 cam A **mirror=ours** · Scene view=0 cam A (main eye) · Scene view=3 cam B **mirror=ours** · Scene view=1 cam B (cloned eye)
· OutputOverlay. So the engine gives one via.render.Mirror a Scene layer PER EYE CAMERA, and each mirror layer sits BEFORE its eye's layer.
`via.render.layer.Output.setLayerIndex(UInt32, UInt32)` exists; native layers carry no TDB fields.

## The working idea `[hypothesis]`
Only the shadow-casting lights go out (the key light, not the candles). If the frame's shadow-light budget is handed out in layer order,
the two scope views take it first and the eyes get the leftovers — lit as seen from the scope. The lever: move the two mirror layers behind
the eyes with `layermove` (built, installed, one restart to load, NOT RUN). The two numbers' meaning is unknown; the read-back says.

## Not established
- Whether it is a shadow budget, a shared light list, or something else — nothing in the engine was read, only the symptom and the order.
- Whether a mirror drawn after its eye still feeds the glass (one frame late) or breaks.
- Also today, unrelated: the zero is off again (three shots low-right by the same amount, 15:31) — noted on the board, not looked at.
