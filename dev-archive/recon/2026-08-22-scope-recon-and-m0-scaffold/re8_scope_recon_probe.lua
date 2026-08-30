-- re8_scope_recon_probe.lua  (v3)
-- READ-ONLY recon for the RE Village (RE8) sniper scope -> VR picture-in-picture work.
-- Confirmed so far: scope GUI element = "GUIScope"; ADS narrows MAIN camera FOV 63 -> 24.37.
-- v3: hands-free capture. You can't hold ADS AND click UI, so:
--   * the weapon dump AUTO-fires the first time the scope is active (no button needed), and
--   * "Arm timed dump" gives a 10s window: click it, close the menu, raise the scope, and it
--     dumps the instant the scope is detected active (FOV<45 or GUIScope drawn <0.3s ago).
-- Also re-dumps GUIScope structure on each armed capture. Nothing writes game state.

local M = {
    enabled = true, log_gui = true, log_fov = true,
    fov_last = nil, fov_min = nil, fov_max = nil,
    seen = {}, seen_order = {},
    guiscope_dumped = false, guiscope_go = nil, dump_guiscope_pending = false,
    dump_weapon_pending = false,
    auto_dumped = false,
    armed_until = 0, armed_captured = false,
    last_guiscope_time = -999.0,
}

local function safe(fn) local ok, r = pcall(fn); if not ok then return nil end; return r end
local function is_vr() return safe(function() return vrmod and vrmod:is_hmd_active() end) == true end
local function type_name(obj) return safe(function() return obj:get_type_definition():get_full_name() end) end

local function components_of(go)
    local comps = safe(function() return go:call("get_Components") end)
    if comps == nil then return {} end
    local els = safe(function() return comps:get_elements() end)
    if els ~= nil then return els end
    local out = {}
    local cn = safe(function() return comps:call("get_Count") end) or 0
    for i = 0, cn - 1 do
        local c = safe(function() return comps:call("get_Item(System.Int32)", i) end)
        if c then out[#out + 1] = c end
    end
    return out
end

local function scope_active()
    if (os.clock() - M.last_guiscope_time) < 0.3 then return true end
    if M.fov_last and M.fov_last < 45.0 then return true end
    return false
end

-- ---- FOV watch --------------------------------------------------------------------
re.on_frame(function()
    if M.enabled and M.log_fov then
        local cam = safe(sdk.get_primary_camera)
        if cam ~= nil then
            local fov = safe(function() return cam:call("get_FOV") end)
            if type(fov) == "number" then
                if M.fov_min == nil or fov < M.fov_min then M.fov_min = fov end
                if M.fov_max == nil or fov > M.fov_max then M.fov_max = fov end
                if M.fov_last == nil then
                    M.fov_last = fov
                elseif math.abs(fov - M.fov_last) > 0.5 then
                    log.info(string.format("[scope_recon] FOV change %.2f -> %.2f (min=%.2f max=%.2f)",
                        M.fov_last, fov, M.fov_min or fov, M.fov_max or fov))
                    M.fov_last = fov
                end
            end
        end
    end

    -- hands-free auto weapon dump: first time the scope is active
    if not M.auto_dumped and scope_active() then
        M.auto_dumped = true
        log.info(string.format("[scope_recon] scope active (FOV=%.1f) -> AUTO weapon dump", M.fov_last or -1))
        safe(function() dump_weapon() end)
    end

    -- armed 10s window
    if M.armed_until > 0 and not M.armed_captured then
        if scope_active() then
            M.armed_captured = true
            M.armed_until = 0
            log.info(string.format("[scope_recon] ARMED capture: scope active (FOV=%.1f)", M.fov_last or -1))
            M.guiscope_dumped = false  -- allow GUIScope structure re-dump while scoped
            safe(function() dump_weapon() end)
        elseif os.clock() >= M.armed_until then
            M.armed_until = 0
            log.info("[scope_recon] ARMED window expired without scope detected")
        end
    end

    if M.dump_weapon_pending then M.dump_weapon_pending = false; safe(function() dump_weapon() end) end
    if M.dump_guiscope_pending then
        M.dump_guiscope_pending = false
        if M.guiscope_go then safe(function() dump_guiscope(M.guiscope_go) end) end
    end
end)

-- ---- GUI element collector + GUIScope one-shot trigger -----------------------------
re.on_pre_gui_draw_element(function(element, context)
    if not M.enabled or not M.log_gui then return true end
    local go = safe(function() return element:call("get_GameObject") end)
    if go == nil then return true end
    local name = safe(function() return go:call("get_Name") end)
    if type(name) ~= "string" then return true end

    local rec = M.seen[name]
    if rec == nil then
        local l = name:lower()
        local flagged = l:find("scope") or l:find("snip") or l:find("zoom")
            or l:find("reticle") or l:find("aim") or l:find("sight")
        rec = { count = 0, last = 0.0, flagged = flagged ~= nil }
        M.seen[name] = rec
        M.seen_order[#M.seen_order + 1] = name
        log.info("[scope_recon] " .. (rec.flagged and "NEW flagged GUI element: '" or "new GUI element: '") .. name .. "'")
    end
    rec.count = rec.count + 1
    rec.last = os.clock()

    if name == "GUIScope" then
        M.last_guiscope_time = os.clock()
        if not M.guiscope_dumped then
            M.guiscope_dumped = true
            safe(function() go:add_ref() end)
            M.guiscope_go = go
            M.dump_guiscope_pending = true
        end
    end

    return true
end)

-- ---- dumps ------------------------------------------------------------------------
function get_player()
    local p = safe(function() return re8vr and re8vr.player end)
    if p ~= nil then return p end
    return safe(function() return re8 and re8.player end)
end

function dump_weapon()
    log.info("[scope_recon] ===== weapon/equip dump start =====")
    local player = get_player()
    if player == nil then log.info("[scope_recon] player not resolved"); return end
    log.info("[scope_recon] player object resolved")
    local els = components_of(player)
    log.info("[scope_recon] player has " .. #els .. " components:")
    for _, c in ipairs(els) do
        local tn = type_name(c)
        if tn then
            local l = tn:lower()
            local flag = (l:find("equip") or l:find("weapon") or l:find("gun")
                or l:find("shell") or l:find("inventory") or l:find("hold")
                or l:find("hand") or l:find("scope")) and "   <<" or ""
            log.info("[scope_recon]   comp: " .. tn .. flag)
        else
            log.info("[scope_recon]   comp: <type unresolved>")
        end
    end
    log.info("[scope_recon] ===== weapon/equip dump end (grep '<<' for candidates) =====")
end

function dump_guiscope(go)
    log.info("[scope_recon] ===== GUIScope structure dump =====")
    local els = components_of(go)
    log.info("[scope_recon] GUIScope has " .. #els .. " components:")
    for _, c in ipairs(els) do
        local tn = type_name(c)
        if tn then log.info("[scope_recon]   gs-comp: " .. tn) end
    end
    local tf = safe(function() return go:call("get_Transform") end)
    if tf then
        local child = safe(function() return tf:call("get_Child") end)
        local guard = 0
        while child ~= nil and guard < 80 do
            guard = guard + 1
            local cgo = safe(function() return child:call("get_GameObject") end)
            local cn = cgo and safe(function() return cgo:call("get_Name") end)
            if type(cn) == "string" then log.info("[scope_recon]   gs-child: " .. cn) end
            child = safe(function() return child:call("get_Next") end)
        end
    end
    log.info("[scope_recon] ===== GUIScope dump end =====")
end

-- ---- Panel ------------------------------------------------------------------------
re.on_draw_ui(function()
    if not imgui.tree_node("Scope Recon") then return end
    changed, M.enabled = imgui.checkbox("Enabled", M.enabled)
    imgui.text(string.format("HMD active: %s   FOV now/min/max: %s / %s / %s",
        tostring(is_vr()),
        M.fov_last and string.format("%.1f", M.fov_last) or "?",
        M.fov_min and string.format("%.1f", M.fov_min) or "?",
        M.fov_max and string.format("%.1f", M.fov_max) or "?"))
    imgui.text(string.format("scope active now: %s   auto-dumped: %s", tostring(scope_active()), tostring(M.auto_dumped)))

    if imgui.button("Arm timed dump (raise scope within 10s)") then
        M.armed_until = os.clock() + 10.0
        M.armed_captured = false
        M.auto_dumped = false
        log.info("[scope_recon] armed timed dump -> close menu and raise the scope now")
    end
    if M.armed_until > os.clock() then
        imgui.text(string.format("  >> ARMED: %.1fs left, raise the scope...", M.armed_until - os.clock()))
    end

    if imgui.button("Reset auto-dump") then M.auto_dumped = false end
    imgui.same_line()
    if imgui.button("Re-dump GUIScope") then M.guiscope_dumped = false end

    imgui.text(string.format("GUI elements seen: %d", #M.seen_order))
    if imgui.tree_node("Seen GUI elements (flagged first)") then
        for _, name in ipairs(M.seen_order) do
            local r = M.seen[name]; if r and r.flagged then imgui.text(string.format("** %s  (x%d)", name, r.count)) end
        end
        for _, name in ipairs(M.seen_order) do
            local r = M.seen[name]; if r and not r.flagged then imgui.text(string.format("   %s  (x%d)", name, r.count)) end
        end
        imgui.tree_pop()
    end
    imgui.tree_pop()
end)

log.info("[scope_recon] re8_scope_recon_probe.lua v3 loaded")
