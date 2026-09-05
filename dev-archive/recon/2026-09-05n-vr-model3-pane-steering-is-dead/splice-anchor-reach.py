import io, shutil
G = r"C:\Steam\steamapps\common\Resident Evil Village BIOHAZARD VILLAGE\reframework\autorun"
P = G + r"\re8_scope_m6_mirror_producer.lua"
shutil.copy(P, P + ".pre-anchor-reach-backup-2026-09-05n")
p = io.open(P, encoding="utf-8").read()
old = """    if anchor_pos == nil then anchor_pos = Vector3f.new(pos.x, pos.y, pos.z) end
"""
assert p.count(old) == 1
new = """    if anchor_pos == nil then anchor_pos = Vector3f.new(pos.x, pos.y, pos.z) end
    -- 2026-09-05 late (headset): the lens anchor sits practically AT the VR eye, so a
    -- few centimetres of head lean swung the eye->anchor ray by ~95 deg. Model 3
    -- measures the ray to a point st.anchor_reach metres further along the bore
    -- (the objective end of the scope), where a lean is a small angle again.
    if st.steer_model == "ref" and az ~= nil and (st.anchor_reach or 0) ~= 0 then
        anchor_pos = Vector3f.new(anchor_pos.x + az.x * st.anchor_reach,
                                  anchor_pos.y + az.y * st.anchor_reach,
                                  anchor_pos.z + az.z * st.anchor_reach)
    end
"""
p = p.replace(old, new, 1)
old2 = "st.steer_ref = nil\n"
assert p.count(old2) == 1
p = p.replace(old2, "st.steer_ref = nil\nst.anchor_reach = 0.35\n", 1)
io.open(P, "w", encoding="utf-8", newline="\n").write(p)

H = G + r"\re8_scope_harness.lua"
h = io.open(H, encoding="utf-8").read()
old3 = '    elseif cmd == "steerk" and v and s then s.steer_k = v\n'
assert h.count(old3) == 1
h = h.replace(old3, old3 + '    elseif cmd == "reach" and v and s then s.anchor_reach = v s.steer_ref = nil\n', 1)
io.open(H, "w", encoding="utf-8", newline="\n").write(h)
print("spliced")
