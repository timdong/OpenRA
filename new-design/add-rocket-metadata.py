from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "mods" / "reignition" / "bits"
SHEETS = {
    "daxia-rocket-walk.png": (240, 48),
    "daxia-rocket-attack.png": (160, 48),
    "daxia-rocket-idle.png": (160, 48),
}


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


for name, (frame_width, frame_height) in SHEETS.items():
    path = ASSETS / name
    data = path.read_bytes()
    frame_size = f"{frame_width // (6 if 'walk' in name else 4)},{frame_height}"
    frame_amount = 48 if "walk" in name else 32
    metadata = (
        chunk(b"tEXt", f"FrameSize\0{frame_size}".encode())
        + chunk(b"tEXt", f"FrameAmount\0{frame_amount}".encode())
        + chunk(b"tEXt", b"Offset\x000,0")
    )
    output = data[:8]
    offset = 8
    inserted = False
    while offset < len(data):
        length = struct.unpack(">I", data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        part = data[offset:offset + 12 + length]
        if kind == b"tEXt" and not inserted:
            offset += 12 + length
            continue
        if kind == b"IDAT" and not inserted:
            output += metadata
            inserted = True
        output += part
        offset += 12 + length
    path.write_bytes(output)
    print(f"Added animation metadata to {name}")
