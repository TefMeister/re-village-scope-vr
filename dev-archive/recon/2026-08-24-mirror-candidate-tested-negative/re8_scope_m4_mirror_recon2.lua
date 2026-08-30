-- re8_scope_m4_mirror_recon2.lua -- M4 round 2: find GameObject/Scene creation methods,
-- create a GameObject, attach via.render.Mirror, registerScene, and try to display its
-- output on an existing GUI element's texture (same redirect trick as m3_recon6).

local function safe(fn) local ok, r = pcall(fn); if not ok then return nil end; return r end
local function L(s) log.info("[m4_mirror2] " .. tostring(s)) end

-- 1. Reflect GameObject creation methods on via.GameObject / via.Scene
local go_td = safe(function() return sdk.find_type_definition("via.GameObject") end)
if go_td then
    L("via.GameObject methods matching create/component:")
    for _, m in ipairs(safe(function() return go_td:get_methods() end) or {}) do
        local n = safe(function() return m:get_name() end)
        if n and (n:find("[Cc]omponent") or n:find("[Cc]reate")) then L("  " .. n) end
    end
end
local scene_td = safe(function() return sdk.find_type_definition("via.Scene") end)
if scene_td then
    L("via.Scene methods matching create/object:")
    for _, m in ipairs(safe(function() return scene_td:get_methods() end) or {}) do
        local n = safe(function() return m:get_name() end)
        if n and (n:find("[Cc]reate")) then L("  " .. n) end
    end
end

-- 2. Try the standard REFramework pattern: sdk.create_instance for a GameObject
local go = safe(function()
    local inst = sdk.create_instance("via.GameObject")
    if inst then inst:add_ref() end
    return inst
end)
L("sdk.create_instance(via.GameObject) -> " .. tostring(go ~= nil))

local scene = safe(function()
    local sm = sdk.get_native_singleton("via.SceneManager")
    local smt = sdk.find_type_definition("via.SceneManager")
    return sdk.call_native_func(sm, smt, "get_CurrentScene")
end)

-- Common REFramework pattern: Scene:createGameObject(name) or Scene:createGameObject2
local go2 = nil
if scene then
    for _, sig in ipairs({"createGameObject(System.String)", "createGameObject2(System.String)", "createGameObject(System.String, via.Float3, via.Quaternion)"}) do
        local ok, r = pcall(function() return scene:call(sig, "m4_mirror_probe") end)
        L("scene:call('" .. sig .. "') ok=" .. tostring(ok) .. " result=" .. tostring(r ~= nil))
        if ok and r then go2 = r break end
    end
end

local target_go = go2 or go
if target_go == nil then
    L("Could NOT create any GameObject via known patterns -- cannot attach Mirror this round")
else
    L("Have a GameObject, attempting to attach via.render.Mirror component...")
    local mirror = nil
    for _, sig in ipairs({"createComponent(System.Type)", "createComponent2(System.Type)"}) do
        local ok, r = pcall(function() return target_go:call(sig, sdk.typeof("via.render.Mirror")) end)
        L("go:call('" .. sig .. "', Mirror) ok=" .. tostring(ok) .. " result=" .. tostring(r ~= nil))
        if ok and r then mirror = r break end
    end

    if mirror ~= nil then
        L("Mirror component attached! Setting up RT + registerScene...")
        local res = safe(function() return sdk.create_resource("via.render.RenderTargetTextureResource", "movie/rtex/movie_1280_720.rtex") end)
        if res then
            safe(function() res:add_ref() end)
            local holder = safe(function() return res:create_holder("via.render.RenderTargetTextureResourceHolder") end)
            if holder then
                safe(function() holder:add_ref() end)
                local ok1 = pcall(function() mirror:call("set_RenderTarget", holder) end)
                local ok2 = pcall(function() mirror:call("registerScene", scene) end)
                L("mirror set_RenderTarget=" .. tostring(ok1) .. " registerScene=" .. tostring(ok2))

                -- redirect an existing, harmless GUI (GUIMouseCursor, present at title screen) to display it
                re.on_frame(function()
                    if _G.m4_bound then return end
                    _G.m4_bound = true
                    local guis = safe(function() return scene:call("findComponents(System.Type)", sdk.typeof("via.gui.GUI")) end)
                    for _, g in ipairs((guis and safe(function() return guis:get_elements() end)) or {}) do
                        local goo = safe(function() return g:call("get_GameObject") end)
                        local nm = goo and safe(function() return goo:call("get_Name") end)
                        if nm == "GUIMouseCursor" then
                            local ok3 = pcall(function() g:call("set_RenderTarget", holder) end)
                            L("redirected GUIMouseCursor to mirror RT: " .. tostring(ok3) .. " -- CHECK SCREEN")
                        end
                    end
                end)
            else
                L("create_holder failed")
            end
        else
            L("create_resource failed")
        end
    else
        L("Could NOT attach via.render.Mirror via known createComponent signatures")
    end
end

L("M4 round 2 pass complete")
