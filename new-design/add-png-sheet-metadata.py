from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "mods" / "reignition" / "bits"
VEHICLES = [
    "crimson-xingtian.png",
    "allied-prism.png",
    "daxia-houyi.png",
    "crimson-thunderbolt.png",
    "daxia-chidian.png",
    "allied-hound.png",
    "reignition-mcv.png",
]


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


for name in VEHICLES:
    path = ASSETS / name
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"Not a PNG: {path}")

    metadata = chunk(b"tEXt", b"FrameSize\x0064,56") + chunk(b"tEXt", b"FrameAmount\x0016") + chunk(b"tEXt", b"Offset\x000,0")
    output = data[:8]
    offset = 8
    inserted = False
    while offset < len(data):
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        part = data[offset:offset + 12 + length]
        if kind == b"tEXt" and not inserted:
            continue
        if kind == b"IDAT" and not inserted:
            output += metadata
            inserted = True
        output += part
        offset += 12 + length

    path.write_bytes(output)
    print(f"Added 8-direction, 2-frame metadata to {name}")
