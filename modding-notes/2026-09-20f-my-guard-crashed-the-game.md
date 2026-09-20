# My safety check crashed the game (2026-09-20, `/pd`, home PC `RTX`)

Tefa ran `RIFLE-STRAIGHT-A.bat` and fired: *"it crashed the game on me"*
`[verified-live 2026-09-20, n=1]`.

## Where it died

```
18:40:55  spread-fix: hooked app.WeaponGunCore.setupDiffusion (off by default)
18:42:29  spread-fix: switched to mode=1 (seen 0 shot(s), applied to 0)
          <nothing further>
```

The layout line is printed **unconditionally on the first call into the hook**, so its absence places
the crash inside that first call — **in the safety check, before any write**.

## The bug — two mistakes in one line

```
auto* d3 = (API::TypeDefinition*)arg_tys[3];
if (d3 != nullptr) t3 = d3->get_full_name();
```

1. **`arg_tys` entries are handles, not pointers.** `include/reframework/API.h` says so directly above
   the typedefs: *"these are NOT pointers to the actual objects"*. Casting one and calling a method on
   it is undefined.
2. **There is no length for `arg_tys`.** The callback receives `argc` (which counts `argv`) and nothing
   for the type array, so index 4 may have been past the end too.

I had read that file — I quoted `add_hook` out of it — and used the one thing in it I had not checked.

## ⚠️ The lesson, which is not "be careful with casts"

**I wrote a guard more dangerous than the thing it guarded.**

The write itself is 16 bytes into memory the Lua tool had been **reading successfully for an hour**
beforehand. The risk I was protecting against — a wrong argument index scribbling over the shot
position — was real, but I chose to check it by reaching into the engine's *type metadata* through a
cast I had never verified. The guard had a higher chance of faulting than the write it was guarding.

**So: prefer validating the DATA you are about to touch over validating the engine's description of
it.** A rotation quaternion has length 1. That is one multiply-add, needs no metadata, cannot be wrong
about engine internals, and catches exactly the case that mattered.

Related, and the same shape: §9bd's muzzle-joint comparison, which was also a "sanity check" built on
an assumption about a frame nobody had verified.

## The second version

Built, 0 errors 0 warnings `[compile-verified 2026-09-20]`, deployed as `re_scope_vr.dll`
(241,152 bytes, sha256 `b65ad8bdd9a3d87a…`).

- **`arg_tys` is not touched at all**; the parameter is left unnamed.
- ⭐ **`off` is now genuinely inert.** The mode is the first thing read and it returns immediately. The
  old version did its fatal checking *before* consulting the mode — which means a build sitting at
  "off" was still a risk to play with, and that was the worse half of this mistake.
- ⭐ **It validates the data.** Both rotations are read through `__try`-guarded reads and each must be
  a unit quaternion (length² in 0.90–1.10) before anything is written. Otherwise it refuses **for
  good** and logs why.
- ⭐ **The write is `__try`-guarded too.** A faulting write logs `(the write faulted)` rather than
  taking the process with it.
- Everything else from §9be is kept: measure → write → re-measure, seen-vs-applied counters,
  rifle-only through `world_tick`'s existing filter.

## What was made safe immediately

- **The switch file was set back to `0 0`** before anything else, so a relaunch could not re-trigger
  it.
- **`re_scope_vr.dll.pre-spread-fix-2026-09-20` is untouched** — it still holds the build from before
  any of this work, so going back is one file copy.
- `deployed.sh record` re-run against the new build.

## ⚠️ What the crash does not tell us

**Nothing about whether cancelling the scatter works.** The write never ran. §9bd's measurement (hip
8.4° average against aimed 0.005°) and §9be's reasoning are untouched; only the guard was wrong.

Credit: **praydog** (REFramework).
