-- re8_scope_m6_mirror_producer.lua — M6: via.render.Mirror as the PRODUCER,
-- the scope glass as the DISPLAY.
--
-- Why this is worth one more shot after Mirror was called a dead end (dev PC,
-- 2026-08-24): both stated reasons for that verdict have since been falsified by
-- this project's own later findings.
--   (a) "a Lua-created RT never gets real GPU backing" — overturned the same day.
--       The native D3D12 hook proved create_resource() really does allocate:
--       1280x728, R8G8B8A8_UNORM_SRGB, ALLOW_RENDER_TARGET.
--   (b) The way Mirror's failure was judged was "41 GUI elements redirected to
--       its RT, zero visible change" — but via.gui.GUI.set_RenderTarget was later
--       shown to mean "renders INTO", not "displays FROM". Mirror was tested as a
--       producer through a broken display path.
-- So Mirror was never actually given a working display. It has one now: as of
-- 2026-08-24 (home PC) the plugin proved setMaterialTexture on the rifle's own
-- Lens_Mat/Lens2_Mat slot 1 puts our pixels on the glass, live, confirmed by F9
-- changing the reticle on the glass in real gameplay.
--
-- This script does NOT touch the plugin. The plugin keeps writing its own
-- backbuffer-crop image into its own latched resource; we simply point the glass
-- at a DIFFERENT holder that Mirror produces into, and compare.
--
-- What we're looking for: the glass showing the SCENE (geometry, the room,
-- parallax as you move) rather than a flat crop of the backbuffer. That would be
-- a genuine second-camera render — correct in VR, no mirror/feedback, and the end
-- of the content problem.
--
-- SAFETY: every material write is saved and restorable ("Restore glass" button).
-- Nothing here is automatic; all of it is behind buttons in the REFramework menu.
-- All code ours.

local function safe(fn)
    local ok, r = pcall(fn)
    if not ok then return nil, tostring(r) end
    return r, nil
end

local function L(s) log.info("[m6_mirror] " .. tostring(s)) end
local function E(s) log.error("[m6_mirror] " .. tostring(s)) end

local st = {
    holder   = nil,   -- our RenderTargetTextureResourceHolder
    res      = nil,
    mirror   = nil,   -- the via.render.Mirror component
    mirror_go = nil,
    saved    = {},    -- { {mesh=, mi=, ti=, orig=} } — for restore
    status   = "idle",
    api_dumped = false,
}

-- ---------------------------------------------------------------------------
-- scene / weapon resolution
-- ---------------------------------------------------------------------------

local function current_scene()
    return safe(function()
        local sm  = sdk.get_native_singleton("via.SceneManager")
        local smt = sdk.find_type_definition("via.SceneManager")
        return sdk.call_native_func(sm, smt, "get_CurrentScene")
    end)
end

-- Find the rifle by NAME, not through the player chain.
--
-- v1 of this script walked PropsManager -> Player -> PlayerUpdater -> playerGun
-- -> equipWeaponObject, and died on "no PlayerUpdater": the native plugin only
-- survives that chain because it falls back to app.PlayerUpdaterFPS when
-- app.PlayerUpdater doesn't resolve, and that fallback wasn't carried over here.
--
-- Rather than re-copy a five-link chain that can break at any link, look the
-- rifle up directly: we already know its GameObject is named "ri3042_Inventory"
-- (weapon recon, 2026-08-23). This enumeration is READ-ONLY -- it reads names and
-- returns one match. It is not the scene-wide *write* that caused the 08-24
-- failure; nothing is mutated here.
local function find_rifle()
    local scene = current_scene()
    if scene ~= nil then
        local list = safe(function()
            return scene:call("findComponents(System.Type)", sdk.typeof("via.render.Mesh"))
        end)
        if list ~= nil then
            local n = safe(function() return list:call("get_Count") end) or 0
            for i = 0, n - 1 do
                local mesh = safe(function() return list:call("get_Item(System.Int32)", i) end)
                local go   = mesh and safe(function() return mesh:call("get_GameObject") end)
                local nm   = go and safe(function() return go:call("get_Name") end)
                if nm ~= nil and tostring(nm):find("ri3042", 1, true) == 1 then
                    return go, mesh, nil
                end
            end
            L("find_rifle: scanned " .. n .. " meshes, no GameObject named ri3042*")
        end
    end

    -- Fallback: the player chain, this time with BOTH updater type names.
    local pm = safe(function() return sdk.get_managed_singleton("app.PropsManager") end)
    if pm == nil then return nil, nil, "no PropsManager (and no ri3042 mesh in scene)" end
    local player = safe(function() return pm:get_field("<Player>k__BackingField") end)
    if player == nil then return nil, nil, "no Player" end

    local upd = nil
    for _, tn in ipairs({ "app.PlayerUpdater", "app.PlayerUpdaterFPS" }) do
        local t = safe(function() return sdk.typeof(tn) end)
        if t ~= nil then
            upd = safe(function() return player:call("getComponent(System.Type)", t) end)
            if upd ~= nil then L("find_rifle: resolved updater as " .. tn) break end
        end
    end
    if upd == nil then return nil, nil, "no PlayerUpdater / PlayerUpdaterFPS" end

    local gun = safe(function() return upd:call("get_playerGun") end)
    if gun == nil then return nil, nil, "no playerGun" end
    local w = safe(function() return gun:call("get_equipWeaponObject") end)
    if w == nil then return nil, nil, "no equipWeaponObject" end

    local go = safe(function() return w:call("get_GameObject") end)
    if go == nil then go = safe(function() return w:get_field("<owner>k__BackingField") end) end
    if go == nil then return nil, nil, "weapon has no GameObject/owner" end

    local comps = safe(function() return go:call("get_Components") end)
    local n = comps and (safe(function() return comps:call("get_Count") end) or 0) or 0
    for i = 0, n - 1 do
        local c = safe(function() return comps:call("get_Item(System.Int32)", i) end)
        local tn = c and safe(function() return c:get_type_definition():get_full_name() end)
        if tn == "via.render.Mesh" then return go, c, nil end
    end
    return go, nil, "rifle found but it has no via.render.Mesh"
end

-- ---------------------------------------------------------------------------
-- 1. API dump — we need registerScene's EXACT overload before calling it.
--    (dev PC lesson: createComponent's naive "(System.Type)" guess threw; the
--    reflected signature had to be used verbatim.)
-- ---------------------------------------------------------------------------

local function dump_type_api(type_name)
    local td = safe(function() return sdk.find_type_definition(type_name) end)
    if td == nil then E(type_name .. ": TYPE NOT FOUND") return end
    L("==== " .. type_name .. " ====")
    local methods = safe(function() return td:get_methods() end) or {}
    for _, m in ipairs(methods) do
        local name = safe(function() return m:get_name() end) or "?"
        local nret = safe(function() return m:get_return_type():get_full_name() end) or "?"
        local ptypes = safe(function() return m:get_param_types() end) or {}
        local parts = {}
        for _, p in ipairs(ptypes) do
            parts[#parts + 1] = (safe(function() return p:get_full_name() end) or "?")
        end
        L(string.format("  %s %s(%s)", nret, name, table.concat(parts, ", ")))
    end
end

local function dump_mirror_api()
    dump_type_api("via.render.Mirror")
    -- createComponent's real signature lives on via.GameObject; we need it exact.
    local td = safe(function() return sdk.find_type_definition("via.GameObject") end)
    if td ~= nil then
        L("==== via.GameObject: createComponent overloads ====")
        for _, m in ipairs(safe(function() return td:get_methods() end) or {}) do
            local name = safe(function() return m:get_name() end) or ""
            if name:find("reateComponent") then
                local ptypes = safe(function() return m:get_param_types() end) or {}
                local parts = {}
                for _, p in ipairs(ptypes) do
                    parts[#parts + 1] = (safe(function() return p:get_full_name() end) or "?")
                end
                L(string.format("  %s(%s)", name, table.concat(parts, ", ")))
            end
        end
    end
    st.api_dumped = true
    L("API dump complete — read the [m6_mirror] lines above for registerScene's exact parameter types.")
end

-- Mirror renders a PLANAR REFLECTION: the image arrives mirrored (hence upside
-- down on the glass) and everything behind the mirror plane is clipped (hence the
-- grey half). To aim it down the bore instead we need whatever controls its
-- plane/normal/offset/clip — none of which showed up in the method dump, so walk
-- the whole parent chain for fields AND inherited methods, with live values.
local function dump_mirror_internals()
    local td = safe(function() return sdk.find_type_definition("via.render.Mirror") end)
    local depth = 0
    while td ~= nil and depth < 8 do
        local tn = safe(function() return td:get_full_name() end) or "?"
        L("==== " .. tn .. " : FIELDS ====")
        for _, f in ipairs(safe(function() return td:get_fields() end) or {}) do
            local n  = safe(function() return f:get_name() end) or "?"
            local ft = safe(function() return f:get_type():get_full_name() end) or "?"
            local v  = "n/a"
            if st.mirror ~= nil then
                v = tostring(safe(function() return st.mirror:get_field(n) end))
            end
            L(string.format("  %s %s = %s", ft, n, v))
        end

        if depth > 0 then
            L("---- " .. tn .. " : inherited methods (transform/plane/clip/fov-ish) ----")
            for _, m in ipairs(safe(function() return td:get_methods() end) or {}) do
                local name = safe(function() return m:get_name() end) or ""
                local low  = name:lower()
                if low:find("plane") or low:find("normal") or low:find("clip") or
                   low:find("fov") or low:find("transform") or low:find("offset") or
                   low:find("gameobject") or low:find("enable") then
                    local ptypes = safe(function() return m:get_param_types() end) or {}
                    local parts = {}
                    for _, p in ipairs(ptypes) do
                        parts[#parts + 1] = (safe(function() return p:get_full_name() end) or "?")
                    end
                    L(string.format("  %s(%s)", name, table.concat(parts, ", ")))
                end
            end
        end

        td = safe(function() return td:get_parent_type() end)
        depth = depth + 1
    end
    L("internals dump complete")
end

-- The plugin's numpad+ TDB scan (2026-08-24) found EIGHT types exposing
-- set_RenderTarget, not the two this project had been assuming. Most are
-- special-purpose (Bloodshed/Stamp = blood and decal splatting, Wrinkle = face
-- wrinkle maps, TextureSpreader = texture distribution). The interesting ones:
--
--   via.render.RenderOutput        -- the engine's own name for "where a view
--                                     gets rendered". If this derives from
--                                     via.Component we can attach it to a
--                                     GameObject like we did the Mirror -- and
--                                     an OUTPUT doesn't reflect or clip the way
--                                     a planar mirror must.
--   via.render.RenderTargetOperator -- generic-sounding RT operation.
--
-- The decisive question for each is the PARENT CHAIN: anything deriving from
-- via.Component is attachable to a GameObject; anything that isn't has to be
-- obtained from somewhere that already owns one.
local RT_CANDIDATES = {
    "via.render.RenderOutput",
    "via.render.RenderTargetOperator",
    "via.render.TextureSpreader",
    "via.gui.ImageFilter",
}

local function dump_candidates()
    local scene = current_scene()
    for _, tn in ipairs(RT_CANDIDATES) do
        local td = safe(function() return sdk.find_type_definition(tn) end)
        if td == nil then
            E(tn .. ": TYPE NOT FOUND")
        else
            -- Parent chain first: this is what tells us if it's attachable.
            local chain, t, guard = {}, td, 0
            while t ~= nil and guard < 8 do
                chain[#chain + 1] = safe(function() return t:get_full_name() end) or "?"
                t = safe(function() return t:get_parent_type() end)
                guard = guard + 1
            end
            local is_component = false
            for _, c in ipairs(chain) do if c == "via.Component" then is_component = true end end

            L("==== " .. tn .. " ====")
            L("  chain: " .. table.concat(chain, " -> "))
            L("  ATTACHABLE TO A GAMEOBJECT: " .. tostring(is_component))

            -- How many already exist in the scene? A live one we can inspect
            -- beats a type we can only guess at.
            if scene ~= nil and is_component then
                local list = safe(function()
                    return scene:call("findComponents(System.Type)", sdk.typeof(tn))
                end)
                local n = list and (safe(function() return list:call("get_Count") end) or 0) or 0
                L("  live instances in scene: " .. tostring(n))
            end

            L("  -- methods --")
            for _, m in ipairs(safe(function() return td:get_methods() end) or {}) do
                local name = safe(function() return m:get_name() end) or "?"
                local ret  = safe(function() return m:get_return_type():get_full_name() end) or "?"
                local ptypes = safe(function() return m:get_param_types() end) or {}
                local parts = {}
                for _, p in ipairs(ptypes) do
                    parts[#parts + 1] = (safe(function() return p:get_full_name() end) or "?")
                end
                L(string.format("    %s %s(%s)", ret, name, table.concat(parts, ", ")))
            end

            L("  -- fields --")
            local any_field = false
            for _, f in ipairs(safe(function() return td:get_fields() end) or {}) do
                local n2 = safe(function() return f:get_name() end) or "?"
                local ft = safe(function() return f:get_type():get_full_name() end) or "?"
                L(string.format("    %s %s", ft, n2))
                any_field = true
            end
            if not any_field then L("    (none)") end
        end
    end
    L("candidate dump complete")
end

-- via.render.RenderOutput is a via.Component (so we can attach one), it has real
-- controls where Mirror had none -- crucially set_Clipplane/set_ClipingEnable,
-- i.e. the clipping that a planar mirror forces on us is OPTIONAL here -- and the
-- scene already contains exactly ONE live instance: the game's own main view.
--
-- Before creating a second one, read the working example. A RenderOutput almost
-- certainly does not define a viewpoint by itself; it is the "where does this
-- view go" half, paired with a via.Camera that is the "what does it see" half.
-- The sibling-component list on the live one settles that, and its RenderOutputID
-- tells us which value NOT to collide with (colliding could hijack the main view).
--
-- Read-only: reads settings and component names, changes nothing.
local function inspect_live_renderoutput()
    local scene = current_scene()
    if scene == nil then E("no current scene") return end
    local list = safe(function()
        return scene:call("findComponents(System.Type)", sdk.typeof("via.render.RenderOutput"))
    end)
    local n = list and (safe(function() return list:call("get_Count") end) or 0) or 0
    L("live RenderOutput count: " .. tostring(n))

    for i = 0, n - 1 do
        local ro = safe(function() return list:call("get_Item(System.Int32)", i) end)
        if ro ~= nil then
            local go   = safe(function() return ro:call("get_GameObject") end)
            local name = go and safe(function() return go:call("get_Name") end)
            L(string.format("==== RenderOutput #%d  on GameObject '%s' ====", i, tostring(name)))

            for _, getter in ipairs({
                "getOutputType", "getRenderMode", "get_RenderOutputID",
                "get_ImageQuality", "get_HorizontalScreenScale", "get_Cutscene",
                "get_ClipingEnable", "get_UseCustomSceneLayer", "get_ManualAspectUse",
                "get_Interleave", "get_RenderModeChangable", "get_DistortionType",
            }) do
                L("   " .. getter .. " = " ..
                  tostring(safe(function() return ro:call(getter) end)))
            end
            L("   get_RenderTarget = " ..
              tostring(safe(function() return ro:call("get_RenderTarget") end)))

            -- THE important part: what else lives on this GameObject? Whatever a
            -- working RenderOutput is paired with is what we must reproduce.
            L("   -- sibling components on the same GameObject --")
            local comps = go and safe(function() return go:call("get_Components") end)
            local cn = comps and (safe(function() return comps:call("get_Count") end) or 0) or 0
            for c = 0, cn - 1 do
                local comp = safe(function() return comps:call("get_Item(System.Int32)", c) end)
                local tn = comp and safe(function() return comp:get_type_definition():get_full_name() end)
                L("     " .. tostring(tn))
            end
        end
    end
    L("live RenderOutput inspection complete")
end


-- ---------------------------------------------------------------------------
-- 2. Our own render target (Lua-created; the D3D12 hook proved these are real)
-- ---------------------------------------------------------------------------

local function make_holder()
    if st.holder ~= nil then return true end
    local res = safe(function()
        return sdk.create_resource("via.render.RenderTargetTextureResource",
                                   "movie/rtex/movie_1280_720.rtex")
    end)
    if res == nil then E("create_resource failed") return false end
    safe(function() res:add_ref() end)
    local holder = safe(function()
        return res:create_holder("via.render.RenderTargetTextureResourceHolder")
    end)
    if holder == nil then E("create_holder failed") return false end
    safe(function() holder:add_ref() end)
    st.res, st.holder = res, holder
    L("holder ready: " .. tostring(safe(function() return holder:call("get_ResourcePath") end)))
    return true
end

-- ---------------------------------------------------------------------------
-- 3. Attach a Mirror and point it at our RT
-- ---------------------------------------------------------------------------

-- registerScene wants via.render.layer.Scene -- a RENDER LAYER, not the game
-- scene get_CurrentScene() returns. (v1 of this script would have passed a
-- via.Scene and thrown; the API dump caught it.) We don't know the accessor's
-- name for certain, so try the plausible ones and report which worked.
local function find_scene_layer()
    local lt = safe(function() return sdk.typeof("via.render.layer.Scene") end)
    if lt == nil then E("typeof(via.render.layer.Scene) failed") return nil end

    local sv = safe(function()
        local sm  = sdk.get_native_singleton("via.SceneManager")
        local smt = sdk.find_type_definition("via.SceneManager")
        return sdk.call_native_func(sm, smt, "get_MainView")
    end)
    if sv == nil then E("no MainView") return nil end

    for _, mname in ipairs({
        "get_RenderLayer(System.Type)", "getRenderLayer(System.Type)",
        "findRenderLayer(System.Type)", "get_Layer(System.Type)",
    }) do
        local r = safe(function() return sv:call(mname, lt) end)
        if r ~= nil then
            L("scene layer found via via.SceneView:" .. mname)
            return r
        end
    end

    -- Nothing matched: dump what SceneView actually offers so the next round is
    -- informed rather than another guess.
    E("no known accessor returned a via.render.layer.Scene -- dumping via.SceneView layer methods:")
    local td = safe(function() return sdk.find_type_definition("via.SceneView") end)
    for _, m in ipairs((td and safe(function() return td:get_methods() end)) or {}) do
        local name = safe(function() return m:get_name() end) or ""
        if name:lower():find("layer") or name:lower():find("render") then
            local ptypes = safe(function() return m:get_param_types() end) or {}
            local parts = {}
            for _, p in ipairs(ptypes) do
                parts[#parts + 1] = (safe(function() return p:get_full_name() end) or "?")
            end
            L(string.format("  SceneView.%s(%s)", name, table.concat(parts, ", ")))
        end
    end
    return nil
end

local function attach_mirror()
    if not make_holder() then st.status = "holder failed" return end

    -- Host the Mirror on the rifle itself: its transform is already at the scope,
    -- already aimed down the bore, and already moving with the weapon. If Mirror
    -- renders from its own GameObject's transform, that is exactly the scope axis.
    local go, _mesh, err = find_rifle()
    if go == nil then E("attach: " .. tostring(err)) st.status = "no rifle" return end
    L("attach: rifle GameObject = " .. tostring(safe(function() return go:call("get_Name") end)))

    if st.mirror == nil then
        local mtype = safe(function() return sdk.typeof("via.render.Mirror") end)
        if mtype == nil then E("typeof(via.render.Mirror) failed") st.status = "no type" return end

        -- Reuse an existing Mirror before creating one. A Reset Scripts drops our
        -- Lua reference but the component itself survives on the rifle, so a naive
        -- re-attach would stack a second Mirror on every script reload.
        local existing = safe(function() return go:call("getComponent(System.Type)", mtype) end)
        if existing ~= nil then
            st.mirror, st.mirror_go = existing, go
            L("reusing the via.render.Mirror already on the rifle (survived a script reload)")
        end
    end

    if st.mirror == nil then
        local mtype = safe(function() return sdk.typeof("via.render.Mirror") end)
        local m, cerr = safe(function() return go:call("createComponent(System.Type)", mtype) end)
        if m == nil then
            E("createComponent(via.render.Mirror) failed: " .. tostring(cerr))
            st.status = "createComponent failed"
            return
        end
        st.mirror, st.mirror_go = m, go
        L("Mirror component created on the rifle GameObject")
    end

    -- This one we know is type-correct straight from the dump:
    --   set_RenderTarget(via.render.RenderTargetTextureResourceHolder)
    local ok_rt, rterr = safe(function() st.mirror:call("set_RenderTarget", st.holder) return true end)
    L("set_RenderTarget(our holder) -> " .. tostring(ok_rt) .. (rterr and (" [" .. rterr .. "]") or ""))

    -- registerScene is what should make it actually RENDER something. If we can't
    -- resolve a render layer we still leave the Mirror attached and targeted --
    -- worth seeing whether set_RenderTarget alone produces anything on the glass.
    local layer = find_scene_layer()
    if layer ~= nil then
        local ok_rs, rserr = safe(function()
            st.mirror:call("registerScene(via.render.layer.Scene, via.render.layer.Scene)", layer, layer)
            return true
        end)
        L("registerScene(layer, layer) -> " .. tostring(ok_rs) .. (rserr and (" [" .. rserr .. "]") or ""))
        local reg = safe(function() return st.mirror:call("isRegisteredScene", layer) end)
        L("isRegisteredScene -> " .. tostring(reg))
        st.layer = layer
        st.status = "mirror attached + registered"
    else
        L("registerScene SKIPPED (no render layer resolved) -- testing set_RenderTarget alone")
        st.status = "mirror attached, not registered"
    end

    L("Mirror Visible=" .. tostring(safe(function() return st.mirror:call("get_Visible") end)) ..
      " LightWeightMode=" .. tostring(safe(function() return st.mirror:call("get_LightWeightMode") end)))
end

-- ---------------------------------------------------------------------------
-- 4. Point the glass at MIRROR's render target (saving originals first)
-- ---------------------------------------------------------------------------

local function bind_glass()
    if st.holder == nil then E("no holder — attach the Mirror first") return end
    local _go, mesh, err = find_rifle()
    if mesh == nil then E("bind: " .. tostring(err)) st.status = "no mesh" return end

    local mn = safe(function() return mesh:call("get_MaterialNum") end) or 0
    local bound = 0
    for mi = 0, mn - 1 do
        local name = safe(function() return mesh:call("getMaterialName", mi) end)
        if name ~= nil and tostring(name):find("Lens") then
            -- Save the CURRENT texture before overwriting (this may be the
            -- plugin's holder rather than stock — that's fine, we put back
            -- whatever was actually there).
            local orig = safe(function() return mesh:call("getMaterialTexture", mi, 1) end)
            if orig == nil then
                E(string.format("  material[%d] slot 1: cannot read original, SKIPPING", mi))
            else
                safe(function() orig:add_ref() end)
                st.saved[#st.saved + 1] = { mesh = mesh, mi = mi, ti = 1, orig = orig }
                local ok = safe(function() mesh:call("setMaterialTexture", mi, 1, st.holder) return true end)
                L(string.format("  BOUND material[%d] (%s) slot 1 -> Mirror RT (%s)",
                    mi, tostring(name), tostring(ok)))
                bound = bound + 1
            end
        end
    end
    L(bound .. " lens slot(s) now showing MIRROR's render target. LOOK AT THE GLASS.")
    st.status = bound > 0 and "glass -> mirror" or "nothing bound"
end

local function restore_glass()
    local n = 0
    for i = #st.saved, 1, -1 do
        local s = st.saved[i]
        if s.mesh ~= nil and s.orig ~= nil then
            safe(function() s.mesh:call("setMaterialTexture", s.mi, s.ti, s.orig) end)
            n = n + 1
        end
        st.saved[i] = nil
    end
    L("restored " .. n .. " lens slot(s) to what they held before this script touched them")
    st.status = "restored"
end

local function unregister_mirror()
    if st.mirror == nil then L("no mirror to unregister") return end
    if st.layer == nil then L("mirror was never registered to a layer") return end
    local ok = safe(function() st.mirror:call("unregisterScene", st.layer) return true end)
    L("unregisterScene -> " .. tostring(ok))
    st.layer = nil
    st.status = "mirror unregistered"
end

-- ---------------------------------------------------------------------------
-- UI — everything behind a button. Nothing on this page runs by itself.
-- ---------------------------------------------------------------------------

-- NOTE (2026-08-25): this block MUST stay below make_holder()/find_rifle().
-- It originally sat above make_holder, and Lua resolved that name to a global
-- (nil) at compile time, so button 7 threw "attempt to call a nil value" before
-- reaching a single log line. `local function f` only enters scope from its own
-- line downwards -- definition order is load order in Lua.

-- ---------------------------------------------------------------------------
-- M7: build a real second view. The live inspection gave us the recipe straight
-- off the game's own MainCamera GameObject:
--     via.Transform  (where it is / which way it faces)
--     via.Camera     (what it sees -- FOV, near/far)
--     via.render.RenderOutput  (where the picture goes)
-- ...followed by ~40 optional post-process components we do not need.
--
-- Two numbers from that inspection drive the safety here:
--   get_RenderOutputID = 1  -> the MAIN VIEW owns ID 1. Ours must not be 1.
--   get_RenderTarget   = nil -> the main view has NO render target, because it
--                               draws to the screen. Setting one is therefore
--                               exactly how a view gets diverted into a texture.
--
-- Split into two steps on purpose. Step 7 adds only the RenderOutput -- no new
-- camera enters the scene, so the blast radius is small. Step 8 adds the
-- via.Camera, which is the genuinely risky one: a second camera in a live scene
-- could in principle be picked up as the view. Do 7 first, read the log, then 8.
-- ---------------------------------------------------------------------------

local OUR_OUTPUT_ID = 2   -- must differ from the main view's 1

-- 2026-08-25: creating a via.Camera in a live scene got it promoted to the
-- scene's PRIMARY camera, so the main view rendered from the rifle -- viewpoint
-- inside Ethan's hands, weapon "gone" because we were looking out of it.
--
-- An earlier dump of via.SceneView filtered method names for "layer"/"render",
-- which hid get_PrimaryCamera (it contains neither). Dump the lot this time --
-- filtering a list before you know what you are looking for is how you miss the
-- one entry that mattered.
local function main_view()
    return safe(function()
        local sm  = sdk.get_native_singleton("via.SceneManager")
        local smt = sdk.find_type_definition("via.SceneManager")
        return sdk.call_native_func(sm, smt, "get_MainView")
    end)
end

local function dump_sceneview_api()
    for _, tn in ipairs({ "via.SceneView", "via.Scene", "via.Camera" }) do
        dump_type_api(tn)
    end
    local sv = main_view()
    if sv ~= nil then
        L("live MainView primary camera = " ..
          tostring(safe(function() return sv:call("get_PrimaryCamera") end)))
    end
end

-- CORRECTION (2026-08-25): this cannot work, and saying it could was wrong.
-- The unfiltered dump shows via.SceneView exposes:
--     via.Camera get_PrimaryCamera()     <- getter ONLY
-- There is NO set_PrimaryCamera. The primary camera slot is read-only from here,
-- so nothing can hand it back once the engine has promoted a new camera. A game
-- restart is the only way out of a takeover. Kept as a button purely so it says
-- that honestly rather than looking like an option that failed.
--
-- The real lever is elsewhere: via.Camera exposes set_CameraType(via.CameraType)
-- and set_DebugCamera(bool). Promotion is far more likely decided by what KIND of
-- camera it is than by any slot we can assign, so the fix is to never BE promoted
-- rather than to undo it afterwards.
local function restore_primary_camera()
    local sv = main_view()
    if sv == nil then E("no MainView") return end
    E("via.SceneView has get_PrimaryCamera but NO set_PrimaryCamera -- the slot is")
    E("read-only. A takeover cannot be undone from here; restart the game.")
    L("current primary = " .. tostring(safe(function() return sv:call("get_PrimaryCamera") end)))
    L("saved original  = " .. tostring(st.orig_primary))
end

-- What KINDS of camera exist? Enum constants live as static fields on the enum
-- type. If the main camera is (say) type 0 and some other value means
-- "secondary/reflection/debug", that value is how ours stays out of the primary
-- slot entirely.
local function dump_camera_types()
    local td = safe(function() return sdk.find_type_definition("via.CameraType") end)
    if td == nil then E("via.CameraType not found") return end
    L("==== via.CameraType constants ====")
    for _, f in ipairs(safe(function() return td:get_fields() end) or {}) do
        local n = safe(function() return f:get_name() end) or "?"
        local v = safe(function() return f:get_data(nil) end)
        L(string.format("  %s = %s", n, tostring(v)))
    end
    local sv = main_view()
    local cam = sv and safe(function() return sv:call("get_PrimaryCamera") end)
    if cam ~= nil then
        L("MainCamera get_CameraType    = " .. tostring(safe(function() return cam:call("get_CameraType") end)))
        L("MainCamera get_DebugCamera   = " .. tostring(safe(function() return cam:call("get_DebugCamera") end)))
        L("MainCamera get_FOV           = " .. tostring(safe(function() return cam:call("get_FOV") end)))
        L("MainCamera get_NearClipPlane = " .. tostring(safe(function() return cam:call("get_NearClipPlane") end)))
        L("MainCamera get_FarClipPlane  = " .. tostring(safe(function() return cam:call("get_FarClipPlane") end)))
    end
    if sv ~= nil then
        L("SceneView get_CameraType = " .. tostring(safe(function() return sv:call("get_CameraType") end)))
    end

    -- CENSUS (user's question, 2026-08-25: "doesn't that mean we take something
    -- else's place?"). Setting a TYPE is a label on our own camera, not a slot we
    -- evict anyone from -- but a type can still be a GROUP the engine acts on, and
    -- joining a busy group is its own kind of interference. So don't reason about
    -- it: count who already uses each type, and pick one nothing else is using.
    local scene = current_scene()
    local list = scene and safe(function()
        return scene:call("findComponents(System.Type)", sdk.typeof("via.Camera"))
    end)
    local n = list and (safe(function() return list:call("get_Count") end) or 0) or 0
    L("==== cameras alive in this scene: " .. tostring(n) .. " ====")
    local tally = {}
    for i = 0, n - 1 do
        local c  = safe(function() return list:call("get_Item(System.Int32)", i) end)
        local go = c and safe(function() return c:call("get_GameObject") end)
        local nm = go and safe(function() return go:call("get_Name") end)
        local ct = c and safe(function() return c:call("get_CameraType") end)
        local dbg = c and safe(function() return c:call("get_DebugCamera") end)
        local key = tostring(ct)
        tally[key] = (tally[key] or 0) + 1
        L(string.format("  '%s'  CameraType=%s  DebugCamera=%s  FOV=%s",
            tostring(nm), key, tostring(dbg),
            tostring(safe(function() return c:call("get_FOV") end))))
    end
    L("  -- how many cameras per type --")
    for k, v in pairs(tally) do
        L(string.format("    CameraType %s : %d camera(s) %s", k, v,
            v == 0 and "" or "<- already in use"))
    end
    L("  A type with ZERO cameras is one nothing else is relying on: safest to join.")
end

local function attach_render_output()
    if not make_holder() then return end
    local go, _m, err = find_rifle()
    if go == nil then E("RO attach: " .. tostring(err)) return end

    local rt = safe(function() return sdk.typeof("via.render.RenderOutput") end)
    if rt == nil then E("typeof(via.render.RenderOutput) failed") return end

    if st.ro == nil then
        st.ro = safe(function() return go:call("getComponent(System.Type)", rt) end)
        if st.ro ~= nil then L("reusing the RenderOutput already on the rifle") end
    end
    if st.ro == nil then
        local ro, cerr = safe(function() return go:call("createComponent(System.Type)", rt) end)
        if ro == nil then E("createComponent(RenderOutput) failed: " .. tostring(cerr)) return end
        st.ro = ro
        L("RenderOutput created on the rifle GameObject")
    end

    -- Distinct ID FIRST, before anything else, so we can never be mistaken for
    -- the main view even for a frame.
    safe(function() st.ro:call("set_RenderOutputID", OUR_OUTPUT_ID) end)
    L("set_RenderOutputID(" .. OUR_OUTPUT_ID .. ") -- main view is 1, ours is not")

    safe(function() st.ro:call("set_ClipingEnable", false) end)   -- no mirror-style clipped half
    safe(function() st.ro:call("set_RenderTarget", st.holder) end)
    L("set_RenderTarget(our holder) -> " ..
      tostring(safe(function() return st.ro:call("get_RenderTarget") end)))
    L("RenderOutput ready. If the glass is bound (button 3) look at it now: a")
    L("RenderOutput with NO paired via.Camera may well render nothing -- that")
    L("result is exactly what step 8 is for.")
    st.status = "renderoutput attached"
end

-- RISKY STEP -- read the comment above. Adds a second via.Camera to a live scene.
local function attach_camera()
    -- Record the engine's own primary camera FIRST, so we can always put it back
    -- without a restart. This is the whole lesson of the 2026-08-25 takeover.
    local sv = main_view()
    if sv ~= nil and st.orig_primary == nil then
        st.orig_primary = safe(function() return sv:call("get_PrimaryCamera") end)
        L("saved original primary camera: " .. tostring(st.orig_primary))
    end
    local go, _m, err = find_rifle()
    if go == nil then E("cam attach: " .. tostring(err)) return end
    local ct = safe(function() return sdk.typeof("via.Camera") end)
    if ct == nil then E("typeof(via.Camera) failed") return end

    if st.cam == nil then
        st.cam = safe(function() return go:call("getComponent(System.Type)", ct) end)
        if st.cam ~= nil then L("reusing the via.Camera already on the rifle") end
    end
    if st.cam == nil then
        local c, cerr = safe(function() return go:call("createComponent(System.Type)", ct) end)
        if c == nil then E("createComponent(via.Camera) failed: " .. tostring(cerr)) return end
        st.cam = c
        L("via.Camera created on the rifle GameObject")
    end

    -- A scope is a narrow field of view. 63 deg is the game's hip FOV; the stock
    -- scope measured 26.23 deg (2.40x). Start there.
    -- Match the game's own camera for everything we have no reason to change.
    -- Read off MainCamera, 2026-08-25: near 0.01, far 4000.
    safe(function() st.cam:call("set_NearClipPlane", 0.01) end)
    safe(function() st.cam:call("set_FarClipPlane", 4000.0) end)
    safe(function() st.cam:call("set_FOV", 26.23) end)
    L("camera FOV -> " .. tostring(safe(function() return st.cam:call("get_FOV") end)))

    -- There is NO set_PrimaryCamera (getter only), so a takeover cannot be undone.
    -- The only defence is never to be promoted: mark ourselves as a different KIND
    -- of camera. st.cam_type comes from the via.CameraType dump (button 9); until
    -- that has actually been read this stays a no-op rather than a guess.
    if st.cam_type ~= nil then
        safe(function() st.cam:call("set_CameraType", st.cam_type) end)
        L("set_CameraType(" .. tostring(st.cam_type) .. ") -> now " ..
          tostring(safe(function() return st.cam:call("get_CameraType") end)))
    else
        E("NO CameraType chosen yet (run button 9 first) -- this camera may be")
        E("promoted to primary and take over your view. Restart is the only undo.")
    end
    L("primary camera is now = " .. tostring(safe(function() return sv and sv:call("get_PrimaryCamera") end)))
    L("LOOK AT THE GLASS -- and at your own screen. If YOUR view changed, press")
    L("'Detach second view' immediately and tell me.")
    st.status = "camera attached"
end

-- Undo. Disconnects our output from the render target first (that alone should
-- stop it producing), then clears our handles.
local function detach_second_view()
    if st.ro ~= nil then
        safe(function() st.ro:call("set_RenderTarget", nil) end)
        L("RenderOutput: render target cleared")
    end
    if st.cam ~= nil then
        safe(function() st.cam:call("set_FOV", 63.0) end)
        L("camera FOV reset to hip 63")
    end
    st.ro, st.cam = nil, nil
    st.status = "second view detached"
    L("NOTE: components themselves remain on the GameObject until the scene")
    L("reloads. They are inert with no render target. One game restart clears all.")
end

re.on_draw_ui(function()
    if not imgui.tree_node("M6 — Mirror as producer (scope)") then return end

    imgui.text("status: " .. st.status)
    imgui.text("holder: " .. (st.holder ~= nil and "ready" or "none") ..
               "   mirror: " .. (st.mirror ~= nil and "attached" or "none") ..
               "   saved slots: " .. #st.saved)
    imgui.text("Order: 1) Dump API  2) Attach Mirror  3) Glass -> Mirror RT")

    if imgui.button("1. Dump Mirror API") then dump_mirror_api() end
    if imgui.button("2. Attach Mirror to rifle + set RT") then attach_mirror() end
    if imgui.button("3. Glass -> Mirror RT") then bind_glass() end
    imgui.separator()
    -- Aiming the reflection: run this AFTER step 2 so the values are live.
    if imgui.button("4. Dump Mirror internals (fields + live values)") then dump_mirror_internals() end
    if imgui.button("5. Dump RT-producer candidates (RenderOutput & friends)") then dump_candidates() end
    if imgui.button("6. Inspect the LIVE RenderOutput (read-only)") then inspect_live_renderoutput() end
    imgui.separator()
    imgui.text("M7 -- build a real second view (do 7 first, read log, THEN 8)")
    if imgui.button("7. Attach RenderOutput to rifle (ID=2, our RT)") then attach_render_output() end
    if imgui.button("8. Add via.Camera  [RISKY -- second camera in a live scene]") then attach_camera() end
    if imgui.button("Detach second view (undo 7+8)") then detach_second_view() end
    if imgui.button("9. Dump via.CameraType + main camera settings") then dump_camera_types() end
    -- Census result (2026-08-25): the whole scene contains exactly ONE camera,
    -- 'MainCamera', CameraType=0 (Game). Types 1..6 have ZERO users -- Debug,
    -- Scene, SceneXY/YZ/XZ and Preview are all editor leftovers nothing in the
    -- shipped game relies on. So joining one displaces nothing. The open risk is
    -- the opposite: an editor-only type might not render AT ALL at runtime, which
    -- is precisely what these three try, cheapest-to-likeliest.
    imgui.text("Camera type for button 8: " .. tostring(st.cam_type or "NONE (will warn)"))
    if imgui.button("  use Debug (1)")   then st.cam_type = 1 L("cam_type = 1 Debug")   end
    if imgui.button("  use Preview (6)") then st.cam_type = 6 L("cam_type = 6 Preview") end
    if imgui.button("  use Scene (2)")   then st.cam_type = 2 L("cam_type = 2 Scene")   end
    if imgui.button("(RESCUE is not possible -- click to see why)") then restore_primary_camera() end
    if imgui.button("0. Dump SceneView / Scene / Camera API (unfiltered)") then dump_sceneview_api() end
    if st.mirror ~= nil then
        if imgui.button("Toggle LightWeightMode") then
            local cur = safe(function() return st.mirror:call("get_LightWeightMode") end)
            safe(function() st.mirror:call("set_LightWeightMode", not cur) end)
            L("LightWeightMode " .. tostring(cur) .. " -> " .. tostring(not cur))
        end
    end
    imgui.separator()
    if imgui.button("Restore glass") then restore_glass() end
    if imgui.button("Unregister Mirror") then unregister_mirror() end

    imgui.tree_pop()
end)

L("loaded — open the REFramework menu, Script Generated UI -> 'M6 — Mirror as producer (scope)'")
