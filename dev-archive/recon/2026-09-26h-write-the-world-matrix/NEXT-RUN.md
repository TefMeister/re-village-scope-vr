# The next flat run: write the world matrix by hand (built 2026-09-26 late by /pd, Fable)

**Why** (§9cu): a runtime GameObject's transform never gets its world matrix computed, so the clone camera's View/World stay
identity. praydog's re8 layout puts the transform's `WorldTransform` at +0x80 (Position 0x30, Rotation 0x40, Scene* 0x60,
UpdateFrame 0xCC, DirtySelf 0xD1, DirtyUpwards 0xD2). `clonepose` copies a real object's 16 world floats into it every LockScene.

Fresh launch, gameplay, then one word per rung, glass screenshot + `tail` after each:

| # | words | answers |
| --- | --- | --- |
| 1 | numpad `.` → `src8 1` → `clonemake rt` (4 s) → `clonetf` | the clone transform raw: **is its Scene* nil? are the dirty flags stuck? World rows identity?** — next to MainCamera's and the rifle's |
| 2 | `clonepose main` → `camcmp` | does the camera's View/World now follow the written world matrix (View row 3 ≈ main's)? |
| 3 | numpad `+` twice, walk `s` 1.5 s between | the target's pixels: the vignette field → the room? changes with walking? |
| 4 | `clonepose rifle` → `camcmp` → numpad `+` | the same from the rifle's own pose (the goal) |
| 5 | if the camera's matrices still ignore the write: `clonescene` → `clonetf` → wait 3 s → `camcmp` | does giving it a Scene* make the scene update it (World rows change by themselves) |
| 6 | `clonekill` → `clonemake rt upd` → `clonescene` → `clonetf` | same with UpdateSelf on |

**Reading:** row 3 of the camera's View following the write = the camera reads the transform's cached matrix; then `+`/glass says whether
the layer renders (room) or not. Camera unchanged after the write = the camera keeps its own copy; find it (dump the camera's 0x1000
bytes before/after `clonepose`) — that is a `/pd` job. Scene* nil and rung 5 making the rows move by themselves = the real fix is
scene membership; then do it at creation.
