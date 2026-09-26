# Reader: can a Lua hook give our clone camera its matrices? (rung 6 of 2026-09-26g NEXT-RUN)

Author: static reader beside the live session, 2026-09-26. No launch, no game files touched. Sources: REFramework `pd-upscaler`
`src/mods/Hooks.cpp` l.634-707 + l.1040-1090, `src/mods/VR.cpp` l.255-345, 617-740, 4356; `src/HookManager.cpp/.hpp`;
`src/mods/ScriptRunner.cpp` l.654-760; `src/mods/bindings/Sdk.cpp` l.365-410, 943-960, 1373-1400, 1653-1680; re8.exe string pool.

## 1. How REFramework hooks the matrices

- Installed by `Hooks.cpp` (always, flat too), not by VR.cpp: `sdk::find_native_method("via.Camera","get_ViewMatrix")` gives the
  reflection WRAPPER; it pattern-scans that wrapper for `49 8B C8 E8` (`mov rcx,r8; call`) and puts a `FunctionHook` on the INNER
  native function it calls. Mods get `on_camera_get_view_matrix(camera, result)` after the original ran `[inferred-static 2026-09-26]`.
- Lua `sdk.hook` hooks the reflected method's own function pointer = the WRAPPER, not the inner function
  (`ScriptRunner::install_hooks` -> `HookManager::add_either_or`) `[inferred-static 2026-09-26]`. So yes, Lua can hook
  get_ViewMatrix/get_ProjectionMatrix, **but it only sees callers that go through reflection (game scripts, our own `:call`)**.
  The renderer is C++ and calls the inner function directly — that is why praydog dug past the wrapper `[inferred-static]`.
  **So a Lua post-hook cannot change what a camera renders** `[inferred-static 2026-09-26]`.
- The render path does call the inner getters: VR.cpp's per-eye projection reaches the picture only through this hook (its
  SceneInfo matrix writes in `on_scene_layer_update` are commented out) `[inferred-static]`. But praydog's comment at l.340:
  *"the game *always* uses the main camera when calling this function, even though it's rendering the other camera"* — so even a
  native hook keyed on "camera == our clone" may never fire on the render path `[hypothesis, from his comment]`.
- **Correction to the §9ct reading.** The VIEW hook does `mtx = eye_transform * mtx` — it modifies the engine's own view matrix, it
  does not supply one. Only PROJECTION is replaced wholesale (for `m_multipass_cameras[0..1]` = main + his clone). So in VR his clone
  still needs an engine-computed view matrix; REFramework does not feed it from nothing `[inferred-static 2026-09-26]`.

## 2. Lua snippet (a DETECTOR more than a fix)

Struct return by value = hidden result pointer: the wrapper's `mov rcx,r8` means `this` is in r8, so in a Lua pre-hook
**args[1] = result pointer, args[2] = vm context, args[3] = the camera** (not args[2]) `[inferred-static]`; the snippet finds the
camera slot by address anyway. `retval` = rax = the same result pointer (MSVC). `sdk.to_valuetype` COPIES (Sdk.cpp l.377), so
writes go through `sdk.call_native_func(raw_ptr, via.mat4, "set_mN", Vector4f)` — `get_real_obj` accepts a raw pointer; that
via.mat4 owns `set_m0..set_m3` is `[hypothesis]` (the names sit in the pool beside get_m0..m3, owner not proven); the snippet
re-reads and logs whether the write landed.

```lua
-- rung 6: via.Camera matrix post-hook. Paste above `_G.re8_scope_cam_clone = {` and add  mathook = mathook, matfill = matfill,
-- mathits = mathits  to that table. Counts every reflected call per camera; with matfill(1) writes the main camera's last
-- matrix into calls made for OUR clone. Expect it to catch script calls only (renderer bypasses the wrapper).
local MAT_TD = sdk.find_type_definition("via.mat4")
st.mh = st.mh or { last = {}, hits = {}, fill = false, said = {} }
local function i64(p) return p ~= nil and (safe(function() return sdk.to_int64(p) end) or p) or nil end
local function read_mat(p)
    local vt = safe(function() return sdk.to_valuetype(p, MAT_TD) end)
    if vt == nil then return nil end
    local m = {}
    for i = 0, 15 do m[i + 1] = vt:read_float(i * 4) end
    return m
end
local function write_mat(p, m)
    for r = 0, 3 do
        local b = r * 4
        sdk.call_native_func(p, MAT_TD, "set_m" .. r, Vector4f.new(m[b + 1], m[b + 2], m[b + 3], m[b + 4]))
    end
end
local function mathook()
    if st.mh.installed then L("mathook: already installed") return end
    for _, name in ipairs({ "get_ViewMatrix", "get_ProjectionMatrix" }) do
        local m = sdk.find_type_definition("via.Camera"):get_method(name)
        sdk.hook(m, function(args)
            local s = thread.get_hook_storage()
            s.a = { i64(args[1]), i64(args[2]), i64(args[3]), i64(args[4]) }
            return sdk.PreHookResult.CALL_ORIGINAL
        end, function(retval)
            local s = thread.get_hook_storage()
            pcall(function()
                local main, ours = i64(addr(primary())), i64(addr(st.clone_cam))
                local slot, who
                for i = 1, 4 do
                    if s.a[i] == main then slot, who = i, "main" elseif ours ~= nil and s.a[i] == ours then slot, who = i, "ours" end
                end
                if not st.mh.said[name] then
                    st.mh.said[name] = true
                    L(string.format("mathook %s first call: args %s | retval %s | camera slot %s", name,
                        table.concat({ tostring(s.a[1]), tostring(s.a[2]), tostring(s.a[3]), tostring(s.a[4]) }, " "),
                        tostring(i64(retval)), tostring(slot)))
                end
                local k = name .. ":" .. (who or "other")
                st.mh.hits[k] = (st.mh.hits[k] or 0) + 1
                local out = retval
                if who == "main" then st.mh.last[name] = read_mat(out)
                elseif who == "ours" and st.mh.fill and st.mh.last[name] ~= nil then
                    write_mat(out, st.mh.last[name])
                    local back = read_mat(out)
                    if back ~= nil and not st.mh.said[k] then
                        st.mh.said[k] = true
                        L(string.format("matfill %s: wrote m[13..15]=%.3f %.3f %.3f, read back %.3f %.3f %.3f", name,
                            st.mh.last[name][13], st.mh.last[name][14], st.mh.last[name][15], back[13], back[14], back[15]))
                    end
                end
            end)
            return retval   -- must hand the pointer back (the post result is written back)
        end)
    end
    st.mh.installed = true
    L("mathook: installed on via.Camera get_ViewMatrix + get_ProjectionMatrix (reflected wrapper)")
end
local function matfill(on) st.mh.fill = (tostring(on) ~= "0") st.mh.said = {} L("matfill -> " .. tostring(st.mh.fill)) end
local function mathits()
    local o = {}
    for k, v in pairs(st.mh.hits) do o[#o + 1] = k .. "=" .. v end
    table.sort(o)
    L("mathits: " .. (#o > 0 and table.concat(o, " ") or "none"))
end
```

Reading: `mathits` shows `...:ours=0` unless something scripted asks for our camera's matrices (camcmp will — that is a sanity
check, not the renderer). A non-zero `other`/`main` rate with `ours=0` during play = the renderer does not come through the wrapper,
as expected. The first-call line confirms which arg is the camera and that retval == args[1].

## 3. A "recompute now" method?

re8.exe's TDB name pool lists via.Camera's reflected methods contiguously (at file offset 0xADFFBB0): get/set_FOV, Near/FarClipPlane,
VerticalEnable, **get_ViewMatrix, get_ProjectionMatrix, get_ViewProjMatrix**, get/set_AspectRatio, LookAtDistance, get_LookAtPosition,
ProjectionType, CameraType, DebugCamera, get_ViewFrustum — **no update/calc/refresh**. via.Transform's block (0xADF2296): lookAt,
rotateAxis, Local/World position-rotation-scale, get_WorldMatrix, get_LocalMatrix, Axis X/Y/Z, joints, set_Parent,
SameJointsConstraint, AbsoluteScaling — **no updateTransform/recalc** `[inferred-static 2026-09-26]` (the pool is de-duplicated, so a
generic name shared with an earlier type would not show here; low risk). `calcMatrix`, `recalcTransform`, `recalculateMatrix` exist
but sit in `app.*` game-script blocks, not via.*.

## What that leaves `[hypothesis]`

- If `camcmp` shows our matrices degenerate, the cheaper lever is NOT a hook: `matscan` gives the offset where via.Camera stores
  its matrix; write the main's bytes there on the clone each frame with `write_float` (camera is managed, writes are real).
- Moving the renderer requires native code (plugin hooking the inner function), and REFramework already hooks that same address.
