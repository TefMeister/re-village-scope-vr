-- re8_scope_m4_mirror_recon4.lua -- M4 round 4: decisive test. Attach Mirror,
-- set_RenderTarget + registerScene (as round 3, confirmed working calls), then
-- redirect EVERY GUI component on screen to the mirror's RT simultaneously and
-- ALSO explicitly force the mirror visible/active, to settle once and for all
-- whether ANY pixel from it reaches the screen.

local function safe(fn) local ok, r = pcall(fn); if not ok then return nil end; return r end
local function L(s) log.info("[m4_mirror4] " .. tostring(s)) end

local go_td = safe(function() return sdk.find_type_definition("via.GameObject") end)
local sig = nil
for _, m in ipairs(safe(function() return go_td:get_methods() end) or {}) do
    if safe(function() return m:get_name() end) == "createComponent" then sig = "createComponent(System.Type)" break end
end

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
        if nm == "FadeInOutBlack" then target_go = goo break end
    end
end

local mirror = safe(function() return target_go:call(sig, sdk.typeof("via.render.Mirror")) end)
L("mirror attached: " .. tostring(mirror ~= nil))
if mirror == nil then L("ABORT: no mirror") return end

-- force it visible/active explicitly, in case default state is off
safe(function() mirror:call("set_LightWeightMode", false) end)
local transform = safe(function() return target_go:call("get_Transform") end)
if transform then
    L("FadeInOutBlack transform found, current position:")
    local pos = safe(function() return transform:call("get_Position") end)
    if pos then
        local x = safe(function() return pos:get_field("x") end)
        local y = safe(function() return pos:get_field("y") end)
        local z = safe(function() return pos:get_field("z") end)
        L("  pos = " .. tostring(x) .. ", " .. tostring(y) .. ", " .. tostring(z))
    end
end

local res = safe(function() return sdk.create_resource("via.render.RenderTargetTextureResource", "movie/rtex/movie_1280_720.rtex") end)
local holder = nil
if res then
    safe(function() res:add_ref() end)
    holder = safe(function() return res:create_holder("via.render.RenderTargetTextureResourceHolder") end)
    if holder then safe(function() holder:add_ref() end) end
end
if holder == nil then L("ABORT: no holder") return end

local ok1 = pcall(function() mirror:call("set_RenderTarget", holder) end)
local ok2 = pcall(function() mirror:call("registerScene", scene) end)
L("set_RenderTarget=" .. tostring(ok1) .. " registerScene=" .. tostring(ok2))
local vis_ok, vis = pcall(function() return mirror:call("get_Visible") end)
L("mirror get_Visible after registerScene: ok=" .. tostring(vis_ok) .. " value=" .. tostring(vis))

local redirected = 0
re.on_frame(function()
    if _G.m4r4_done then return end
    _G.m4r4_done = true
    local guis2 = safe(function() return scene:call("findComponents(System.Type)", sdk.typeof("via.gui.GUI")) end)
    for _, g in ipairs((guis2 and safe(function() return guis2:get_elements() end)) or {}) do
        local ok3 = pcall(function() g:call("set_RenderTarget", holder) end)
        if ok3 then redirected = redirected + 1 end
    end
    L("redirected " .. redirected .. " GUI elements to the mirror RT -- SCREENSHOT NOW")
end)
