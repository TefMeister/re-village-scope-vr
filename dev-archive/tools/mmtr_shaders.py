"""mmtr_shaders.py - carve the compiled shaders out of an RE Engine .mmtr and read them.

    python mmtr_shaders.py list   <file.mmtr>                 # every DXBC blob, with its RDEF names
    python mmtr_shaders.py find   <file.mmtr> <name> [...]     # only blobs whose RDEF mentions these
    python mmtr_shaders.py dump   <file.mmtr> <index> <out>    # write one blob to disk
    python mmtr_shaders.py disasm <file.mmtr> <index>          # D3DDisassemble it to readable assembly

Why this exists. A master material (.mmtr) is the only place the SHADER lives -- the
.mdf2 just names variables and values, so reading it tells you a parameter exists and
nothing about what it DOES. RE Village's sniper-scope lens carries an eye-position term
we needed to understand before spending a headset wear on it, and the file turned out to
hold 378 ordinary DXBC blobs with their reflection chunks intact.

How the carving works. A DXBC container is self-describing: the magic 'DXBC', a 16-byte
digest, a u32 version, then the TOTAL SIZE at offset 24 and the chunk count at 28. So
every blob can be cut out exactly without knowing anything about the .mmtr's own format
-- which is the same trick that makes shader bundles readable through Denuvo: shaders are
data, not code.

`disasm` calls D3DDisassemble out of the system d3dcompiler_47.dll through ctypes, so
nothing has to be built. ID3DBlob is a plain COM object: GetBufferPointer and
GetBufferSize are vtable slots 3 and 4, after the three IUnknown entries.

Reads game files locally and writes only what it is asked to. Never commit what it
extracts -- the shader bytecode is game content; the NAMES it prints are interface
metadata and are fine.
"""
import ctypes
import os
import struct
import sys

MAGIC = b"DXBC"


def carve(data):
    """Every DXBC container in `data`, as (offset, size). Sizes come from the
    container's own header, so a false-positive magic inside a blob is rejected
    rather than silently splitting one shader into two."""
    out = []
    pos = 0
    end = len(data)
    while True:
        i = data.find(MAGIC, pos)
        if i < 0:
            break
        if i + 32 > end:
            break
        total, chunks = struct.unpack_from("<II", data, i + 24)
        # Sanity: a real container is at least a header plus one chunk offset, fits
        # inside the file, and does not claim an absurd chunk count.
        if 32 < total <= end - i and 0 < chunks < 64:
            out.append((i, total))
            pos = i + total
        else:
            pos = i + 4
    return out


def rdef_strings(blob):
    """ASCII runs of 3+ chars from the blob's RDEF (reflection) chunk. That chunk is
    where cbuffer, variable and resource NAMES live, so this is enough to say which
    shader owns a parameter without decoding the chunk's structure."""
    j = blob.find(b"RDEF")
    if j < 0:
        return []
    size = struct.unpack_from("<I", blob, j + 4)[0]
    chunk = blob[j + 8: j + 8 + size]
    names, cur = [], bytearray()
    for b in chunk:
        if 32 <= b < 127:
            cur.append(b)
        else:
            if len(cur) >= 3:
                names.append(cur.decode("ascii"))
            cur = bytearray()
    if len(cur) >= 3:
        names.append(cur.decode("ascii"))
    return names


def _disassemble(blob):
    d3d = ctypes.WinDLL("d3dcompiler_47.dll")
    fn = d3d.D3DDisassemble
    fn.restype = ctypes.c_long
    fn.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_uint,
                   ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p)]
    out = ctypes.c_void_p()
    buf = ctypes.create_string_buffer(blob, len(blob))
    hr = fn(ctypes.cast(buf, ctypes.c_void_p), len(blob), 0, None, ctypes.byref(out))
    if hr != 0 or not out:
        raise RuntimeError("D3DDisassemble failed, hr=0x%08X" % (hr & 0xFFFFFFFF))
    # ID3DBlob: [0] QueryInterface [1] AddRef [2] Release [3] GetBufferPointer [4] GetBufferSize
    vtbl = ctypes.cast(out, ctypes.POINTER(ctypes.c_void_p))[0]
    slots = ctypes.cast(vtbl, ctypes.POINTER(ctypes.c_void_p))
    get_ptr = ctypes.CFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p)(slots[3])
    get_len = ctypes.CFUNCTYPE(ctypes.c_size_t, ctypes.c_void_p)(slots[4])
    release = ctypes.CFUNCTYPE(ctypes.c_ulong, ctypes.c_void_p)(slots[2])
    n = get_len(out)
    text = ctypes.string_at(get_ptr(out), n)
    release(out)
    return text.decode("utf-8", "replace")


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    mode, path = sys.argv[1], sys.argv[2]
    data = open(path, "rb").read()
    blobs = carve(data)

    if mode == "list":
        print("%d DXBC blob(s) in %s (%d bytes)" % (len(blobs), os.path.basename(path), len(data)))
        for k, (off, size) in enumerate(blobs):
            names = rdef_strings(data[off:off + size])
            print("[%3d] off=0x%08X size=%-8d %s" % (k, off, size, " ".join(names[:8])))
        return 0

    if mode == "find":
        wanted = [w.lower() for w in sys.argv[3:]]
        if not wanted:
            print("find: give at least one name to look for")
            return 2
        hits = 0
        for k, (off, size) in enumerate(blobs):
            names = rdef_strings(data[off:off + size])
            low = [n.lower() for n in names]
            if all(any(w in n for n in low) for w in wanted):
                hits += 1
                print("[%3d] off=0x%08X size=%-8d %s" % (k, off, size, " ".join(names)))
        print("%d of %d blob(s) matched" % (hits, len(blobs)))
        return 0 if hits else 1

    if mode == "dump":
        k, out = int(sys.argv[3]), sys.argv[4]
        off, size = blobs[k]
        open(out, "wb").write(data[off:off + size])
        print("blob %d (off=0x%08X, %d bytes) -> %s" % (k, off, size, out))
        return 0

    if mode == "disasm":
        k = int(sys.argv[3])
        off, size = blobs[k]
        print(_disassemble(data[off:off + size]))
        return 0

    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
