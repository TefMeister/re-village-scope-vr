-- re8_spread_kill.lua -- make the sniper rifle shoot straight from the hip.
-- 2026-09-20. Starts READ-ONLY. It writes nothing until you tell it to.
--
-- WHAT TEFA ASKED FOR (2026-09-20, their words):
--   "get the bullet spread to 0 somehow and be able to shoot the rifle without the need to
--    hold aim button RG for it to turn accurate, it just has to be accurate when looking
--    through the scope"
--
-- WHY THIS TOOL AND NOT MORE DIGGING
-- `re8_spread_dig.lua` already found the parts. Read back on 2026-09-20, the 2026-09-17 probe
-- output shows `app.WeaponGunCore` carrying, in one block:
--     field  isReduceRecoil        : System.Boolean
--     field  isRestrictAimShake    : System.Boolean
--     method enableReduceRecoil
--     method enableRestrictAimShake
--     method setupDiffusion
-- Confirmed against re8.exe the same day: those two `enable...` methods sit in WeaponGunCore's
-- method table between `updateScope` / `enableHighRateScope` and `shootCommon` / `createBullet` /
-- `setupDiffusion` [measured 2026-09-20]. They are the gun's own steadiness switches, sitting
-- beside the code that fires the shot.
--
-- ⚠ SO THE DECIDING QUESTION IS NOT "what number is the spread". It is:
--       DOES THE GAME ITSELF CALL enableRestrictAimShake(true) WHEN YOU HOLD AIM?
-- If it does, then "hold RG to become accurate" IS that call, and the whole job is to make it
-- permanent. If it does not, the accuracy comes from somewhere else and we have learned that
-- for the price of one launch instead of guessing at it.
--
-- This tool watches those calls before it changes anything. Watching is the point.
--
-- ⚠ WHAT IS NOT KNOWN, and must not be written up as if it were:
--   * whether `enableRestrictAimShake` takes a bool (the tool reads its real signature and
--     REFUSES to call it if it is anything else -- it will say so rather than guess)
--   * whether the sniper scatters from a DIFFUSION CONE at all, or purely from aim movement.
--     `DiffusionNum` exists because of shotguns; the rifle may well have IsDiffusion = false.
--     `read` settles that by printing the live values, not by reasoning about it.
--
-- HOW TO RUN IT -- write ONE line into  reframework\data\re_spread_kill_cmd.txt :
--     read            dump every live field of the gun in your hands, with its value
--     steady on       call enableRestrictAimShake(true) + enableReduceRecoil(true) every frame
--     steady off      stop (the game reverts it by itself on the next weapon change)
--     quiet on|off    stop/start the per-call watch lines, if the log gets noisy
--     status          say what is captured and what is on
--
-- Its OWN command file, so it cannot race the scope harness or the dig tool.
-- Everything it prints is prefixed [spread-kill].

local CMD    = "re_spread_kill_cmd.txt"
local PREFIX = "[spread-kill] "
local CORE   = "app.WeaponGunCore"

local state = {
    core        = nil,     -- the live app.WeaponGunCore of the weapon in hand
    core_seen   = 0,       -- how many times we have captured one
    steady      = false,
    quiet       = false,
    calls       = {},      -- method name -> count, so the log cannot flood
    m_shake     = nil,
    m_recoil    = nil,
    shake_ok    = false,   -- signature checked and callable
    recoil_ok   = false,
    last_apply  = 0.0,
}

local function L(fmt, ...)
    local ok, s = pcall(string.format, fmt, ...)
    log.info(PREFIX .. (ok and s or tostring(fmt)))
end

-- ---------------------------------------------------------------------------
-- Value printing. A field dump is only useful if the VALUES come out, not the types.
-- ---------------------------------------------------------------------------
local function describe(v)
    local t = type(v)
    if v == nil then return "nil" end
    if t == "boolean" or t == "number" or t == "string" then return tostring(v) end
    if t == "userdata" then
        local name = "?"
        pcall(function() name = v:get_type_definition():get_full_name() end)
        -- vec3 / vec2 print usefully; everything else is just an object
        local x, y, z
        pcall(function() x, y, z = v.x, v.y, v.z end)
        if x ~= nil and y ~= nil then
            return string.format("%s(%.4f, %.4f, %.4f)", name, x, y, z or 0.0)
        end
        return "<" .. name .. ">"
    end
    return "<" .. t .. ">"
end

local function dump_live(obj, label)
    if obj == nil then L("%s -- nothing captured yet; hold the rifle and fire once", label) return end
    local td
    local ok = pcall(function() td = obj:get_type_definition() end)
    if not ok or td == nil then L("%s -- object has no type definition", label) return end

    L("================ %s   (%s)", label, td:get_full_name())
    local fields = {}
    pcall(function() fields = td:get_fields() end)
    L("  -- %d fields, with their CURRENT values --", #fields)
    for _, f in ipairs(fields) do
        local fn, ft = "?", "?"
        pcall(function() fn = f:get_name() end)
        pcall(function() ft = f:get_type():get_full_name() end)
        local val = nil
        pcall(function() val = obj:get_field(fn) end)
        -- mark the ones this job is about, so the list can be skimmed
        local mark = "  "
        if fn:lower():find("diffus") or fn:lower():find("shake")
            or fn:lower():find("recoil") or fn:lower():find("accur") then mark = ">>" end
        L("  %s %-38s %-22s = %s", mark, fn, ft, describe(val))
    end
    L("  >> lines marked >> are the ones this job is about")
end

-- ---------------------------------------------------------------------------
-- Capturing the live gun. There is no singleton for it, so we take `this` off any
-- WeaponGunCore method the game calls. REFramework passes args[2] as `this` for an
-- instance method -- but rather than trust that, we check both slots and keep whichever
-- really is a WeaponGunCore. A wrong guess here would poison everything after it.
-- ---------------------------------------------------------------------------
local function capture_this(args)
    for _, slot in ipairs({ 2, 1 }) do
        local obj = nil
        pcall(function() obj = sdk.to_managed_object(args[slot]) end)
        if obj ~= nil then
            local name = nil
            pcall(function() name = obj:get_type_definition():get_full_name() end)
            if name ~= nil and (name == CORE or name:find("WeaponGunCore")) then
                if state.core ~= obj then
                    state.core = obj
                    state.core_seen = state.core_seen + 1
                    L("captured the gun in your hands: %s (slot args[%d], capture #%d)",
                      name, slot, state.core_seen)
                end
                return obj
            end
        end
    end
    return nil
end

local function note_call(name, extra)
    state.calls[name] = (state.calls[name] or 0) + 1
    local n = state.calls[name]
    if state.quiet then return end
    -- first five of each, then every fiftieth: enough to see a pattern, not enough to flood
    if n <= 5 or n % 50 == 0 then
        L("CALL #%d  %s%s", n, name, extra and ("  " .. extra) or "")
    end
end

local function bool_arg(args, slot)
    local v = nil
    pcall(function() v = sdk.to_int64(args[slot]) end)
    if v == nil then return "?" end
    return tostring((v & 1) == 1)
end

-- ---------------------------------------------------------------------------
-- Signature check. We only ever call a method whose parameters we have actually read.
-- ---------------------------------------------------------------------------
local function takes_one_bool(m)
    if m == nil then return false end
    local ps = {}
    local ok = pcall(function() ps = m:get_param_types() end)
    if not ok then return false end
    if #ps ~= 1 then return false end
    local n = "?"
    pcall(function() n = ps[1]:get_full_name() end)
    return n == "System.Boolean"
end

local function describe_signature(m, name)
    if m == nil then L("  %s -- NOT FOUND on %s", name, CORE) return end
    local ps, ret = {}, "?"
    pcall(function() for _, p in ipairs(m:get_param_types()) do ps[#ps + 1] = p:get_full_name() end end)
    pcall(function() ret = m:get_return_type():get_full_name() end)
    L("  %s(%s) -> %s", name, table.concat(ps, ", "), ret)
end

-- ---------------------------------------------------------------------------
-- Set up. Hook the three methods that matter, read-only.
-- ---------------------------------------------------------------------------
local function setup()
    local td = sdk.find_type_definition(CORE)
    if td == nil then
        L("⚠ %s is NOT in this game's type database. Nothing below can work.", CORE)
        return
    end
    L("found %s", CORE)

    state.m_shake  = td:get_method("enableRestrictAimShake")
    state.m_recoil = td:get_method("enableReduceRecoil")
    local m_diff   = td:get_method("setupDiffusion")

    L("the three methods this job turns on:")
    describe_signature(state.m_shake,  "enableRestrictAimShake")
    describe_signature(state.m_recoil, "enableReduceRecoil")
    describe_signature(m_diff,         "setupDiffusion")

    state.shake_ok  = takes_one_bool(state.m_shake)
    state.recoil_ok = takes_one_bool(state.m_recoil)
    if not state.shake_ok then
        L("⚠ enableRestrictAimShake does not take a single bool -- 'steady on' will NOT call it.")
    end
    if not state.recoil_ok then
        L("⚠ enableReduceRecoil does not take a single bool -- 'steady on' will NOT call it.")
    end

    -- Watch. This is the read that decides the whole job.
    if state.m_shake ~= nil then
        sdk.hook(state.m_shake, function(args)
            capture_this(args)
            note_call("enableRestrictAimShake", "arg=" .. bool_arg(args, 3)
                .. "  <-- if this turns true when you HOLD AIM, that is the accuracy you want")
        end, function(r) return r end)
    end
    if state.m_recoil ~= nil then
        sdk.hook(state.m_recoil, function(args)
            capture_this(args)
            note_call("enableReduceRecoil", "arg=" .. bool_arg(args, 3))
        end, function(r) return r end)
    end
    if m_diff ~= nil then
        sdk.hook(m_diff, function(args)
            capture_this(args)
            note_call("setupDiffusion", "<-- the cone is being installed on THIS shot")
        end, function(r) return r end)
    end

    L("watching. Nothing is being changed.")
    L("Hold the rifle. Fire once from the hip, then once holding aim, and read the CALL lines.")
end

-- ---------------------------------------------------------------------------
-- Applying. Re-asserted every frame on purpose: the game sets these itself on weapon
-- change and on state changes, so a one-shot write would be quietly undone and we would
-- wrongly conclude the lever does not work.
-- ---------------------------------------------------------------------------
local function apply_steady()
    if state.core == nil then return end
    if state.shake_ok then pcall(function() state.m_shake:call(state.core, true) end) end
    if state.recoil_ok then pcall(function() state.m_recoil:call(state.core, true) end) end
end

local function status()
    L("---- status ----")
    L("  gun captured : %s (%d time(s))", state.core ~= nil and "yes" or "NO -- fire once", state.core_seen)
    L("  steady       : %s", state.steady and "ON" or "off")
    L("  callable     : enableRestrictAimShake=%s  enableReduceRecoil=%s",
      tostring(state.shake_ok), tostring(state.recoil_ok))
    local any = false
    for k, v in pairs(state.calls) do L("  seen %-26s %d call(s)", k, v) any = true end
    if not any then L("  no calls seen yet -- the game has not touched any of them") end
end

local function run(line)
    local cmd, arg = line:match("^%s*(%S+)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    arg = (arg or ""):lower()

    if cmd == "read" then
        dump_live(state.core, "the gun in your hands")
    elseif cmd == "steady" then
        state.steady = (arg ~= "off")
        L("steady %s%s", state.steady and "ON" or "off",
          state.steady and " -- enableRestrictAimShake(true) + enableReduceRecoil(true) every frame" or "")
        if state.steady and state.core == nil then
            L("⚠ no gun captured yet -- fire once so it can be grabbed, then this starts working")
        end
    elseif cmd == "quiet" then
        state.quiet = (arg ~= "off")
        L("watch lines %s", state.quiet and "silenced" or "back on")
    elseif cmd == "status" then
        status()
    else
        L("not understood: %s   (read / steady on|off / quiet on|off / status)", line)
    end
end

-- ---------------------------------------------------------------------------
-- Command file + the per-frame apply. Same shape as the dig tool: consume the file
-- FIRST so a failing command cannot loop forever.
-- ---------------------------------------------------------------------------
local last_poll = 0.0

re.on_frame(function()
    if state.steady then
        local now = os.clock()
        if now - state.last_apply > 0.016 then
            state.last_apply = now
            apply_steady()
        end
    end

    local now = os.clock()
    if now - last_poll < 0.5 then return end
    last_poll = now

    local ok, raw = pcall(fs.read, CMD)
    if not ok or raw == nil or raw == "" then return end
    pcall(fs.write, CMD, "")

    for line in tostring(raw):gmatch("[^\r\n]+") do
        if line:match("%S") then
            local ran, err = pcall(run, line)
            if not ran then L("command failed: %s", tostring(err)) end
        end
    end
end)

pcall(setup)
L("loaded. Commands go in reframework/data/%s -- start with 'status'.", CMD)
