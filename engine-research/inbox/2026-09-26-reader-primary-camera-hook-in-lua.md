# Reader: praydog's PrimaryCamera hook in Lua, component order, and what else differs (2026-09-26)

Source: REFramework `pd-upscaler` — `CameraDuplicator.cpp/.hpp`, `VR.cpp`, `shared/sdk/Renderer.cpp/.hpp`, `src/mods/ScriptRunner.cpp`,
`src/mods/bindings/Sdk.cpp`, fetched 2026-09-26. Static reading only; nothing launched.

## Ranked: what to try if the draw flag alone is not enough

**1. Create the camera at praydog's moment, not at present time.** He builds the clone inside
`on_pre_application_entry("LockScene")` and re-asserts draw/update flags every frame in `LockScene`. `cammake` runs from `re.on_frame`
(present hook, after the frame's scene was built) `[inferred-static 2026-09-26]`. Whether this gates layer execution is `[hypothesis]`.

```lua
-- in re8_scope_cam_probe.lua, after make() is defined; harness word sets st.want_make = {fov, type}
re.on_pre_application_entry("LockScene", function()
    local w = st.want_make
    if w ~= nil then st.want_make = nil; make(w[1], w[2]) end
    if st.cam_go ~= nil then pcall(function() st.cam_go:write_byte(0x13, 1); st.cam_go:write_byte(0x12, 0) end) end
end)
```

**2. Leave the RenderOutput's RenderTarget alone.** praydog never calls `set_RenderTarget`; his clone renders to its default output (id 3)
and VR.cpp copies the result out of the clone layer's `PrepareOutput` state `[inferred-static 2026-09-26]`. A custom target may switch the
output path `[hypothesis]`. Test: a `cammake` variant with the `set_RenderTarget` line removed and `set_RenderOutputID(3)`, then `camlayer`.

**3. Never create `via.render.ExperimentalRayTrace`.** praydog blacklists it; our `camcopy all` made one (log line 75)
`[inferred-static 2026-09-26]`. Effect on our layer `[hypothesis]`. Skip it in `camcopy`.

**4. Component order.** praydog walks `transform:get_child_component()` = MainCamera's own order `[inferred-static 2026-09-26]`. The 09-26 log
shows only the via.render.* order (LDRPostProcess, Fog, ToneMapping, SoftBloom, SSAO, SSR, LightShaft, DOF, SSSSS, FakeLensflare,
MotionBlur, GeometryAO, GodRay, SubsurfaceSettings, VolumetricFog, VolumetricFogControl, Outline, TessellationFactor, RetroFilm,
ExperimentalRayTrace); no "carries 42 components" line exists, and where via.Camera / RenderOutput sit is not logged. Whether order matters:
`[hypothesis]`. Dump it (`camlua`, one line):

```lua
local a = primary():call("get_GameObject"):call("get_Components") for i = 0, a:get_size() - 1 do L(i .. " " .. a:get_element(i):get_type_definition():get_full_name()) end
```

**5. The PrimaryCamera hook — doable in Lua, but it is a takeover guard, not a render switch.** It hides the clone from primary selection
(CameraType Debug during the call). We have no takeover, so expect no pixel change `[inferred-static 2026-09-26]`. Lua post-hooks MUST return
`retval` or the primary camera becomes null (ScriptRunner writes the post result back). Install once; only a script reset removes it.

```lua
if not st.pc_hook then st.pc_hook = true
  sdk.hook(sdk.find_type_definition("via.SceneView"):get_method("get_PrimaryCamera"),
    function(args) local c = st.cam
      if c ~= nil then pcall(function() c:write_dword(0x48, 0xFFFFFFFF); c:write_dword(0x50, 1) end) end   -- priority -1, Debug
      return sdk.PreHookResult.CALL_ORIGINAL end,
    function(retval) local c = st.cam
      if c ~= nil then pcall(function() c:write_dword(0x50, 0) end) end   -- back to Game
      return retval end)
end
```

## Not needed / not a gate
- VR.cpp never drives the clone layer; its layer hooks always return "draw" and only touch layers whose camera's GameObject name starts
  with `MainCamera` etc. **Do not name ours `MainCamera*`** — the VR mod would then rewrite its matrices `[inferred-static 2026-09-26]`.
- Parenting to MainCamera and the ~20-component property copy are for matching looks, not for execution `[inferred-static 2026-09-26]`.
