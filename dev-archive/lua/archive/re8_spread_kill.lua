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
-- ⛔ HARD CONSTRAINT FROM THE WEARER (2026-09-20) -- DO NOT "SIMPLIFY" THIS TOOL INTO IT:
--   "if you mean having RG - the aim button constantly on then this can't be an option because it
--    removes hands from the rifle, only the actual rifle is visible when RG is held and would cause
--    a whole heap of other issues"
-- Holding aim is NOT the fix and must never be forced. In VR, aim mode hides the hands and leaves
-- only the rifle drawn, which breaks the whole point of the mod. This tool never touches the aim
-- button, the aim state, or any input. It calls two methods ON THE GUN OBJECT directly, which is a
-- different thing entirely: the gun is told to steady itself while the player is NOT aiming, hands
-- and all. If those two switches turn out to be what aim mode was flipping, we get the accuracy
-- WITHOUT the aim pose -- that is the whole idea, not a side effect.
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
--     stats           the measured scatter per shot, in degrees, split hip vs aimed
--     flags           the gun's steadiness flags right now, plus the trigger
--     fix on          write the barrel direction over the scattered one; PROVES ITSELF
--     trace on        watch the whole firing path, in order
--     skip on         do not let setupDiffusion run at all
--     spec on         force the weapon spec's diffusion radius to zero <-- then this
--     zero swap       the same, the other way round, if 'zero on' sends shots wild
--     zero off        give the game its own scatter back
--     watchflags off  stop the automatic change lines, if they get noisy
--
-- Its OWN command file, so it cannot race the scope harness or the dig tool.
-- Everything it prints is prefixed [spread-kill].

local CMD    = "re_spread_kill_cmd.txt"
local PREFIX = "[spread-kill] "
local CORE   = "app.WeaponGunCore"

local state = {
    core        = nil,     -- the live app.WeaponGunCore of the weapon in hand
    core_seen   = 0,       -- how many times we have captured one
    quiet       = false,
    calls       = {},      -- method name -> count, so the log cannot flood
    m_shake     = nil,
    m_recoil    = nil,
    shake_ok    = false,   -- signature checked and callable
    recoil_ok   = false,
    last_apply  = 0.0,
    skip        = false,   -- skip setupDiffusion entirely
    spec        = false,   -- force the weapon spec's diffusion numbers to zero
    spec_hits   = 0,       -- how many times the spec getters were actually asked
    fix         = false,   -- the self-verifying write
    trace       = false,
    trace_left  = 0,
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
-- MEASURING THE SCATTER, so nobody has to judge where a bullet landed.
--
-- `setupDiffusion(via.vec3, via.Quaternion, via.Quaternion)` is handed the shot's
-- origin and TWO rotations. Read as (intended, scattered): the angle between them
-- IS the scatter of that one shot, in degrees, exactly, before the bullet exists.
-- So the test needs no target, no aiming at anything, and no eyesight -- firing at
-- the sky measures just as well as firing at a barrel.
--
-- ⚠ The (intended, scattered) reading is [hypothesis]. If the two quaternions turn
-- out to be something else the angle will be nonsense -- but it will be OBVIOUS
-- nonsense (constant, or wild), and the shot COUNT and the flag columns below stay
-- valid either way. Read the first few SHOT lines before trusting any average.
--
-- Value-type arguments are passed by pointer and REFramework has offered more than
-- one way to read them across versions, so read_quat tries each in turn and says
-- once which one worked. A guess here would silently produce numbers, which is the
-- worst possible failure for a measurement.
-- ---------------------------------------------------------------------------

local QUAT_METHOD = nil   -- decided on the first shot, then reported once

local function read_quat(arg)
    if arg == nil then return nil end

    -- 1. the usual route for a value-type argument
    if QUAT_METHOD == nil or QUAT_METHOD == "valuetype" then
        local q = nil
        pcall(function() q = sdk.to_valuetype(arg, "via.Quaternion") end)
        if q ~= nil then
            local x, y, z, w
            pcall(function() x, y, z, w = q.x, q.y, q.z, q.w end)
            if x ~= nil and w ~= nil then
                QUAT_METHOD = "valuetype"
                return { x = x, y = y, z = z, w = w }
            end
        end
    end

    -- 2. some builds hand back something already readable
    if QUAT_METHOD == nil or QUAT_METHOD == "direct" then
        local x, y, z, w
        pcall(function() x, y, z, w = arg.x, arg.y, arg.z, arg.w end)
        if x ~= nil and w ~= nil then
            QUAT_METHOD = "direct"
            return { x = x, y = y, z = z, w = w }
        end
    end

    -- 3. a managed object wrapper
    if QUAT_METHOD == nil or QUAT_METHOD == "managed" then
        local o = nil
        pcall(function() o = sdk.to_managed_object(arg) end)
        if o ~= nil then
            local x, y, z, w
            pcall(function() x, y, z, w = o.x, o.y, o.z, o.w end)
            if x ~= nil and w ~= nil then
                QUAT_METHOD = "managed"
                return { x = x, y = y, z = z, w = w }
            end
        end
    end

    return nil
end

-- Angle between two unit quaternions, in degrees. |dot| because q and -q are the
-- same rotation, and a clamp because floating point walks outside [-1, 1].
local function quat_angle_deg(a, b)
    if a == nil or b == nil then return nil end
    local d = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
    if d < 0 then d = -d end
    if d > 1.0 then d = 1.0 end
    return 2.0 * math.acos(d) * 180.0 / math.pi
end

-- ---------------------------------------------------------------------------
-- The experiment runs itself. Every shot is filed under the state the gun was in
-- at the moment it fired, so firing some shots hip and some aimed produces the
-- A/B comparison with nobody having to keep track of which was which.
-- ---------------------------------------------------------------------------
local shots = {}   -- bucket name -> { n, sum, min, max }

-- ⚠ 2026-09-20: the first version of this bucketed by `isRestrictAimShake`, on the
-- assumption that it tracked the aim button. It does not -- it reads `true` all the
-- time, hip or aimed -- so all ten shots of the first run landed in one bucket and the
-- labels lied. The SHOT lines themselves were fine, and the comparison came from their
-- ORDER plus Tefa saying which five were which. Bucket by what WE changed instead;
-- nothing readable on the gun distinguishes aiming.
local function bucket_name()
    local on = {}
    if state.skip then on[#on + 1] = "skip" end
    if state.spec then on[#on + 1] = "spec" end
    if state.fix then on[#on + 1] = "fix" end
    if #on == 0 then return "as the game ships it" end
    return "we changed: " .. table.concat(on, "+")
end

local function file_shot(bucket, deg)
    local b = shots[bucket]
    if b == nil then
        b = { n = 0, sum = 0.0, min = nil, max = nil }
        shots[bucket] = b
    end
    b.n = b.n + 1
    if deg ~= nil then
        b.sum = b.sum + deg
        if b.min == nil or deg < b.min then b.min = deg end
        if b.max == nil or deg > b.max then b.max = deg end
    end
end

local function stats(L)
    L("---- scatter measured per shot, in degrees ----")
    if QUAT_METHOD == nil then
        L("  (the two rotations could not be read yet -- shot COUNTS below are still valid)")
    else
        L("  (rotations read by the '%s' route)", QUAT_METHOD)
    end
    local any = false
    for name, b in pairs(shots) do
        any = true
        if b.min ~= nil then
            L("  %-44s %3d shot(s)   min %.3f   avg %.3f   max %.3f",
              name, b.n, b.min, b.sum / b.n, b.max)
        else
            L("  %-44s %3d shot(s)   (no angle read)", name, b.n)
        end
    end
    if not any then L("  no shots recorded yet -- fire the rifle") end
    L("  >> a row sitting at 0.000 is a shot with NO scatter at all.")
    L("  >> compare the hip row against the aimed row: that difference IS the thing being chased.")
end




-- ---------------------------------------------------------------------------
-- THE SELF-VERIFYING WRITE.
--
-- What the 2026-09-20 trace established, and it is worth stating plainly because
-- three levers were built on guesses before it:
--   * the firing order is expendBullet -> createBullet -> createBulletImple ->
--     setupDiffusion, with shootCommon after; IDENTICAL for an aimed shot (0.000 deg)
--     and a hip shot (7.317 deg)  [verified-live 2026-09-20, n=2]
--   * the spec getters `get_diffusionRadius` / `get_isDiffusion` were NEVER CALLED --
--     not once, on either shot. So the spread is not read from the spec at shot time,
--     and that is why `spec on` did nothing. Proven, not assumed.
--   * the scatter is therefore already inside setupDiffusion's arguments, decided by
--     whatever calls it.
--
-- We can READ those arguments (the `valuetype` route works and has been right all
-- along). What failed was WRITING them -- and only one way of writing was tried:
-- reassigning the `args[n]` slot, which does not reach a value-type argument.
--
-- ⭐ So try writing THROUGH the value type instead, and make the write PROVE ITSELF:
-- measure, write, then RE-READ and measure again. If the second measurement is 0, the
-- write landed. If it still reads 8 degrees, it did not -- and we know that from the
-- log, without anyone judging where a bullet went. No more "is it working?".
--
-- ⭐ And the which-one-is-intended question is settled numerically rather than by
-- trying both: `get_muzzleJoint` gives the barrel's own rotation, so whichever of the
-- two quaternions is closer to the muzzle is the direction the rifle is pointing.
-- ---------------------------------------------------------------------------

local WRITE_METHOD = nil   -- decided on the first attempt, then reported once

-- Try each way of writing a quaternion through to the real argument. Returns the
-- name of whichever worked, or nil.
local function write_quat(arg, q)
    if arg == nil or q == nil then return nil end

    -- 1. the value type's own float writer, at the natural offsets
    local vt = nil
    pcall(function() vt = sdk.to_valuetype(arg, "via.Quaternion") end)
    if vt ~= nil then
        local ok = pcall(function()
            vt:write_float(0, q.x); vt:write_float(4, q.y)
            vt:write_float(8, q.z); vt:write_float(12, q.w)
        end)
        if ok then return "write_float" end

        -- 2. plain field assignment on the value type
        local ok2 = pcall(function() vt.x = q.x; vt.y = q.y; vt.z = q.z; vt.w = q.w end)
        if ok2 then return "field assign" end
    end

    -- 3. assignment straight on the argument
    local ok3 = pcall(function() arg.x = q.x; arg.y = q.y; arg.z = q.z; arg.w = q.w end)
    if ok3 then return "arg assign" end

    return nil
end

-- The barrel's own rotation, for telling the two quaternions apart.
local function muzzle_quat(gun)
    if gun == nil then return nil end
    local j = nil
    pcall(function() j = gun:call("get_muzzleJoint") end)
    if j == nil then return nil end
    local r = nil
    pcall(function() r = j:call("get_Rotation") end)
    if r == nil then return nil end
    local x, y, z, w
    pcall(function() x, y, z, w = r.x, r.y, r.z, r.w end)
    if x == nil or w == nil then return nil end
    return { x = x, y = y, z = z, w = w }
end

-- ---------------------------------------------------------------------------
-- TRACE -- stop guessing, watch what actually happens.
--
-- Three levers have now failed (`steady`, `zero`, `skip`/`spec`), each one a guess
-- about where the scatter is decided. The measurement, meanwhile, has never been
-- wrong. So: measure the mechanism too.
--
-- ⭐ The finding that should have stopped the guessing earlier: the two rotations
-- handed to `setupDiffusion` ALREADY differ by ~8 degrees when it is called. The
-- scatter therefore exists BEFORE that function runs -- it does not create it, it
-- receives it. Which is exactly why skipping it changed nothing, and why zeroing the
-- spec radius at the moment it is asked may be too late as well.
--
-- In the gun's method table the order is:
--     shootCommon -> gatherJoints -> expendBullet -> createBullet
--                 -> setupDiffusion -> createBulletImple
-- so the caller decides the spread. This traces that whole run, in order, and logs
-- what the spec getters actually return, for one aimed shot against one hip shot.
-- The difference between the two traces is the answer, whatever it turns out to be.
--
-- Budgeted: it stops itself after a set number of lines so it can never flood a log.
-- ---------------------------------------------------------------------------

local TRACE_PATH = { "shootCommon", "gatherJoints", "expendBullet", "createBullet", "createBulletImple" }

local function T(fmt, ...)
    if not state.trace then return end
    if state.trace_left <= 0 then
        state.trace = false
        L("trace budget spent -- trace off")
        return
    end
    state.trace_left = state.trace_left - 1
    local ok, str = pcall(string.format, fmt, ...)
    log.info(PREFIX .. "  trace| " .. (ok and str or tostring(fmt)))
end

local function hook_trace(L)
    local td = sdk.find_type_definition(CORE)
    if td == nil then return end
    for _, nm in ipairs(TRACE_PATH) do
        local m = td:get_method(nm)
        if m ~= nil then
            sdk.hook(m, function(args) T("%s", nm) end, function(r) return r end)
        else
            L("  trace: %s not found on %s", nm, CORE)
        end
    end
end

-- ---------------------------------------------------------------------------
-- LEVER 3 -- the tidiest one, and the one a shipped fix would use.
--
-- `app.ItemSpecificationData.SpecUnit.WeaponSpec.GunSpec` holds the per-weapon
-- numbers and exposes them as READ-ONLY getters: `get_isDiffusion`,
-- `get_diffusionNum`, `get_diffusionRadius` [verified-live 2026-09-17 probe].
-- A getter's RETURN VALUE can be overridden in a post-hook, which is the most
-- reliable lever REFramework offers -- no argument writing, no memory pokes.
--
-- Zero the radius at source and the cone has nothing to open into, whoever asks.
-- ⚠ This is global: every gun that asks loses its spread, not just the rifle.
-- That is fine for a test and NOT fine to ship; a shipped version filters by weapon.
-- ---------------------------------------------------------------------------
local SPEC = "app.ItemSpecificationData.SpecUnit.WeaponSpec.GunSpec"

local function hook_spec(L)
    local td = sdk.find_type_definition(SPEC)
    if td == nil then
        L("⚠ %s not in the type database -- 'zero spec' cannot work", SPEC)
        return false
    end

    local mr = td:get_method("get_diffusionRadius")
    local mb = td:get_method("get_isDiffusion")
    local mn = td:get_method("get_diffusionNum")
    L("spec getters found: radius=%s isDiffusion=%s num=%s",
      tostring(mr ~= nil), tostring(mb ~= nil), tostring(mn ~= nil))

    if mr ~= nil then
        sdk.hook(mr, function() end, function(retval)
            local was = nil
            pcall(function() was = sdk.to_float(retval) end)
            T("GunSpec.get_diffusionRadius -> %s", tostring(was))
            if state.spec then
                state.spec_hits = state.spec_hits + 1
                local ok, z = pcall(sdk.float_to_ptr, 0.0)
                if ok and z ~= nil then return z end
            end
            return retval
        end)
    end
    if mb ~= nil then
        sdk.hook(mb, function() end, function(retval)
            local was = nil
            pcall(function() was = sdk.to_int64(retval) end)
            T("GunSpec.get_isDiffusion -> %s", tostring(was))
            if state.spec then
                state.spec_hits = state.spec_hits + 1
                local ok, z = pcall(sdk.to_ptr, 0)
                if ok and z ~= nil then return z end
            end
            return retval
        end)
    end
    return (mr ~= nil or mb ~= nil)
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
                    -- ⚠ the first run could not say WHICH weapon it had hold of, which
                    -- nearly cost a finding. Name it every time.
                    local go_name = "?"
                    pcall(function()
                        local go = obj:call("get_GameObject")
                        if go == nil and obj.get_game_object ~= nil then go = obj:get_game_object() end
                        if go ~= nil then go_name = go:call("get_Name") end
                    end)
                    L("captured the gun in your hands: %s  weapon=%s  (slot args[%d], capture #%d)",
                      name, tostring(go_name), slot, state.core_seen)
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

-- ---------------------------------------------------------------------------
-- THE ZERO-SHOT TEST -- the one that needs no target, no bullets and no judgement.
--
-- `app.WeaponGunCore` also carries `get_isInputRightTrigger`, `get_isInputTrigger`
-- and `get_isForbidAim`/`set_isForbidAim` [measured 2026-09-20 from re8.exe]. So the
-- gun knows whether the trigger is held, and we can read its steadiness flags at the
-- same time.
--
-- ⭐ Which means the deciding question -- does holding aim flip `isRestrictAimShake`? --
-- can be answered by HOLDING THE AIM BUTTON AND LETTING GO. No shot is fired, no
-- ammo is used, nothing is aimed at, and nobody has to see where anything landed.
--
-- This watch prints only CHANGES, so a held-down button produces two lines, not
-- thousands. If nothing prints while the aim button is held, that is the answer too:
-- aiming does not touch these flags, and the accuracy comes from somewhere else.
-- ---------------------------------------------------------------------------

local WATCHED = {
    "isRestrictAimShake",
    "isReduceRecoil",
    "isDiffusion",
    "diffusionRadius",
    "isForbidAim",
}

-- ⛔ The per-frame flag WATCHER is removed (2026-09-20). It did its job: across three
-- aim holds and twenty-odd shots neither `isRestrictAimShake` (always true) nor
-- `isReduceRecoil` (always false) ever changed, so there is nothing left for it to see,
-- and it was doing field reads every single frame. Finding: dossier §9bc. The one-shot
-- snapshot below stays, because it is free and still worth a look.

local WATCHED = { "isRestrictAimShake", "isReduceRecoil", "isDiffusion", "diffusionRadius", "isForbidAim" }

local function read_flag(gun, name)
    local v = nil
    if not pcall(function() v = gun:get_field(name) end) then return nil end
    return v
end

local function flags_snapshot(L)
    if state.core == nil then
        L("nothing captured yet -- equip the rifle (equipping is enough, no shot needed)")
        return
    end
    L("---- the gun's steadiness flags, right now ----")
    for _, name in ipairs(WATCHED) do
        L("  %-20s = %s", name, tostring(read_flag(state.core, name)))
    end
    local trig = nil
    pcall(function() trig = state.core:call("get_isInputRightTrigger") end)
    L("  %-20s = %s", "trigger held", tostring(trig))
    L("  >> HOLD THE AIM BUTTON and watch for FLAG lines. If isRestrictAimShake flips")
    L("  >> to true, that is the accuracy you want, and we can switch it on without aiming.")
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
            local gun = capture_this(args)
            -- args: [1] context, [2] this, [3] vec3, [4] Quaternion, [5] Quaternion
            T("=== setupDiffusion (the scatter is ALREADY in its arguments) ===")
            local qa  = read_quat(args[4])
            local qb  = read_quat(args[5])
            local deg = quat_angle_deg(qa, qb)

            local restrict, reduce, isdiff, radius = nil, nil, nil, nil
            if gun ~= nil then
                pcall(function() restrict = gun:get_field("isRestrictAimShake") end)
                pcall(function() reduce   = gun:get_field("isReduceRecoil") end)
                pcall(function() isdiff   = gun:get_field("isDiffusion") end)
                pcall(function() radius   = gun:get_field("diffusionRadius") end)
            end

            local b = bucket_name()
            file_shot(b, deg)

            -- ⭐ THE FIX. Both arguments are POINTERS to quaternions, so pointing the
            -- scattered one at the intended one makes the shot leave along the aim.
            -- Done AFTER the measurement above, so the log still records the scatter
            -- the game wanted -- we can see what was cancelled, not just that it is 0.
            -- ⚠ Which of the two is "intended" is not known: on an aimed shot they are
            -- identical, so the log cannot tell them apart. `zero swap` tries the other
            -- way round. If bullets fly off at random, it is the wrong way round.
            -- ⛔ The `zero`/`swap` arg-reassignment lever lived here and is DISPROVED
            -- (2026-09-20, 10 hip shots, 8.649 deg vs 8.429 with nothing on). Removed
            -- from the working file per the code-shape rule; the write-up is in
            -- dev-archive/recon/2026-09-20-the-steady-switches-are-questions-not-switches/.
            -- ⭐ THE FIX, and it proves itself. Write the barrel's direction over the
            -- scattered one, then RE-READ and measure again: 0 means the write landed,
            -- still-8-degrees means it did not, and the log says which without anyone
            -- having to judge where a bullet went.
            if state.fix and qa ~= nil and qb ~= nil then
                local mz = muzzle_quat(gun)
                -- whichever quaternion is closer to the barrel is the one the rifle is
                -- actually pointing along; that is the one to keep.
                local keep, over, which = qa, args[5], "args[4] (closer to the muzzle)"
                if mz ~= nil then
                    local da, db = quat_angle_deg(mz, qa), quat_angle_deg(mz, qb)
                    if da ~= nil and db ~= nil and db < da then
                        keep, over, which = qb, args[4], "args[5] (closer to the muzzle)"
                    end
                    T("muzzle vs args[4] = %.3f deg, vs args[5] = %.3f deg", da or -1, db or -1)
                end

                local how = write_quat(over, keep)
                if how ~= nil and WRITE_METHOD == nil then
                    WRITE_METHOD = how
                    L("write route in use: %s", how)
                end

                local after = quat_angle_deg(read_quat(args[4]), read_quat(args[5]))
                L("  FIX  kept %s  wrote via %s  scatter after the write = %s",
                  which, tostring(how),
                  after and string.format("%.3f deg", after) or "unread")
                if after ~= nil and after > 0.5 then
                    L("  FIX  ⚠ THE WRITE DID NOT LAND -- the number did not move. Not a wrong choice, no effect.")
                end
            end

            -- LEVER 2: do not let the diffusion run at all. setupDiffusion sits between
            -- createBullet and createBulletImple in the gun's method table, so the bullet
            -- is made, then diffused, then finished -- skipping the middle step should
            -- leave it on the rotation it was made with.
            -- ⚠ If this makes the rifle stop firing, or fire somewhere fixed, the step
            -- does more than diffuse and the answer is `zero spec` instead.

            state.calls["setupDiffusion"] = (state.calls["setupDiffusion"] or 0) + 1
            local n = state.calls["setupDiffusion"]
            if not state.quiet and (n <= 12 or n % 25 == 0) then
                L("SHOT #%d  scatter=%s  restrictAimShake=%s  reduceRecoil=%s  isDiffusion=%s  diffusionRadius=%s  [%s]",
                  n,
                  deg and string.format("%.3f deg", deg) or "unread",
                  tostring(restrict), tostring(reduce), tostring(isdiff), tostring(radius), b)
            end
            if n % 10 == 0 then stats(L) end

            -- ⚠ BUG FIXED 2026-09-20: this return used to sit ABOVE the logging, so
            -- `skip on` silenced the SHOT lines and made its own test unreadable. The
            -- skip must always be the LAST thing the pre-hook does.
            if state.skip then
                return sdk.PreHookResult.SKIP_ORIGINAL
            end
        end, function(r) return r end)
    end

    -- ⭐ Capture WITHOUT firing. onEquipWeapon runs the moment the rifle is drawn, and
    -- updateScope runs while it is held, so `read` and the flag watch work straight away.
    for _, nm in ipairs({ "onEquipWeapon", "updateScope" }) do
        local m = td:get_method(nm)
        if m ~= nil then
            sdk.hook(m, function(args) capture_this(args) end, function(r) return r end)
            L("  capture hook on %s -- no shot needed to grab the gun", nm)
        else
            L("  ⚠ %s not found; capture will need a shot fired", nm)
        end
    end

    pcall(hook_spec, L)
    pcall(hook_trace, L)

    L("watching. Nothing is being changed.")
    L("EQUIP the rifle, then HOLD THE AIM BUTTON and let go. Watch for FLAG lines.")
    L("No shot is needed for that test. Firing additionally measures the scatter in degrees.")
end

-- ---------------------------------------------------------------------------
-- Applying. Re-asserted every frame on purpose: the game sets these itself on weapon
-- change and on state changes, so a one-shot write would be quietly undone and we would
-- wrongly conclude the lever does not work.
-- ---------------------------------------------------------------------------
-- ⛔ apply_steady() removed 2026-09-20: both methods take NO arguments, so there was
-- never anything to call. See dossier §9bc.

local function status()
    L("---- status ----")
    L("  gun captured : %s (%d time(s))", state.core ~= nil and "yes" or "NO -- fire once", state.core_seen)
    L("  skip         : %s", state.skip and "ON" or "off")
    L("  spec         : %s  (spec getters answered %d time(s))", state.spec and "ON" or "off", state.spec_hits)
    L("  trace        : %s  (%d line(s) of budget left)", state.trace and "ON" or "off", state.trace_left)
    L("  callable     : enableRestrictAimShake=%s  enableReduceRecoil=%s",
      tostring(state.shake_ok), tostring(state.recoil_ok))
    local any = false
    for k, v in pairs(state.calls) do L("  seen %-26s %d call(s)", k, v) any = true end
    if not any then L("  no calls seen yet -- the game has not touched any of them") end
    stats(L)
end

local function run(line)
    local cmd, arg = line:match("^%s*(%S+)%s*(.-)%s*$")
    cmd = (cmd or ""):lower()
    arg = (arg or ""):lower()

    if cmd == "read" then
        dump_live(state.core, "the gun in your hands")
    elseif cmd == "quiet" then
        state.quiet = (arg ~= "off")
        L("watch lines %s", state.quiet and "silenced" or "back on")
    elseif cmd == "fix" then
        state.fix = (arg ~= "off")
        L("fix %s -- the barrel direction is written over the scattered one, and the write",
          state.fix and "ON" or "off")
        L("     checks itself: look for the 'scatter after the write' number on each shot.")
    elseif cmd == "trace" then
        if arg == "off" then
            state.trace, state.trace_left = false, 0
            L("trace off")
        else
            state.trace, state.trace_left = true, 400
            L("trace ON, budget 400 lines. Fire ONE shot holding aim, then ONE from the hip.")
            L("The difference between the two traces is the answer.")
        end
    elseif cmd == "skip" then
        state.skip = (arg ~= "off")
        L("skip %s -- setupDiffusion %s run", state.skip and "ON" or "off",
          state.skip and "will NOT" or "runs normally")
        if state.skip then L("Fire from the HIP. If the rifle stops firing, say so and use 'spec' instead.") end
    elseif cmd == "spec" then
        state.spec = (arg ~= "off")
        state.spec_hits = 0
        if state.spec then
            L("spec ON -- the weapon spec's diffusion radius is forced to ZERO for every gun that asks")
        else
            L("spec off -- the spec answers its own numbers again")
        end
        if state.spec then L("Fire from the HIP, then run 'stats' -- the SHOT scatter itself should go to 0.000.") end
    elseif cmd == "flags" then
        flags_snapshot(L)
    elseif cmd == "stats" then
        stats(L)
    elseif cmd == "status" then
        status()
    else
        L("not understood: %s   (read / flags / fix on|off / trace on|off / skip on|off / spec on|off / stats / status)", line)
    end
end

-- ---------------------------------------------------------------------------
-- Command file + the per-frame apply. Same shape as the dig tool: consume the file
-- FIRST so a failing command cannot loop forever.
-- ---------------------------------------------------------------------------
local last_poll = 0.0

re.on_frame(function()
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
