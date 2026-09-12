-- re8_scope_vrlens_probe.lua -- read Capcom's own VR sniper scope class, and measure the swing (2026-09-12, /lm).
--
-- Two jobs, both read-only, both logged as "[vrlens]" lines in the REFramework log:
--  1. app.VrWeaponSniperScopeLensUpdater: dump every field and method of the type from the live type
--     database, then look for live instances in the scene (findComponents) and print their GameObject
--     names and field values. Answers the board's "read Capcom's own VR scope" row without a SDK dump.
--  2. Every second, list every via.Camera in the scene with its GameObject name and the four projection
--     terms that move with the head under an HMD (m00, m11, m20, m21 = scale and off-centre offsets)
--     plus the view-matrix translation, so a mirror camera whose PROJECTION changes frame to frame
--     while its VIEW stays put is caught in numbers. That is the 9j claim, measured.
-- NUM8 re-runs the type dump + instance search. Nothing here writes to the game.

local TYPE = "app.VrWeaponSniperScopeLensUpdater"
local last_cam_log = 0
local dumped = false
local t_bound = nil

local function L(fmt, ...) log.info("[vrlens] " .. string.format(fmt, ...)) end

local function scene()
    local sm = sdk.get_native_singleton("via.SceneManager")
    if not sm then return nil end
    return sdk.call_native_func(sm, sdk.find_type_definition("via.SceneManager"), "get_CurrentScene")
end

local function find_components(td)
    local sc = scene()
    if not sc or not td then return {} end
    local ok, arr = pcall(function() return sc:call("findComponents(System.Type)", td:get_runtime_type()) end)
    if not ok or not arr then return {} end
    local out = {}
    local n = 0
    pcall(function() n = arr:get_size() end)
    for i = 0, n - 1 do
        local ok2, c = pcall(function() return arr:get_element(i) end)
        if ok2 and c then out[#out + 1] = c end
    end
    return out
end

local function go_name(comp)
    local ok, go = pcall(function() return comp:call("get_GameObject") end)
    if not ok or not go then return "?" end
    local ok2, nm = pcall(function() return go:call("get_Name") end)
    return ok2 and tostring(nm) or "?"
end

local function dump_type()
    local td = sdk.find_type_definition(TYPE)
    if not td then L("type %s NOT in the type database", TYPE) return end
    L("type %s found; parent=%s", TYPE, tostring(td:get_parent_type() and td:get_parent_type():get_full_name()))
    for _, f in ipairs(td:get_fields()) do
        local ft = "?"
        pcall(function() ft = f:get_type():get_full_name() end)
        L("  field %-28s %s @0x%x%s", f:get_name(), ft, f:get_offset_from_base(), f:is_static() and " static" or "")
    end
    for _, m in ipairs(td:get_methods()) do
        local ret = "?"
        pcall(function() ret = m:get_return_type():get_full_name() end)
        local ps = {}
        pcall(function() for _, p in ipairs(m:get_param_types()) do ps[#ps + 1] = p:get_full_name() end end)
        L("  method %s(%s) -> %s", m:get_name(), table.concat(ps, ","), ret)
    end
    local insts = find_components(td)
    L("live instances in scene: %d", #insts)
    for i, inst in ipairs(insts) do
        L("  instance %d on GameObject '%s'", i, go_name(inst))
        for _, f in ipairs(td:get_fields()) do
            if not f:is_static() then
                local v = "?"
                pcall(function() v = tostring(inst:get_field(f:get_name())) end)
                L("    %s = %s", f:get_name(), v)
            end
        end
    end
    -- who else mentions VR scopes: any type with 'VrWeapon' in the name that has live instances
    for _, cand in ipairs({ "app.VrWeaponSniperScope", "app.VrWeaponManager", "app.VrWeaponSniperScopeLens" }) do
        local ctd = sdk.find_type_definition(cand)
        if ctd then L("related type present: %s (%d live)", cand, #find_components(ctd)) end
    end
end

local typed_once = false
-- REFramework hands matrices back in more than one shape depending on the getter; try each.
-- Seen live 2026-09-12: the getters return a sol-bound glm mat4 ("sol.glm::mat<4,4,float,0>");
-- integer double-indexing gave nil, so rows are taken as vec4 and read by component letter.
local COMP = { [0] = "x", [1] = "y", [2] = "z", [3] = "w" }
local function mget(m, r, c)
    local v
    if pcall(function() v = m[r][COMP[c]] end) and type(v) == "number" then return v end
    if pcall(function() v = m[r][c] end) and type(v) == "number" then return v end
    if pcall(function() v = m[r + 1][COMP[c]] end) and type(v) == "number" then return v end
    if pcall(function() v = m[r + 1][c + 1] end) and type(v) == "number" then return v end
    if pcall(function() local row = m[r]; v = row[c] end) and type(v) == "number" then return v end
    if pcall(function() v = m:get_field("m" .. r .. c) end) and type(v) == "number" then return v end
    return nil
end

local function log_cameras()
    local td = sdk.find_type_definition("via.Camera")
    local cams = find_components(td)
    for i, cam in ipairs(cams) do
        local nm = go_name(cam)
        local p, v
        pcall(function() p = cam:call("get_ProjectionMatrix") end)
        pcall(function() v = cam:call("get_ViewMatrix") end)
        local fov = "?"
        pcall(function() fov = string.format("%.2f", cam:call("get_FOV")) end)
        if p and v then
            if not typed_once then
                typed_once = true
                L("matrix userdata type: %s / %s", tostring(p), tostring(v))
                local row = nil
                pcall(function() row = p[0] end)
                L("row0 type: %s  row0.x=%s  row0[0]=%s", tostring(row), tostring(row and row.x), tostring(row and row[0]))
                -- also name every mirror in the scene once, so the mirror camera can be told apart
                local mtd = sdk.find_type_definition("via.render.Mirror")
                for j, mir in ipairs(find_components(mtd)) do L("mirror %d on GameObject '%s'", j, go_name(mir)) end
            end
            local m00, m11, m20, m21 = mget(p, 0, 0), mget(p, 1, 1), mget(p, 2, 0), mget(p, 2, 1)
            local t0, t1, t2 = mget(v, 3, 0), mget(v, 3, 1), mget(v, 3, 2)
            L("cam %d '%s' fov=%s proj m00=%s m11=%s m20=%s m21=%s | view t=(%s %s %s)",
                i, nm, fov, tostring(m00), tostring(m11), tostring(m20), tostring(m21), tostring(t0), tostring(t1), tostring(t2))
        else
            L("cam %d '%s' fov=%s (matrices unreadable)", i, nm, fov)
        end
    end
end

re.on_frame(function()
    if reframework:is_key_down(0x68) then dumped = false end   -- VK_NUMPAD8 re-runs the dump
    local now = os.clock()
    if not t_bound then t_bound = now end
    if not dumped and now - t_bound > 20 then
        dumped = true
        local ok, err = pcall(dump_type)
        if not ok then L("dump threw: %s", tostring(err)) end
    end
    if now - last_cam_log >= 1.0 and now - t_bound > 20 then
        last_cam_log = now
        local ok, err = pcall(log_cameras)
        if not ok then L("cameras threw: %s", tostring(err)) end
    end
end)

L("loaded")
