-- re8_scope_m5_texture_native_recon.lua -- M5: candidate 2 groundwork. Load a REAL
-- on-disk texture resource (same class of thing M3's working glass-hijack used --
-- an actually-streamed asset, not a fresh RenderTargetTextureResource) and reflect
-- on its type for any native-resource accessor (method OR field) we can call from
-- the plugin's native C++ side to reach the real GPU resource.

local function safe(fn) local ok, r = pcall(fn); if not ok then return nil end; return r end
local function L(s) log.info("[m5_texnative] " .. tostring(s)) end

-- 1. Reflect via.render.Texture and via.render.TextureResource fully (methods + fields).
for _, tn in ipairs({"via.render.Texture", "via.render.TextureResource", "via.render.TextureResourceHolder"}) do
    local td = safe(function() return sdk.find_type_definition(tn) end)
    if td == nil then
        L(tn .. ": TYPE NOT FOUND")
    else
        L(tn .. ": methods:")
        for _, m in ipairs(safe(function() return td:get_methods() end) or {}) do
            local n = safe(function() return m:get_name() end)
            if n then L("  method: " .. n) end
        end
        L(tn .. ": fields:")
        for _, f in ipairs(safe(function() return td:get_fields() end) or {}) do
            local n = safe(function() return f:get_name() end)
            local ft = f and safe(function() return f:get_type() end)
            local ftn = ft and safe(function() return ft:get_full_name() end)
            if n then L("  field: " .. n .. "  (" .. tostring(ftn) .. ")") end
        end
    end
end

-- 2. Load a REAL on-disk texture (not a fresh RT) and inspect the live instance.
--    Use a texture we know exists: the game's own UI atlas is a safe bet, but we
--    don't have a confirmed path handy -- try a couple of plausible common ones and
--    report which (if any) actually loads, rather than guessing blind.
local candidates = {
    "GUI/00_Common/Texture/Icon/Item/im_item_all.tex",
    "gui/00_common/texture/icon/item/im_item_all.tex",
}
local loaded = nil
local loaded_path = nil
for _, path in ipairs(candidates) do
    local res = safe(function() return sdk.create_resource("via.render.TextureResource", path) end)
    if res then
        safe(function() res:add_ref() end)
        loaded = res
        loaded_path = path
        L("loaded texture resource OK: " .. path)
        break
    else
        L("failed to load: " .. path)
    end
end

if loaded then
    local td = safe(function() return loaded:get_type_definition() end)
    L("loaded resource live type: " .. tostring(td and safe(function() return td:get_full_name() end)))
    -- try any getter that sounds like it returns a native handle
    for _, mname in ipairs({"get_NativeTexture", "get_Texture", "get_RhiTexture", "get_D3D11Texture", "get_D3D12Texture", "get_Handle", "get_TexturePtr"}) do
        local ok, val = pcall(function() return loaded:call(mname) end)
        if ok then L("  " .. mname .. " -> callable, result=" .. tostring(val)) end
    end
else
    L("No candidate texture path loaded -- cannot inspect a live real-texture instance this round")
end

L("M5 recon pass complete")
