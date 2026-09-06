"""rtex_author.py - write an RE Engine render-target texture descriptor (.rtex.5) of any size.

    python rtex_author.py <width> <height> <out file> [dxgi format, default 29]

The shipped movie targets are 64-byte descriptors, nothing more -- no pixels, the engine
allocates the surface at load. Layout, read off the five shipped movie/rtex files and
mirror_env.rtex on 2026-09-06 (all six identical except the three fields marked *):

    0x00  "RTEX"            magic
    0x04  u32 5             version (the ".5" suffix on the path)
    0x08  u32 4             constant in all six (type/dimension; 2D texture is the reading)
    0x0C  u32 format *      DXGI_FORMAT: 29 = R8G8B8A8_UNORM_SRGB (movie targets; the plugin's
                            first-source "fmt=29" latch), 26 = R11G11B10_FLOAT (mirror_env)
    0x10  u32 width *
    0x14  u32 height *       NOTE: the shipped movie files carry the NAME's height + 8 rows
                            (movie_1920_1080 -> 1920x1088, movie_1280_720 -> 1280x728; the
                            "padded" sizes the plugin latch sees were never runtime rounding,
                            they are in the file). movie_1144_1048 is 1144x808 and mirror_env
                            is 1024x1024, so the name is not a contract. Give the height you
                            want allocated; the authored 2560/3840 targets follow the +8 rule
                            (1448 / 2168) so their aspect matches the shipped ones (1.765).
                            Authoring 1920 1088 and 1280 728 reproduces the shipped files
                            byte for byte `[verified-numerically 2026-09-06]`.
    0x18  u32 1             depth / array size
    0x1C  u32 0
    0x20  u32 0
    0x24  u32 1             mip count
    0x28  u32 0, 0x2C u32 0, 0x30 u32 0
    0x34  f32 1.0
    0x38  f32 1.0
    0x3C  u32 0

Field meanings for 0x08 / 0x18-0x3C are `[inferred-static 2026-09-06]` from the values alone;
width / height / format are pinned by three files with three different sizes and one with a
different format. Whether the engine ACCEPTS a size it never shipped is the launch's question.

Drop the result under the game's natives/stm/<path>.rtex.5 (REFramework's LooseFileLoader
serves natives/ ahead of the pak) and request it from Lua with the natives/stm/ prefix and
the .5 suffix stripped, e.g. movie/rtex/movie_2560_1440.rtex. Nothing from the game is copied
by this script; it writes the structure above from the numbers you give it.
"""
import struct
import sys


def rtex_bytes(width, height, fmt=29):
    return (b"RTEX"
            + struct.pack("<IIIII", 5, 4, fmt, width, height)
            + struct.pack("<IIIIIII", 1, 0, 0, 1, 0, 0, 0)
            + struct.pack("<ffI", 1.0, 1.0, 0))


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        return 2
    w, h, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    fmt = int(sys.argv[4]) if len(sys.argv) > 4 else 29
    data = rtex_bytes(w, h, fmt)
    assert len(data) == 64
    with open(out, "wb") as f:
        f.write(data)
    print("%s: %dx%d fmt=%d, 64 B" % (out, w, h, fmt))
    return 0


if __name__ == "__main__":
    sys.exit(main())
