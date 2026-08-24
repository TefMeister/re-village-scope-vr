# Research index

Every research topic gathered for this project, newest first. Each row links to a self-contained
write-up in `topics/`. Status tags:

- 🆕 **new** — found, not yet acted on by the modding side.
- 👀 **reviewed** — a modding session has read it and factored it into a decision, but nothing shipped from it yet.
- ✅ **incorporated** — directly led to a real change (code, a test, a note) in one of the other five repos; linked below.
- ❌ **dead end** — checked out, didn't pan out; kept for the record so it isn't re-investigated from scratch.

| Date | Topic | Status | Summary |
| --- | --- | --- | --- |
| 2026-08-24 | [RT GPU-backing: known REResource bug + VR eye-texture architecture](topics/2026-08-24-rt-gpu-backing-known-reresource-bug-and-vr-eye-texture-architecture.md) | 🆕 new | REFramework issue #1448 describes an unresolved resource-lifetime/GC bug matching the "RT binds but shows nothing" symptom — workaround: `add_ref()` both the holder AND the resource, create early. Also: REFramework's own VR eye texture is a post-render backbuffer copy, not engine-side scene→RT registration — doesn't transfer, but reinforces that Mirror-as-producer (candidate 1) is the right direction, not a backbuffer-copy shortcut. Still no public in-world-screen/second-camera RE Engine mod found. |

## How to add a topic

1. New file in `topics/`, named `YYYY-MM-DD-short-slug.md`.
2. One row added to the table above, newest at the top.
3. Update the status tag here as it moves through review → incorporated/dead-end (the modding side should update this when it acts on a lead, so the index reflects reality without the research side needing to poll).
