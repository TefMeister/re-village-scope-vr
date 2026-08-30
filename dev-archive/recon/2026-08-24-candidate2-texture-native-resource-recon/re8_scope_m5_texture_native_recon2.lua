-- re8_scope_m5_texture_native_recon2.lua -- M5 round 2: get_methods()/get_fields() only
-- return members declared directly on a type, not inherited ones (same gotcha this
-- project already hit on the native C SDK side, notes/2026-08-23). Walk the full
-- parent-type chain for TextureResourceHolder, and find a LIVE, already-bound texture
-- object via a real GUI component instead of a freshly create_resource'd handle
-- (which turns out not to be a reflectable managed object at all -- that's why
-- get_type_definition()/:call() kept returning nil/failing on it).

local function safe(fn) local ok, r = pcall(fn); if not ok then return nil end; return r end
local function L(s) log.info("[m5_texnative2] " .. tostring(s)) end

local function dump_type_chain(start_td, label)
    local td = start_td
    local depth = 0
    while td ~= nil and depth < 8 do
        local name = safe(function() return td:get_full_name() end) or "?"
        L(label .. " chain[" .. depth .. "] = " .. name)
        for _, m in ipairs(safe(function() return td:get_methods() end) or {}) do
            local n = safe(function() return m:get_name() end)
            if n then L("  method: " .. n) end
        end
        for _, f in ipairs(safe(function() return td:get_fields() end) or {}) do
            local n = safe(function() return f:get_name() end)
            if n then L("  field: " .. n) end
        end
        td = safe(function() return td:get_parent_type() end)
        depth = depth + 1
    end
end

local h_td = safe(function() return sdk.find_type_definition("via.render.TextureResourceHolder") end)
if h_td then dump_type_chain(h_td, "TextureResourceHolder") end

-- Find a LIVE, currently-bound texture on a real on-screen GUI element.
local scene = safe(function()
    local sm = sdk.get_native_singleton("via.SceneManager")
    local smt = sdk.find_type_definition("via.SceneManager")
    return sdk.call_native_func(sm, smt, "get_CurrentScene")
end)
if scene then
    local guis = safe(function() return scene:call("findComponents(System.Type)", sdk.typeof("via.gui.GUI")) end)
    for _, g in ipairs((guis and safe(function() return guis:get_elements() end)) or {}) do
        -- via.gui.GUI components commonly have get_Texture / get_Material style accessors --
        -- try a few plausible names, first hit wins.
        for _, mname in ipairs({"get_Texture", "get_Material", "get_MaterialTexture"}) do
            local ok, tex = pcall(function() return g:call(mname) end)
            if ok and tex ~= nil then
                local ttd = safe(function() return tex:get_type_definition() end)
                local goo = safe(function() return g:call("get_GameObject") end)
                local nm = goo and safe(function() return goo:call("get_Name") end)
                L("GUI '" .. tostring(nm) .. "' ." .. mname .. "() -> live object, type=" .. tostring(ttd and safe(function() return ttd:get_full_name() end)))
                if ttd then dump_type_chain(ttd, mname .. "@" .. tostring(nm)) end
            end
        end
    end
end

L("M5 round 2 pass complete")
