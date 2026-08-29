# Research index

Every research topic gathered for this project, newest first. Each row links to a self-contained
write-up in `topics/`. Status tags:

- 🆕 **new** — found, not yet acted on by the modding side.
- 👀 **reviewed** — a modding session has read it and factored it into a decision, but nothing shipped from it yet.
- ✅ **incorporated** — directly led to a real change (code, a test, a note) in one of the other five repos; linked below.
- ❌ **dead end** — checked out, didn't pan out; kept for the record so it isn't re-investigated from scratch.

| Date | Topic | Status | Summary |
| --- | --- | --- | --- |
| 2026-08-29 | [Runtime mesh spawning: via.Prefab + instantiate](topics/2026-08-29-runtime-mesh-spawning-via-prefab-instantiate.md) | ✅ incorporated — staging `c4052d3`, P-series buttons P0–P4 (2026-08-29) | Answers the M18–M26 wall: don't assemble GameObjects from components — instantiate a `.pfb` prefab (`via.Prefab` → `set_Path` → `get_Exist` → `instantiate(via.vec3, via.Folder)`); EMV Engine's proven route, RE8 explicitly supported, and EMV's own README warns component assembly is fragile. RE8 ships 2,670 prefabs incl. `ri3042_detailsearch.pfb` (a spawnable copy of our rifle) and `c22e500_00_mirror.pfb` (a Capcom-assembled cutscene mirror to read the recipe off). Unlocks the pane-steering test that all three mirror limits hang on. |
| 2026-08-24 | [RT GPU-backing: known REResource bug + VR eye-texture architecture](topics/2026-08-24-rt-gpu-backing-known-reresource-bug-and-vr-eye-texture-architecture.md) | 🆕 new | REFramework issue #1448 describes an unresolved resource-lifetime/GC bug matching the "RT binds but shows nothing" symptom — workaround: `add_ref()` both the holder AND the resource, create early. Also: REFramework's own VR eye texture is a post-render backbuffer copy, not engine-side scene→RT registration — doesn't transfer, but reinforces that Mirror-as-producer (candidate 1) is the right direction, not a backbuffer-copy shortcut. Still no public in-world-screen/second-camera RE Engine mod found. |

## How to add a topic

1. New file in `topics/`, named `YYYY-MM-DD-short-slug.md`.
2. One row added to the table above, newest at the top.
3. Update the status tag here as it moves through review → incorporated/dead-end (the modding side should update this when it acts on a lead, so the index reflects reality without the research side needing to poll).
