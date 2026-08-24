-- re8_scope_m4_mirror_recon3.lua -- M4 round 3: get the EXACT createComponent signature
-- (overload resolution needs the precise param-type string), then retry attach.

local function safe(fn) local ok, r = pcall(fn); if not ok then return nil end; return r end
local function L(s) log.info("[m4_mirror3] " .. tostring(s)) end

local go_td = safe(function() return sdk.find_type_definition("via.GameObject") end)
local exact_sigs = {}
if go_td then
    for _, m in ipairs(safe(function() return go_td:get_methods() end) or {}) do
        local n = safe(function() return m:get_name() end)
        if n == "createComponent" then
            local params = safe(function() return m:get_param_types() end) or {}
            local parts = {}
            for _, p in ipairs(params) do
                table.insert(parts, safe(function() return p:get_full_name() end) or "?")
            end
            local sig = "createComponent(" .. table.concat(parts, ", ") .. ")"
            L("exact overload: " .. sig)
            table.insert(exact_sigs, sig)
        end
    end
end

-- Also try attaching to a GameObject that's actually IN the live scene (not a bare
-- sdk.create_instance orphan) -- use the FadeInOutBlack GUI's own GameObject, present
-- at title screen per round-1 recon, since a real in-scene object is more likely to
-- actually get ticked/rendered by the engine each frame.
local scene = safe(function()
    local sm = sdk.get_native_singleton("via.SceneManager")
    local smt = sdk.find_type_definition("via.SceneManager")
    return sdk.call_native_func(sm, smt, "get_CurrentScene")
end)
local target_go = nil
if scene then
    local guis = safe(function() return scene:call("findComponents(System.Type)", sdk.typeof("via.gui.GUI")) end)
    for _, g in ipairs((guis and safe(function() return guis:get_elements() end)) or {}) do
        local goo = safe(function() return g:call("get_GameObject") end)
        local nm = goo and safe(function() return goo:call("get_Name") end)
        if nm == "FadeInOutBlack" then target_go = goo L("using in-scene GameObject: FadeInOutBlack") break end
    end
end
if target_go == nil then
    L("FadeInOutBlack not found this run, falling back to a fresh sdk.create_instance GameObject (may not be scene-live)")
    target_go = safe(function() local i = sdk.create_instance("via.GameObject") if i then i:add_ref() end return i end)
end

local mirror = nil
for _, sig in ipairs(exact_sigs) do
    local ok, r = pcall(function() return target_go:call(sig, sdk.typeof("via.render.Mirror")) end)
    L("call('" .. sig .. "') ok=" .. tostring(ok) .. " result=" .. tostring(r ~= nil) .. (ok and not r and (" err=" .. tostring(r)) or ""))
    if ok and r then mirror = r break end
end

if mirror == nil then
    L("Still could not attach Mirror -- candidate 1 blocked on component creation, not just RT-binding")
else
    L("SUCCESS: Mirror attached to an in-scene GameObject!")
    local res = safe(function() return sdk.create_resource("via.render.RenderTargetTextureResource", "movie/rtex/movie_1280_720.rtex") end)
    if res then
        safe(function() res:add_ref() end)
        local holder = safe(function() return res:create_holder("via.render.RenderTargetTextureResourceHolder") end)
        if holder then
            safe(function() holder:add_ref() end)
            local ok1 = pcall(function() mirror:call("set_RenderTarget", holder) end)
            local ok2 = pcall(function() mirror:call("registerScene", scene) end)
            L("set_RenderTarget=" .. tostring(ok1) .. " registerScene=" .. tostring(ok2))
            re.on_frame(function()
                if _G.m4r3_bound then return end
                _G.m4r3_bound = true
                local guis2 = safe(function() return scene:call("findComponents(System.Type)", sdk.typeof("via.gui.GUI")) end)
                for _, g in ipairs((guis2 and safe(function() return guis2:get_elements() end)) or {}) do
                    local goo = safe(function() return g:call("get_GameObject") end)
                    local nm = goo and safe(function() return goo:call("get_Name") end)
                    if nm == "BackColor" then
                        local ok3 = pcall(function() g:call("set_RenderTarget", holder) end)
                        L("redirected BackColor to mirror RT: " .. tostring(ok3) .. " -- CHECK SCREEN NOW")
                    end
                end
            end)
        end
    end
end

L("M4 round 3 pass complete")
