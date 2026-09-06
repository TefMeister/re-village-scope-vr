"""ree_pak_extract.py - pull ONE or a few named files out of RE Engine .pak archives
without unpacking the whole 30 GB chunk.

    python ree_pak_extract.py "<game dir>" <out dir> natives/stm/movie/rtex/movie_1920_1080.rtex.5 [...]

Scans re_chunk_000.pak and every re_chunk_000.pak.patch_NNN.pak in the game folder (later
patches win, the way the engine layers them), finds each requested path by its name hash and
writes it under <out dir>/<path>. Prints which pak it came from, the compression, and the size.

Format knowledge is Ekey's, read from the public REE.PAK.Tool source (REE.Unpacker,
github.com/Ekey/REE.PAK.Tool) on 2026-09-06 and reimplemented here in Python so a single file
can be pulled instead of a whole archive:
  header  KPKA, major u8, minor u8, feature i16, count i32, fingerprint u32
  entry   (v4, 48 B) hash_lower u32, hash_upper u32, offset i64, csize i64, dsize i64,
          attributes i64 (& 0xF = compression: 0 none, 1 deflate, 2 zstd; >>16 & 0xFF =
          per-resource encryption type), checksum u64
  hashes  murmur3_32(seed 0xFFFFFFFF) over the UTF-16LE path, lower-cased / upper-cased
  table   XOR-obfuscated when the feature flag says so, key = RSA-decrypted 128-byte blob
Credit: Ekey. This script reads game files locally and must never commit what it extracts.
"""
import glob
import io
import os
import struct
import sys
import zlib

import mmh3
import zstandard

MAGIC = 0x414B504B
SEED = 0xFFFFFFFF

# Ekey's PakCipher constants (table obfuscation key, RSA-wrapped), little-endian byte lists.
_PAK_MODULUS = bytes([
    0x7D, 0x0B, 0xF8, 0xC1, 0x7C, 0x23, 0xFD, 0x3B, 0xD4, 0x75, 0x16, 0xD2, 0x33, 0x21, 0xD8, 0x10,
    0x71, 0xF9, 0x7C, 0xD1, 0x34, 0x93, 0xBA, 0x77, 0x26, 0xFC, 0xAB, 0x2C, 0xEE, 0xDA, 0xD9, 0x1C,
    0x89, 0xE7, 0x29, 0x7B, 0xDD, 0x8A, 0xAE, 0x50, 0x39, 0xB6, 0x01, 0x6D, 0x21, 0x89, 0x5D, 0xA5,
    0xA1, 0x3E, 0xA2, 0xC0, 0x8C, 0x93, 0x13, 0x36, 0x65, 0xEB, 0xE8, 0xDF, 0x06, 0x17, 0x67, 0x96,
    0x06, 0x2B, 0xAC, 0x23, 0xED, 0x8C, 0xB7, 0x8B, 0x90, 0xAD, 0xEA, 0x71, 0xC4, 0x40, 0x44, 0x9D,
    0x1C, 0x7B, 0xBA, 0xC4, 0xB6, 0x2D, 0xD6, 0xD2, 0x4B, 0x62, 0xD6, 0x26, 0xFC, 0x74, 0x20, 0x07,
    0xEC, 0xE3, 0x59, 0x9A, 0xE6, 0xAF, 0xB9, 0xA8, 0x35, 0x8B, 0xE0, 0xE8, 0xD3, 0xCD, 0x45, 0x65,
    0xB0, 0x91, 0xC4, 0x95, 0x1B, 0xF3, 0x23, 0x1E, 0xC6, 0x71, 0xCF, 0x3E, 0x35, 0x2D, 0x6B, 0xE3,
])
_PAK_EXPONENT = 0x10001

FEATURES_TABLE_ENCRYPTED = {8, 12, 24, 40, 44}
FEATURE_EXTRA_SKIP = {24: 4, 12: 9, 44: 9}
FEATURES_CHUNKED = {40, 44}


def name_hashes(path):
    lo = mmh3.hash(path.lower().encode("utf-16-le"), SEED, signed=False)
    hi = mmh3.hash(path.upper().encode("utf-16-le"), SEED, signed=False)
    return lo, hi


def _decrypt_table(table, enc_key):
    k = int.from_bytes(enc_key + b"\x00", "little")
    key = pow(k, _PAK_EXPONENT, int.from_bytes(_PAK_MODULUS + b"\x00", "little"))
    kb = key.to_bytes((key.bit_length() + 8) // 8, "little")
    out = bytearray(table)
    for i in range(len(out)):
        out[i] ^= (i + kb[i % 32] * kb[i % 29]) & 0xFF
    return bytes(out)


def read_table(f):
    hdr = f.read(16)
    if len(hdr) < 16:
        return None, []
    magic, major, minor, feature, count, _fp = struct.unpack("<IBBhiI", hdr)
    if magic != MAGIC:
        raise ValueError("not a KPKA pak")
    if major != 4:
        raise ValueError("pak major version %d not handled (only 4)" % major)
    table = f.read(count * 48)
    chunks = None
    if feature in FEATURES_TABLE_ENCRYPTED:
        skip = FEATURE_EXTRA_SKIP.get(feature, 0)
        if skip:
            f.seek(skip, io.SEEK_CUR)
        enc_key = f.read(128)
        table = _decrypt_table(table, enc_key)
        if feature in FEATURES_CHUNKED:
            chunks = _read_chunk_map(f)
    entries = []
    for i in range(count):
        lo, hi, off, csz, dsz, attr, chk = struct.unpack_from("<IIqqqqQ", table, i * 48)
        entries.append((lo, hi, off, csz, dsz, attr, chk))
    return {"feature": feature, "count": count, "chunks": chunks}, entries


def _read_chunk_map(f):
    _max_block, n = struct.unpack("<ii", f.read(8))
    raw = struct.unpack("<%dI" % (2 * n), f.read(8 * n))
    offs, sizes = raw[0::2], raw[1::2]
    high, prev, table = 0, 0, []
    for i in range(n):
        if i > 0 and offs[i] < prev:
            high += 1 << 32
        table.append((high | offs[i], sizes[i] >> 10))
        prev = offs[i]
    return table


def extract_entry(f, info, e):
    lo, hi, off, csz, dsz, attr, chk = e
    comp = attr & 0xF
    enc = (attr >> 16) & 0xFF
    if enc:
        raise ValueError("per-resource encryption type %d not implemented here" % enc)
    if comp == 0 and info["chunks"] is not None and attr in (0x1000000, 0x1000400):
        data = bytearray()
        cid, remain = off, csz
        while remain > 0:
            coff, csize = info["chunks"][cid]
            f.seek(coff)
            blob = f.read(csize)
            data += blob if csize == 524288 else zstandard.ZstdDecompressor().decompress(blob, max_output_size=1 << 26)
            cid += 1
            remain -= csize
        return bytes(data[:dsz]), "chunked-zstd"
    f.seek(off)
    blob = f.read(csz)
    if comp == 0:
        return blob, "none"
    if comp == 1:
        return zlib.decompress(blob, -15), "deflate"
    if comp == 2:
        return zstandard.ZstdDecompressor().decompress(blob, max_output_size=max(dsz, 1) * 2 + 1024), "zstd"
    raise ValueError("unknown compression %d" % comp)


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    game, out, paths = sys.argv[1], sys.argv[2], sys.argv[3:]
    paks = sorted(glob.glob(os.path.join(game, "re_chunk_000.pak*")))
    paks = [p for p in paks if os.path.getsize(p) > 16]
    wanted = {name_hashes(p): p for p in paths}
    found = {}
    for pak in paks:
        with open(pak, "rb") as f:
            info, entries = read_table(f)
            if info is None:
                continue
            hits = [e for e in entries if (e[0], e[1]) in wanted]
            for e in hits:
                data, how = extract_entry(f, info, e)
                found[wanted[(e[0], e[1])]] = (os.path.basename(pak), how, data)
            print("%-45s entries=%-7d feature=%-3d hits=%d" % (os.path.basename(pak), info["count"], info["feature"], len(hits)))
    for p in paths:
        if p not in found:
            print("MISSING: %s" % p)
            continue
        pak, how, data = found[p]
        dst = os.path.join(out, p.replace("/", os.sep))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "wb") as w:
            w.write(data)
        print("%s  <- %s (%s, %d B)" % (p, pak, how, len(data)))
    return 0 if len(found) == len(paths) else 1


if __name__ == "__main__":
    sys.exit(main())
