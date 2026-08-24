-- re8_scope_m4_mirror_recon5.lua -- M4 round 5: check whether REFramework's Lua API
-- has a proper create-render-target helper (d2d/imgui overlay creation, or
-- re.create_d3d12_texture style functions) instead of repurposing a movie .rtex,
-- which might be the actual reason nothing gets real GPU backing.

local function L(s) log.info("[m4_mirror5] " .. tostring(s)) end
local function safe(fn) local ok, r = pcall(fn); if not ok then return nil end; return r end

L("Global 're' table functions containing render/texture/target:")
for k, v in pairs(re) do
    if type(v) == "function" and (tostring(k):lower():find("render") or tostring(k):lower():find("texture") or tostring(k):lower():find("target")) then
        L("  re." .. k)
    end
end

L("Global 'sdk' table functions containing resource/texture:")
for k, v in pairs(sdk) do
    if type(v) == "function" and (tostring(k):lower():find("resource") or tostring(k):lower():find("texture")) then
        L("  sdk." .. k)
    end
end

L("Global 'd2d' table exists: " .. tostring(d2d ~= nil))
L("Global 'imgui' table exists: " .. tostring(imgui ~= nil))

-- Also: check the actual created RT resource's own reported state (width/height/format)
-- to see if it's even a valid non-zero-size resource at all.
local res = safe(function() return sdk.create_resource("via.render.RenderTargetTextureResource", "movie/rtex/movie_1280_720.rtex") end)
if res then
    safe(function() res:add_ref() end)
    local td = safe(function() return res:get_type_definition() end)
    L("resource type: " .. tostring(td and safe(function() return td:get_full_name() end)))
    for _, mname in ipairs({"get_Width", "get_Height", "get_Format", "get_ArrayNum"}) do
        local ok, val = pcall(function() return res:call(mname) end)
        L("  " .. mname .. " ok=" .. tostring(ok) .. " val=" .. tostring(val))
    end
end

L("M4 round 5 pass complete")
