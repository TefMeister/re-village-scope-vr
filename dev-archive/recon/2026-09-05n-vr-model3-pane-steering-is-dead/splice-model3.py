import io, shutil, sys
G = r"C:\Steam\steamapps\common\Resident Evil Village BIOHAZARD VILLAGE\reframework\autorun"
P = G + r"\re8_scope_m6_mirror_producer.lua"
H = G + r"\re8_scope_harness.lua"
shutil.copy(P, P + ".pre-model3-backup-2026-09-05n")
shutil.copy(H, H + ".pre-model3-backup-2026-09-05n")

p = io.open(P, encoding="utf-8").read()
assert p.count("st.steer_k = 0.5\n") == 1
p = p.replace("st.steer_k = 0.5\n",
"""st.steer_k = 0.5
-- model 3, "ref" (2026-09-05 late, /lm, headset). Model 2's premise -- "on-axis
-- means the eye is on the bore line" -- is FALSE in VR: aiming with the picture
-- right, the eye->anchor ray sat 84 deg off the bore (the headset eye is well
-- above the rifle's lens anchor), so model 2 applied a constant 42 deg where it
-- should have applied nothing. This model captures the eye->anchor ray, in the
-- pane's own frame, at the moment steering is switched on -- i.e. at whatever
-- pose the user has just called right -- and steers by the DEVIATION from that
-- reference. Identity at the reference pose by construction, flat or VR.
st.steer_ref = nil
""", 1)

old_corr = """    if st.steer_model == "corr" then
        local q2 = steer_corr_rotation(rot, d, v, st.steer_k)
        if q2 == nil then return nil, "degenerate vectors" end
        if isnan(q2.x) or isnan(q2.y) or isnan(q2.z) or isnan(q2.w) then return nil, "NaN" end
        local now2 = os.clock()
        if now2 - st.steer_log_t > 5.0 then
            st.steer_log_t = now2
"""
assert p.count(old_corr) == 1
new_corr = """    if st.steer_model == "ref" then
        local rq = { x = rot.x, y = rot.y, z = rot.z, w = rot.w }
        local rinv = { x = -rq.x, y = -rq.y, z = -rq.z, w = rq.w }
        if st.steer_ref == nil then
            st.steer_ref = quat_rotate(rinv, v)
            L(string.format("steer: model=ref REFERENCE captured -- eye->anchor in the pane frame = (%.2f,%.2f,%.2f), %.1f deg off the bore at capture. Steering is the identity here by construction.",
                st.steer_ref.x, st.steer_ref.y, st.steer_ref.z,
                math.deg(math.acos(math.max(-1.0, math.min(1.0, v3_dot(d, v)))))))
            return nil, "reference captured"
        end
        local vref = v3_norm(quat_rotate(rq, st.steer_ref))
        if vref == nil then return nil, "degenerate reference" end
        local arc = quat_shortest_arc(vref, v)
        local corr = quat_scale_angle(arc, st.steer_k or 0.5)
        local q3 = quat_mul(corr, rq)
        if isnan(q3.x) or isnan(q3.y) or isnan(q3.z) or isnan(q3.w) then return nil, "NaN" end
        local now3 = os.clock()
        if now3 - st.steer_log_t > 2.0 then
            st.steer_log_t = now3
            local dev = math.deg(math.acos(math.max(-1.0, math.min(1.0, v3_dot(vref, v)))))
            -- the reflected bore before/after: does the applied rotation move the VIEW at all?
            local n0 = quat_rotate(rq, { x = 0, y = 1, z = 0 })
            local n1 = quat_rotate(q3, { x = 0, y = 1, z = 0 })
            local r0 = { x = d.x - 2 * v3_dot(d, n0) * n0.x, y = d.y - 2 * v3_dot(d, n0) * n0.y, z = d.z - 2 * v3_dot(d, n0) * n0.z }
            local r1 = { x = d.x - 2 * v3_dot(d, n1) * n1.x, y = d.y - 2 * v3_dot(d, n1) * n1.y, z = d.z - 2 * v3_dot(d, n1) * n1.z }
            local swing = math.deg(math.acos(math.max(-1.0, math.min(1.0, v3_dot(r0, r1)))))
            L(string.format("steer: model=ref k=%.3f deviation=%.1f deg -> applied %.1f deg; reflected-bore swing %.1f deg (0 = the rotation is about the pane normal and moves nothing)",
                st.steer_k, dev, dev * st.steer_k, swing))
        end
        return q3
    end
    if st.steer_model == "corr" then
        local q2 = steer_corr_rotation(rot, d, v, st.steer_k)
        if q2 == nil then return nil, "degenerate vectors" end
        if isnan(q2.x) or isnan(q2.y) or isnan(q2.z) or isnan(q2.w) then return nil, "NaN" end
        local now2 = os.clock()
        if now2 - st.steer_log_t > 5.0 then
            st.steer_log_t = now2
            do
                local rq = { x = rot.x, y = rot.y, z = rot.z, w = rot.w }
                local n0 = quat_rotate(rq, { x = 0, y = 1, z = 0 })
                local n1 = quat_rotate(q2, { x = 0, y = 1, z = 0 })
                local r0 = { x = d.x - 2 * v3_dot(d, n0) * n0.x, y = d.y - 2 * v3_dot(d, n0) * n0.y, z = d.z - 2 * v3_dot(d, n0) * n0.z }
                local r1 = { x = d.x - 2 * v3_dot(d, n1) * n1.x, y = d.y - 2 * v3_dot(d, n1) * n1.y, z = d.z - 2 * v3_dot(d, n1) * n1.z }
                L(string.format("steer: model=corr reflected-bore swing %.1f deg under the applied rotation (0 = about the pane normal, moves nothing)",
                    math.deg(math.acos(math.max(-1.0, math.min(1.0, v3_dot(r0, r1)))))))
            end
"""
p = p.replace(old_corr, new_corr, 1)

# harness fn to recapture the reference
old_fn = "    sc_next = sc_bind_next,\n}"
assert p.count(old_fn) == 1
p = p.replace(old_fn, """    sc_next = sc_bind_next,
    -- model 3: forget the reference ray; the next steered frame captures a new one.
    steer_ref = function() st.steer_ref = nil L("steer: reference cleared (harness) -- aim so the picture is RIGHT, then it is captured on the next frame") end,
}""", 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(p)

h = io.open(H, encoding="utf-8").read()
old_m = """        s.steer_model = (v == 2) and "corr" or ((v ~= 0) and "fwd" or "eye")
        s.steer_axis = nil"""
assert h.count(old_m) == 1
h = h.replace(old_m, """        s.steer_model = (v == 3) and "ref" or (v == 2) and "corr" or ((v ~= 0) and "fwd" or "eye")
        s.steer_axis = nil
        s.steer_ref = nil""", 1)
old_s = 'elseif cmd == "steer" and v and s then s.steer_on = (v ~= 0)'
assert h.count(old_s) == 1
h = h.replace(old_s, 'elseif cmd == "steer" and v and s then s.steer_on = (v ~= 0) if v ~= 0 then s.steer_ref = nil end', 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(h)
print("spliced")
