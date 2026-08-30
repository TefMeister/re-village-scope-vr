# The camera was never in the pipeline

**2026-08-25, evening, home PC. User-driven throughout (no agents, no automated input).**

## One-line result

A `via.Camera` + `via.render.RenderOutput` on our own GameObject, pointed at our own
render target holder, contributes **nothing** to the scope glass. Proven by removing it:
with **no camera in existence at all**, the glass shows the identical image.

## How the evening went wrong, in order

M8 was built to answer one question: does our camera produce ANY pixels into our render
target on a non-`Game` CameraType? Never once observed; M7 died of a NaN'd rifle before it
could report.

M8 ran clean. Rig tracked the rifle exactly (`rig=(-277.04,-98.78,238.38)
rifle=(-277.04,-98.78,238.38)`), rifle stayed visible, zero exceptions, and **an image
appeared on the scope glass that changed as the player looked around**.

That was called a success. It was not one. What was actually observed is *pixels appeared
where we wanted them and responded to the scene* — which is not the same claim as *our
camera drew them*, and the difference is the entire finding.

Three rounds of tuning followed, all aimed at the image:

| round | changed | result |
|---|---|---|
| M9  | FOV re-asserted every frame, live read-back | value holds exactly (120.0, 2.5, no drift) — image unchanged |
| M10 | `VerticalEnable` true, `AspectRatio` 1.7582, `CameraType` 6 (Preview), `DebugCamera` false | every property confirmed stuck by heartbeat — image unchanged |
| M10b | FOV swept 1.48 → 113 | image unchanged |

A camera ignoring its FOV, aspect, type *and* near/far is not a camera with one
disconnected knob. That should have been the signal to stop tuning and test provenance —
it took three rounds to ask.

## The control

`control_no_camera()`: create the holder, bind the scope glass to it, create **no
GameObject, no RenderOutput, no via.Camera**. Nothing in the script can write a pixel into
that holder.

```
CONTROL: holder created. No rig, no RenderOutput, no camera exist.
  BOUND material[2] (it02_070_Sniperrifle_01_Lens_Mat) slot 1 -> (true)
  BOUND material[3] (it02_070_Sniperrifle_01_Lens2_Mat) slot 1 -> (true)
CONTROL: glass bound. NOTHING in this script can write into that holder.
cam_type = 1 Debug
rig GameObject created via via.GameObject.create(System.String)
rig RenderOutput: ID=2 ...
rig camera CameraType -> 1
```

Same holder, same glass bind, camera absent then present, **fresh game process**. User
report on both: *"exactly the same as before"*.

## What the image actually looks like

Sky at the top, a hard horizon across the middle, flat grey below, **no world geometry** —
photographed while looking directly at a lit castle through fog, with no castle in it.
Earlier, in the factory: a faint X-shaped structure at an odd angle. Low detail, no
tonemapping, content shifts with player location, completely indifferent to our camera.

That is the signature of an **environment / reflection capture**, and it raises the
question that comes next: is our texture reaching the glass *at all*, or has the stock lens
material been showing its own reflection all evening?

## What still stands, and what does not

**Stands** — the glass display mechanism itself. That was proven separately and by a
different mechanism on 2026-08-24: the native plugin's latched RT on the lens slot, with
**F9 changing the reticle shape on the glass in real gameplay**. Our content, our change,
visible. That evidence is untouched by tonight.

**Does not stand** — "a second camera renders into our render target". Never demonstrated.
Tonight it was disproven for the `RenderOutput` + `via.Camera` + rig path specifically.

**Open** — whether `sdk.create_resource("via.render.RenderTargetTextureResource",
"movie/rtex/movie_1280_720.rtex")` yields a holder anyone can write to, or whether binding
it to a material slot changes what that slot displays at all.

## The lesson, stated plainly

This project has now made the same mistake twice in eight days.

- **2026-08-24, dev PC:** the D3D12 hook stored "the last Texture2D allocated while armed",
  never identified it, and the scope image went into a real game texture. Lesson recorded
  then: *never write into a GPU resource you have not positively identified.*
- **2026-08-25, home PC:** an image appeared on the glass and was attributed to our camera
  without ever testing whether our camera was connected to it. Same error, read backwards:
  *never attribute pixels to a source you have not positively identified.*

The control that settled it took one button and under a minute. It was available before any
of the tuning and would have saved all three rounds. **Test provenance before you test
parameters** — adjusting something you have not proven is in the loop can only produce
ambiguous results, and it produced four hours of them.

## Instrumentation added tonight (all still in the script, all read-only or reversible)

- `activate_object()` / `report_view_state()` (button F) — GameObject update/draw flags,
  component enabled state, live RT, output ID, camera type, FOV, rig position.
- `dump_live_getters()` (button G) — every zero-arg getter on our camera and RenderOutput
  **and on the game's own MainCamera**, side by side. This is what found the three property
  mismatches, and it remains the most productive tool built tonight.
- `heartbeat()` — throttled ~4s: rig vs rifle position, update/draw, RT, FOV, DebugCamera,
  AspectRatio, VerticalEnable. Proved the FOV was not being overwritten.
- `teleport_rig()`, `apply_output_id()`, `cut_rt()`, `control_no_camera()` — provenance
  tests, cheapest first.

## Rig safety note (worth keeping)

The M8 premise held perfectly: a camera on its own GameObject parented to nothing, driven
by a *copy* of the rifle's pose, **never NaN'd the rifle**. The 2026-08-24 corruption was
caused by joining the hand skeleton's hierarchy, and flying in formation genuinely avoids
it. The rifle stayed visible through every run tonight. That part of M8 is sound and should
be kept in whatever replaces the camera approach.
