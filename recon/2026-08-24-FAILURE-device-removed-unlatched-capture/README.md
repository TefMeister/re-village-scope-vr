# 2026-08-24 (home PC) — FAILURE: DXGI_ERROR_DEVICE_REMOVED, hard freeze on equipping the rifle

**Verdict: the D3D12 capture hook never identified our resource. It stored "the last
Texture2D allocated while armed" and hoped. Removing the accidental thing that had been
freezing that pointer turned a latent bug into an instant device removal.**

## What the user saw

Loaded a save, equipped the F2 rifle, and the game froze solid — image locked in place,
never recovered. (On the dev PC the same underlying defect had presented differently:
the game unfroze and all colours went "low poly / cell shaded".)

## What the log shows

Full plugin log lines: `all-plugin-log-lines.txt`. The decisive stretch is in
`log-excerpt-capture-drift-to-device-removed.txt`:

```
2193  auto-created scope target resource -> committed=0000000000000000 holder=0000011B4F592670
2194  CreateCommittedResource dim=728x1280 fmt=29 flags=0x1 -> 0000011FC36ACFB0   <-- OURS
2195..2242  47 more CreateCommittedResource captures, all game textures
            (fmt=72 BC1_UNORM_SRGB / fmt=98 BC7_UNORM, all flags=0x0),
            each one overwriting last_committed
2243  blit: pso_blit (re)built for target fmt=98 1024x1024
2244  blit: first continuous scope-image write into the engine target (fmt=98 1024x1024)
2245  Present failed: ffffffff887a0005     <-- DXGI_ERROR_DEVICE_REMOVED
```

Line 2194 is the good news: **the hook caught our real render target correctly, first
try, 1 ms after the create call** — 1280x728, `R8G8B8A8_UNORM_SRGB`, `ALLOW_RENDER_TARGET`.
Identical to the signature observed on the dev PC. Identification was never the hard part;
nothing was *keeping* it.

Line 2243-2245 is the kill: `last_committed` had drifted to a 1024x1024 **BC7_UNORM**
texture with `flags=0x0`. `blit_rt_into_target()` built a pipeline state with
`RTVFormats[0] = BC7_UNORM` and drew into it. Rendering into a block-compressed texture
is illegal in D3D12; the driver removed the device.

## The reasoning error that caused it

The commit immediately before this (`0286638`) identified, correctly, that
`ensure_created()` set `hook::armed = true` without setting `arm_frame`, so
`check_and_report()` disarmed on the very next present. It called that a race and
"fixed" it with a `keep_armed` flag.

**The race was protective.** Disarming after ~1 frame was accidentally acting as a
*latch*, freezing the pointer right after our own allocation landed — and it is the only
reason the dev-PC session ever appeared to work. The fix removed the protection and
replaced it with nothing, so all 47 subsequent textures got a turn.

## This also re-explains the earlier dev-PC corruption

The 2026-08-24 dev-PC incident was attributed to the brute-force material bind (5615
meshes / 44920 `setMaterialTexture` calls). That bind was genuinely reckless and is
rightly gone — but it is probably **not** what corrupted the visuals. The same pointer
drift happened there; the difference is that the drifted-to texture happened to have a
legal render-target format, so instead of removing the device, the scope image was
written into a real game texture every frame. "All the colours went low-poly / cell
shaded" is a much better fit for *the game's own textures being overwritten* than for a
reticle-slot material swap.

## The fix (staging, next commit)

- `looks_like_our_target()` — identify by the signature of what we *asked for*:
  Texture2D + `ALLOW_RENDER_TARGET` + width 1280 + height 700..768. Every streamed game
  texture arrives `flags=0x0` and is rejected outright.
- **Latch on first match**, then store nothing further, log nothing further, and disarm
  both hooks for the rest of the session.
- `hook_srv` no longer feeds `last_captured` at all — it sees thousands of unrelated
  bindless SRVs per frame, so anything it wrote was by definition a guess.
- `blit_rt_into_target()` draws only when latched **and** independently re-checks that
  the target carries `ALLOW_RENDER_TARGET` and a drawable, non-block-compressed format.
  This second guard makes device removal unreachable rather than merely unlikely.
- `write_test_pattern()` (F7) requires the latch too; its "fall back to `last_captured`"
  line was the diagnostic twin of the same bug.

## Lesson worth keeping

**Never write into a GPU resource you have not positively identified.** "The last thing
the hook saw" is not an identification. And when removing something that looks like an
accident, first ask what it was holding up — this bug was created by fixing a real race
whose side effect was the only safety in the system.
