# The one-handed gun pose is the controller's rotation times a FIXED offset, and the offset depends on the runtime

*For the board's `[VR USER]` row "one-handed, the rifle points up by quite a lot" (Tefa, 2026-10-02; not seen since,
kept open because it comes and goes with tracking). That row's own first step is no-game: "read how praydog's
`re8_vr.lua` builds the one-handed weapon pose and whether it adds a fixed pitch". This answers that step from
praydog's published source, read online on 2026-10-26.*

## What the source says

Read through the GitHub viewer/API, `praydog/REFramework` master at `d4611ae` (2026-10-21). `scripts/re8_vr.lua` was
last changed on 2026-03-05 ("Fix racy behavior in hooks causing jitter"), so the March build 76298bd we ship on carries
the same lines.

- **The hand pose is a straight product** (`src/mods/vr/games/RE8VR.cpp`, ~lines 339-352): hand rotation = the game
  camera's original rotation x the controller's tracked rotation x a fixed per-hand rotation offset; hand position =
  the controller position plus a fixed per-hand position offset turned by the same rotation `[inferred-static 2026-10-26]`.
  Nothing in that line filters, smooths or checks tracking quality, so any error in the controller's tracked
  orientation reaches the gun one to one. (Our own dossier already notes that nothing reads OpenXR's
  "position tracked" flag.)
- **The offset is fixed, set once at script start, and is different for OpenXR and OpenVR** (`re8_vr.lua`, top of
  file) `[inferred-static 2026-10-26]`:
  - OpenXR: right hand rotation `(0.186, -2.821, -1.222)`, left `(0.386, 2.821, 1.222)`; position offsets
    `(±0.037, 0.070, 0.018)`.
  - OpenVR: right `(-0.105, -2.37, -1.10)`, left `(0.095, 2.37, 1.10)`; position `(±0.025, 0.045, 0.155)`.
  - The three numbers are turned into a quaternion as Euler angles in radians; praydog's own comment reads
    "pitch yaw roll?", with the question mark. The first component differs by 0.29 rad (about 17°) between the two
    runtimes, but with the large second and third components the visible tilt of the gun is not simply that
    number `[hypothesis]`.
- **It can be changed live, with no file edit:** the script's REFramework menu has "Left/Right Hand Rotation Offset"
  and "Position Offset" sliders, plus a Debug "Adjust Hand Offset" mode that nudges them with the sticks. These values
  are not written to the script's config file (`re7_vr/main_config.json` holds other settings), so they reset on the
  next launch `[inferred-static 2026-10-26]`.

## What it means for the row

- The offset is a **constant**. On our setup (Virtual Desktop's OpenXR every time) it cannot make the rifle point up
  on some launches and not others. A come-and-go tilt therefore points at the controller's tracked orientation
  itself (lighting, the headset's view of the controller), which matches Tefa's own observation `[hypothesis]`.
- Two ways to tell them apart, cheap: (1) if the tilt ever shows again, open the REFramework menu and note the
  sliders' values: unchanged values rule the offset out at once; (2) log the right controller's raw rotation next to
  the gun's, so a jump in one and not the other separates tracking from the offset.
- If Tefa ever wants the one-handed hold a few degrees lower **all the time**, the sliders are the no-code way to try
  it; making it stick would need our script to set the value at start-up.

## Sources

- praydog, REFramework — `scripts/re8_vr.lua` and `src/mods/vr/games/RE8VR.cpp`,
  https://github.com/praydog/REFramework (read online only; nothing copied).
