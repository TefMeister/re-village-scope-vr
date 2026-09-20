-- re8_spread_dig.lua -- where does the sniper's bullet spread actually come from?
-- 2026-09-20. READ-ONLY. Writes nothing, hooks nothing, changes no game state.
--
-- WHY THIS EXISTS
-- The 2026-09-17 `spreadprobe` searched by NAME: it listed fields whose names looked like
-- spread / recoil / accuracy. It found nothing numeric on the weapon, and the 2026-09-18
-- aiming-vs-not diff showed exactly one field changing (`DrawOffByScope`, a draw flag).
-- Dossier conclusion: spread is not a weapon field -- it lives on the player or in the shot code.
--
-- ⚠ BUT A NAME SEARCH CANNOT FIND A FIELD THAT IS NOT CALLED WHAT YOU GUESSED.
-- If Capcom called it Dispersion, Blur, Rand, Corrective, Ratio or anything else, the old probe
-- looked straight past it. So this one takes the opposite approach: it dumps EVERY field and
-- method of a small number of types the old probe ALREADY PROVED EXIST, with no name filter,
-- and lets a human read the list.
--
-- The targets are not guesses. Every one of them appeared in the 2026-09-17 dump:
--   app.ItemSpecificationData.SpecUnit.WeaponSpec       per-weapon numbers live here
--   app.ItemSpecificationData.SpecUnit.WeaponSpec.GunSpec
--   app.BulletDefault                                   the bullet itself
--   app.PlayerActionTPS.ProcessGunAttackBase            the shot being taken
--   app.PlayerGunPl6000                                 the sniper's own gun component
--   app.PlayerCameraTPS.Sniper                          the aim state that narrows it
--
-- HOW TO RUN IT
--   Write one line into  reframework\data\re_spread_dig_cmd.txt :
--       dig all        every target below
--       dig gunspec    the weapon spec tables only
--       dig bullet     the bullet type only
--       dig shot       the firing code only
--       dig <app.Some.Type>   any type by name
--   It has its OWN command file on purpose, so it cannot race the scope harness for the
--   one the harness reads.
--
-- Output goes to the REFramework log, every line prefixed [spread-dig].

local CMD = "re_spread_dig_cmd.txt"
local PREFIX = "[spread-dig] "

local TARGETS = {
    "app.ItemSpecificationData.SpecUnit.WeaponSpec",
    "app.ItemSpecificationData.SpecUnit.WeaponSpec.GunSpec",
    "app.BulletDefault",
    "app.PlayerActionTPS.ProcessGunAttackBase",
    "app.PlayerGunPl6000",
    "app.PlayerCameraTPS.Sniper",
}

local GROUPS = {
    gunspec = { TARGETS[1], TARGETS[2] },
    bullet  = { TARGETS[3] },
    shot    = { TARGETS[4] },
    gun     = { TARGETS[5] },
    aim     = { TARGETS[6] },
}

local function L(fmt, ...)
    local ok, s = pcall(string.format, fmt, ...)
    log.info(PREFIX .. (ok and s or tostring(fmt)))
end

-- Numeric-looking types are what a spread value would be. Flagged with >> so the
-- interesting lines can be found without reading all of it.
local NUMERIC = {
    ["System.Single"] = true, ["System.Double"] = true,
    ["System.Int32"] = true, ["System.UInt32"] = true,
    ["System.Int16"] = true, ["System.UInt16"] = true,
    ["System.Byte"] = true, ["System.SByte"] = true,
    ["via.vec2"] = true, ["via.vec3"] = true, ["via.Range"] = true,
}

local function dump_type(name)
    local td = sdk.find_type_definition(name)
    if not td then
        L("%s -- NOT in the type database", name)
        return
    end

    local parent = "?"
    pcall(function()
        local p = td:get_parent_type()
        parent = p and p:get_full_name() or "(none)"
    end)
    L("================ %s   (parent %s)", name, parent)

    local fields, nnum = {}, 0
    pcall(function() fields = td:get_fields() end)
    L("  -- %d fields --", #fields)
    for _, f in ipairs(fields) do
        local ft, fn, off = "?", "?", -1
        pcall(function() ft = f:get_type():get_full_name() end)
        pcall(function() fn = f:get_name() end)
        pcall(function() off = f:get_offset_from_base() end)
        local mark = NUMERIC[ft] and ">>" or "  "
        if NUMERIC[ft] then nnum = nnum + 1 end
        L("  %s field %-40s %-24s @0x%x%s", mark, fn, ft, off, f:is_static() and " static" or "")
    end

    local methods = {}
    pcall(function() methods = td:get_methods() end)
    L("  -- %d methods --", #methods)
    for _, m in ipairs(methods) do
        local mn, ret, ps = "?", "?", {}
        pcall(function() mn = m:get_name() end)
        pcall(function() ret = m:get_return_type():get_full_name() end)
        pcall(function()
            for _, p in ipairs(m:get_param_types()) do ps[#ps + 1] = p:get_full_name() end
        end)
        L("     method %s(%s) -> %s", mn, table.concat(ps, ", "), ret)
    end

    L("  >> %d of %d fields are numeric -- a spread value would be one of those", nnum, #fields)
end


-- ---------------------------------------------------------------------------
-- `spec` -- try to reach the weapon SPEC TABLE without needing a weapon in hand.
-- app.ItemSpecificationData is a via.UserData holding SpecUnits + findSpec(uint).
-- A UserData is not a singleton, so something must own it. This tries the managers
-- that plausibly do, reports which exist, and walks the list if one hands it over.
-- Read-only. Prints the Diffusion numbers per gun if it gets that far.
-- ---------------------------------------------------------------------------
local OWNERS = {
    "app.ItemManager", "app.ItemSpecificationManager", "app.WeaponManager",
    "app.PlayerManager", "app.GameDataManager", "app.ItemDataManager",
    "app.InventoryManager", "app.EquipmentManager",
}

local function try_spec()
    L("---- looking for whoever owns app.ItemSpecificationData ----")
    local found = {}
    for _, name in ipairs(OWNERS) do
        local td = sdk.find_type_definition(name)
        if td then
            local inst = nil
            pcall(function() inst = sdk.get_managed_singleton(name) end)
            L("  %-34s type EXISTS, singleton %s", name, inst and "PRESENT" or "nil")
            if inst then found[#found + 1] = { name = name, inst = inst, td = td } end
        else
            L("  %-34s no such type", name)
        end
    end
    if #found == 0 then
        L("  none of those hand one over. The spec table is reachable some other way;")
        L("  the fallback is to read it off the EQUIPPED weapon, which needs gameplay.")
        return
    end
    for _, o in ipairs(found) do
        L("  -- fields of the live %s that look like spec data --", o.name)
        for _, f in ipairs(o.td:get_fields()) do
            local ft = "?"
            pcall(function() ft = f:get_type():get_full_name() end)
            if ft:find("ItemSpecificationData") or f:get_name():lower():find("spec") then
                L("     >> %s : %s", f:get_name(), ft)
            end
        end
    end
end

local function run(arg)
    local list
    if arg == "spec" then
        local ok, err = pcall(try_spec)
        if not ok then L("spec failed: %s", tostring(err)) end
        return
    end
    if arg == nil or arg == "" or arg == "all" then
        list = TARGETS
    elseif GROUPS[arg] then
        list = GROUPS[arg]
    else
        list = { arg }   -- a type name typed by hand
    end

    L("==== dig START (%d target(s)) ====", #list)
    L("read-only: nothing is written, hooked or changed")
    for _, t in ipairs(list) do
        local ok, err = pcall(dump_type, t)
        if not ok then L("%s -- dump FAILED: %s", t, tostring(err)) end
    end
    L("==== dig DONE. Numeric fields are marked >> ====")
    L("NOTE: a field existing is not a field being USED. Anything promising still has to be")
    L("      watched or written live before it can be called the cause.")
end

-- ---------------------------------------------------------------------------
-- Command file. Same shape as the scope harness (fs.read / fs.write, relative to
-- reframework/data/, polled on a timer, consumed by writing it empty). REFramework
-- sandboxes Lua -- there is no `io` library -- so this is the only way that works.
-- Its OWN file, so it cannot race the harness for the one the harness reads.
-- ---------------------------------------------------------------------------
local last_poll = 0.0

re.on_frame(function()
    local now = os.clock()
    if now - last_poll < 0.5 then return end
    last_poll = now

    local ok, raw = pcall(fs.read, CMD)
    if not ok or raw == nil or raw == "" then return end
    pcall(fs.write, CMD, "")   -- consume it FIRST, so a failure cannot loop forever

    for line in tostring(raw):gmatch("[^\r\n]+") do
        if line:match("%S") then
            local cmd, arg = line:match("^%s*(%S+)%s*(.-)%s*$")
            if cmd == "dig" then
                local ran, err = pcall(run, arg)
                if not ran then L("dig failed: %s", tostring(err)) end
            else
                L("ignored (only 'dig ...' is understood here): %s", line)
            end
        end
    end
end)

L("loaded. Write 'dig all' into reframework/data/%s to run it.", CMD)
