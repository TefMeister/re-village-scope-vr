-- re8_scope_m4_mirror_recon.lua -- M4: reflect via.render.Mirror's real API surface,
-- then (if a suitable target exists in the current scene) try it as an RT producer,
-- since M3's create_resource()-based RTs never got real GPU backing (notes/M3 recon).

local function safe(fn) local ok, r = pcall(fn); if not ok then return nil end; return r end
local function L(s) log.info("[m4_mirror] " .. tostring(s)) end

-- 1. Reflect via.render.Mirror: does the type even exist, and what can we call on it?
local mirror_td = safe(function() return sdk.find_type_definition("via.render.Mirror") end)
if mirror_td == nil then
    L("via.render.Mirror type NOT FOUND in this game's TDB -- candidate 1 is dead, moving to candidate 2/3")
else
    L("via.render.Mirror type FOUND. Methods:")
    local methods = safe(function() return mirror_td:get_methods() end) or {}
    for _, m in ipairs(methods) do
        local name = safe(function() return m:get_name() end)
        if name then L("  method: " .. name) end
    end
    L("Fields:")
    local fields = safe(function() return mirror_td:get_fields() end) or {}
    for _, f in ipairs(fields) do
        local name = safe(function() return f:get_name() end)
        if name then L("  field: " .. name) end
    end
end

-- 2. What's actually in the current scene right now (title/menu), for a test target.
local scene = safe(function()
    local sm = sdk.get_native_singleton("via.SceneManager")
    local smt = sdk.find_type_definition("via.SceneManager")
    return sdk.call_native_func(sm, smt, "get_CurrentScene")
end)
if scene == nil then
    L("no current scene yet")
else
    local root = safe(function() return scene:call("get_RootLayer") end)
    L("scene root: " .. tostring(root ~= nil))
    -- enumerate all via.gui.GUI components present, same technique as m3_recon6
    local guis = safe(function()
        return scene:call("findComponents(System.Type)", sdk.typeof("via.gui.GUI"))
    end)
    local count = 0
    for _, g in ipairs((guis and safe(function() return guis:get_elements() end)) or {}) do
        local go = safe(function() return g:call("get_GameObject") end)
        local nm = go and safe(function() return go:call("get_Name") end)
        if nm then L("GUI on scene: " .. nm); count = count + 1 end
    end
    L("total GUI components found: " .. count)
    -- also enumerate via.render.Mesh components (candidate targets to bind a texture onto)
    local meshes = safe(function()
        return scene:call("findComponents(System.Type)", sdk.typeof("via.render.Mesh"))
    end)
    local mcount = 0
    for _, m in ipairs((meshes and safe(function() return meshes:get_elements() end)) or {}) do
        mcount = mcount + 1
    end
    L("total Mesh components found: " .. mcount .. " (not naming all, just a count)")
end

-- 3. app.RecordSys -- candidate 3 -- does the type exist at all?
local recordsys_td = safe(function() return sdk.find_type_definition("app.RecordSys") end)
L("app.RecordSys type found: " .. tostring(recordsys_td ~= nil))
if recordsys_td ~= nil then
    local rmethods = safe(function() return recordsys_td:get_methods() end) or {}
    for _, m in ipairs(rmethods) do
        local name = safe(function() return m:get_name() end)
        if name and (name:find("[Rr][Tt]") or name:find("[Cc]amera") or name:find("[Rr]ender")) then
            L("  RecordSys candidate method: " .. name)
        end
    end
end

L("M4 recon pass complete")
