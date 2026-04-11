#!/usr/bin/env python3
"""Downscale a PNG so both dimensions are ≤ max_dim (default 1000px).

Pure stdlib — no Pillow or external deps required.
Uses nearest-neighbor sampling for speed (fine for screenshots).

Usage: resize-screenshot.py [input.png] [output.png] [max_dim]
"""
import struct
import sys
import zlib


def read_png(path):
    with open(path, "rb") as f:
        sig = f.read(8)
        if sig != b"\x89PNG\r\n\x1a\n":
            raise ValueError("Not a PNG file")
        chunks = []
        while True:
            raw = f.read(8)
            if len(raw) < 8:
                break
            length, ctype = struct.unpack(">I4s", raw)
            data = f.read(length)
            _crc = f.read(4)
            chunks.append((ctype, data))
    # Parse IHDR
    ihdr = next(d for t, d in chunks if t == b"IHDR")
    w, h, bit_depth, color_type = struct.unpack(">IIBB", ihdr[:10])
    if bit_depth != 8:
        raise ValueError(f"Unsupported bit depth: {bit_depth}")
    if color_type == 2:
        bpp = 3  # RGB
    elif color_type == 6:
        bpp = 4  # RGBA
    else:
        raise ValueError(f"Unsupported color type: {color_type}")
    # Decompress IDAT
    idat = b"".join(d for t, d in chunks if t == b"IDAT")
    raw = zlib.decompress(idat)
    # Unfilter
    stride = w * bpp
    rows = []
    pos = 0
    prev_row = bytes(stride)
    for _y in range(h):
        filt = raw[pos]
        pos += 1
        row_data = bytearray(raw[pos : pos + stride])
        pos += stride
        if filt == 0:  # None
            pass
        elif filt == 1:  # Sub
            for i in range(bpp, stride):
                row_data[i] = (row_data[i] + row_data[i - bpp]) & 0xFF
        elif filt == 2:  # Up
            for i in range(stride):
                row_data[i] = (row_data[i] + prev_row[i]) & 0xFF
        elif filt == 3:  # Average
            for i in range(stride):
                a = row_data[i - bpp] if i >= bpp else 0
                row_data[i] = (row_data[i] + (a + prev_row[i]) // 2) & 0xFF
        elif filt == 4:  # Paeth
            for i in range(stride):
                a = row_data[i - bpp] if i >= bpp else 0
                b = prev_row[i]
                c = prev_row[i - bpp] if i >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                if pa <= pb and pa <= pc:
                    pr = a
                elif pb <= pc:
                    pr = b
                else:
                    pr = c
                row_data[i] = (row_data[i] + pr) & 0xFF
        rows.append(bytes(row_data))
        prev_row = row_data
    return w, h, bpp, color_type, rows


def write_png(path, w, h, bpp, color_type, rows):
    def chunk(ctype, data):
        c = struct.pack(">I", len(data)) + ctype + data
        return c + struct.pack(">I", zlib.crc32(ctype + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBB3B", w, h, 8, color_type, 0, 0, 0)
    raw_data = bytearray()
    for row in rows:
        raw_data.append(0)  # filter: None
        raw_data.extend(row)
    compressed = zlib.compress(bytes(raw_data), 9)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", compressed))
        f.write(chunk(b"IEND", b""))


def resize(src, dst, max_dim=1000):
    w, h, bpp, color_type, rows = read_png(src)
    if w <= max_dim and h <= max_dim:
        # Already small enough — just copy
        import shutil
        shutil.copy2(src, dst)
        return w, h
    scale = min(max_dim / w, max_dim / h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    new_rows = []
    for ny in range(nh):
        oy = min(int(ny / scale), h - 1)
        src_row = rows[oy]
        new_row = bytearray(nw * bpp)
        for nx in range(nw):
            ox = min(int(nx / scale), w - 1)
            new_row[nx * bpp : (nx + 1) * bpp] = src_row[ox * bpp : (ox + 1) * bpp]
        new_rows.append(bytes(new_row))
    write_png(dst, nw, nh, bpp, color_type, new_rows)
    return nw, nh


if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "/tmp/test_screen_raw.png"
    dst = sys.argv[2] if len(sys.argv) > 2 else "/tmp/test_screen.png"
    max_dim = int(sys.argv[3]) if len(sys.argv) > 3 else 1000
    nw, nh = resize(src, dst, max_dim)
    print(f"{nw}x{nh}")
