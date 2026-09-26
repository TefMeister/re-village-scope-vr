# The next flat run: praydog's clone, step for step (built 2026-09-26 by /pd, staging `re8_scope_cam_clone.lua`)

Fresh launch, gameplay, then one word at a time (command file), glass + FULL-screen screenshot after each:

| # | words | what it answers |
| --- | --- | --- |
| 1 | `cloneorder` | MainCamera's real component order (what the clone copies) |
| 2 | `clonewatch` | baseline: which Scene layers' ResizeFrame MOVES (the eyes should) |
| 3 | `clonemake` | the full recipe: LockScene build, parented to MainCamera, every component in order, id 3, no target |
| 4 | `clonewatch` | does the CLONE's layer counter move? MOVES = it now runs. **Also: did the screen change?** (id 3 with no target may composite onto the screen) |
| 5 | `clonekill` then numpad `.` then `clonemake rt` | same, but into our own 2560 target so the plugin's catcher can show it on the glass |
| 6 | `clonehook` then `clonewatch` | praydog's get_PrimaryCamera guard (expected: no change; it only prevents a takeover) |
| 7 | `clonekill` then `clonemake bare` then `clonewatch` | A/B: Camera + RenderOutput only, same moment and flags -- tells whether the COMPONENTS or the MOMENT made the difference |

Reading: the clone's counter moving while the old ScopeCam's never did = praydog's recipe is the fix, and 7 says which part. Still
"still" on every rung = the difference is native (his C++ runs hooks our Lua cannot; next is a plugin-side clone).
