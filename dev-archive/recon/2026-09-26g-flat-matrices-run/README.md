# 2026-09-26 evening (/lm, flat, Opus) — the clone camera's matrices are IDENTITY: the scene never updates a runtime GameObject

One launch, Claude driving, `re8_scope_cam_clone.lua` (staging `54f587e`). `[verified-live 2026-09-26, n=1]` unless noted.

**The load-bearing finding.** `camcmp`: MainCamera's View/World matrices are real (world row 3 = its position −99.96, −10.30, −29.90;
projection 1.560/2.082, near 0.01, far 4000); **the clone's View AND World matrices are exact identity** — with update OFF and with
update ON (`upd`) — and its projection is the default 90°/aspect 1.77/near 0.1/far 1000. After **unparenting it and setting its world
position by hand**, `transform:get_Position()` reads the new value (−97.998, −10.302, −29.896) but **`transform:get_WorldMatrix()` row 3
and the camera's World/View row 3 stay (0,0,0)**. The scene never computes the world matrix of a GameObject we create at runtime; the
camera derives its view from that, so our camera sits at the world origin with an identity view no matter what we set.

This explains praydog: in VR his `on_camera_get_view_matrix` / `_projection_matrix` hooks hand his clone its matrices every frame, so
the engine never has to compute them (§9cs/§9ct); in flat nothing does.

**The picture, re-read with the plugin's numpad `+` probe** (the 8-bit resolve of our own target, 2560 then 1920): luminance
0.73–1.00, **brightest in the centre and falling off smoothly toward every edge** — a vignette — identical across rungs and walking.
A smooth post-process vignette over a bright field is what a camera at the world origin looking into distant fog would produce
**if its layer runs** `[hypothesis 2026-09-26, the reading of the probe, not verified]`; it fits the 09-25 VR "flat sky-blue" too.
The fmt-26 buffer the plugin UPGRADES to (the cloud-blob "junk") is then an intermediate, not the output.

`matscan`: the camera's position appears nowhere in the 0x1000-byte via.Camera — the matrices live elsewhere (the transform / a
render-side copy). The transform exposes only `get_WorldMatrix`, `get_LocalMatrix`, `copyJointsLocalMatrix` to the TDB.

**Next (no game):** give the clone real matrices — (a) find via.Transform's world-matrix field offset (REFramework's `RETransform`)
and write the rifle's/main camera's world matrix into the clone's transform every LockScene; (b) the reader's Lua hook on the
camera's matrix getters, if the renderer calls them. Then one flat run: if the probe's vignette field turns into the room, the
rifle camera is alive.
