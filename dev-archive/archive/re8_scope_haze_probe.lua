-- re8_scope_haze_probe.lua -- READ-ONLY probe (2026-10-03, /lm home PC, Opus)
--
-- Why: outdoors the scope stays bright saturated blue where the world is pale grey fog, whatever curve or exposure
-- (Tefa, 22:15). Lead: the game applies via.render.LDRHazeFilter AFTER tone mapping (a grey veil, colour removed), driven
-- by app.HazeFilterController, and our clone skips every app.* component (re8_scope_cam_clone.lua skip_component).
-- This reads, every PROBE_EVERY_S, the haze filter of MainCamera's LDRPostProcess and of the clone's (ScopeCam2), plus
-- MainCamera's app.HazeFilterController / app.FogController fields, and logs a block ONLY when a value changed.
-- Writes nothing. Remove once the haze question is answered.

local TAG = "[re8-haze] "
local PROBE_EVERY_S = 2.0
local CLONE_NAME = "ScopeCam2"
local MAX_VALUES = 120             -- per object, keeps a block readable

local function L(s) log.info(TAG .. tostring(s)) end
local function safe(f) local ok, r = pcall(f) if ok then return r end return nil end

local function fmt(v)
    local t = type(v)
    if t == "number" then return string.format("%.4g", v) end
    if t == "boolean" or t == "string" then return tostring(v) end
    if t == "userdata" then
        local x = safe(function() return v.x end)
        if x ~= nil then
            local y, z, w = safe(function() return v.y end), safe(function() return v.z end), safe(function() return v.w end)
            return string.format("(%.3g %.3g %s %s)", x, y or 0, z and string.format("%.3g", z) or "", w and string.format("%.3g", w) or "")
        end
        local tn = safe(function() return v:get_type_definition():get_full_name() end)
        return tn and ("<" .. tn .. ">") or "<obj>"
    end
    return tostring(v)
end

-- every zero-argument get_* / is* method and every instance field, as "name=value"
local function dump(o)
    local out = {}
    local td = o and safe(function() return o:get_type_definition() end)
    while td ~= nil and #out < MAX_VALUES do
        for _, m in ipairs(safe(function() return td:get_methods() end) or {}) do
            local n = safe(function() return m:get_name() end) or ""
            if (n:sub(1, 4) == "get_" or n:sub(1, 2) == "is") and (safe(function() return m:get_num_params() end) or 1) == 0 then
                local v = safe(function() return o:call(n) end)
                if v ~= nil then out[#out + 1] = n:gsub("^get_", "") .. "=" .. fmt(v) end
            end
            if #out >= MAX_VALUES then break end
        end
        for _, f in ipairs(safe(function() return td:get_fields() end) or {}) do
            if not safe(function() return f:is_static() end) then
                local n = safe(function() return f:get_name() end) or "?"
                local v = safe(function() return o:get_field(n) end)
                if v ~= nil then out[#out + 1] = "." .. n .. "=" .. fmt(v) end
            end
            if #out >= MAX_VALUES then break end
        end
        local p = safe(function() return td:get_parent_type() end)
        local pn = p and safe(function() return p:get_full_name() end) or ""
        if pn == "" or pn == "System.Object" or pn == "via.Component" or pn == "via.clr.ManagedObject" then break end
        td = p
    end
    return table.concat(out, " ")
end

local function component(go, tn)
    local t = sdk.typeof(tn)
    return (go and t) and safe(function() return go:call("getComponent(System.Type)", t) end) or nil
end

local function main_go()
    local cam = safe(function() return sdk.get_primary_camera() end)
    return cam and safe(function() return cam:call("get_GameObject") end) or nil
end

local function clone_go()
    local sm = sdk.get_native_singleton("via.SceneManager")
    local smt = sdk.find_type_definition("via.SceneManager")
    local scene = sm and safe(function() return sdk.call_native_func(sm, smt, "get_CurrentScene") end)
    return scene and safe(function() return scene:call("findGameObject(System.String)", CLONE_NAME) end) or nil
end

local function haze_of(go)
    local ldr = component(go, "via.render.LDRPostProcess")
    if not ldr then return "no LDRPostProcess" end
    local h = safe(function() return ldr:call("get_HazeFilter") end)
    if not h then return "LDRPostProcess has no HazeFilter" end
    return dump(h)
end

-- round 2 (22:31): the haze filter is OFF on both cameras, indoors and out [verified-live 2026-10-03, n=1] -- lead dropped.
-- Now: compare MainCamera's fog components with the clone's, value by value, every COMPARE_EVERY_S.
local COMPARE_EVERY_S = 5.0
local FOG_TYPES = { "via.render.Fog", "via.render.VolumetricFog", "via.render.VolumetricFogControl" }
local MAX_DIFFS = 12

local function values(o)
    local m = {}
    for kv in dump(o):gmatch("%S+=%S+") do
        local k, v = kv:match("^(.-)=(.*)$")
        if k and not k:find("Cost") then m[k] = v end
    end
    return m
end

local next_t = 0
re.on_frame(function()
    local now = os.clock()
    if now < next_t then return end
    next_t = now + COMPARE_EVERY_S
    local m, c = main_go(), clone_go()
    if not m then return end
    if not c then L("no clone (scope not up)"); return end
    for _, tn in ipairs(FOG_TYPES) do
        local a, b = component(m, tn), component(c, tn)
        if not a or not b then
            L(string.format("%s: main %s, clone %s", tn, a and "yes" or "NO", b and "yes" or "NO"))
        else
            local va, vb = values(a), values(b)
            local diffs, n, total = {}, 0, 0
            for k, v in pairs(va) do
                total = total + 1
                if vb[k] ~= v then
                    n = n + 1
                    if #diffs < MAX_DIFFS then diffs[#diffs + 1] = k .. " main=" .. v .. " clone=" .. tostring(vb[k]) end
                end
            end
            L(string.format("%s: %d of %d values differ%s%s", tn, n, total, n > 0 and ": " or "", table.concat(diffs, " | ")))
        end
    end
end)

L("round 2 loaded: fog main vs clone, every " .. COMPARE_EVERY_S .. " s (MAX_VALUES " .. MAX_VALUES .. ")")
