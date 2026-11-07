"""Build the two-rotor helicopter sprites from the supplied layers (Pillow)."""

from pathlib import Path

from PIL import Image, ImageChops, PngImagePlugin


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "new-design/source-assets/reignition-nhaw/large"
OUTPUT = ROOT / "mods/reignition/bits"
FRAME_SIZE = 128
FAST_FRAME_COUNT = 24
SLOW_FRAME_COUNT = 12
SHEET_COLUMNS = 12
FAST_STEP_DEGREES = 75
BODY_OFFSET = (40, 0)
HUBS = ((268, 254), (855, 561))
CANVAS_SIZE = (1140, 1050)
RESAMPLE = Image.Resampling.LANCZOS


def alpha_scaled(image, opacity):
    result = image.copy()
    result.putalpha(image.getchannel("A").point(lambda value: round(value * opacity)))
    return result


def build():
    body = Image.open(SOURCE / "nhaw-body.png").convert("RGBA")
    blade = Image.open(SOURCE / "nhaw-rotor.png").convert("RGBA")
    assert body.size == (1024, 1024) and blade.size == (974, 974)
    # The source's lower-left label is outside the aircraft.
    body.paste((0, 0, 0, 0), (0, 922, 276, 1024))
    body_canvas = Image.new("RGBA", CANVAS_SIZE)
    body_canvas.alpha_composite(body, BODY_OFFSET)

    # Center on the source rotor hub, then rectify its diagonal axis before
    # applying rotation and the foreshortening of a horizontal rotor disk.
    centered = Image.new("RGBA", (1500, 1500))
    centered.alpha_composite(blade, (750 - 474, 750 - 505))
    centered = centered.rotate(-45, resample=Image.Resampling.BICUBIC)
    centered = centered.resize((480, 480), RESAMPLE)

    def rotor_at(angle):
        return centered.rotate(angle, resample=Image.Resampling.BICUBIC).resize((480, 250), RESAMPLE)

    def overlay(frame, fast):
        result = Image.new("RGBA", CANVAS_SIZE)
        for hub, direction in zip(HUBS, (1, -1)):
            # Keep one displayed frame per engine tick. A shorter sequence tick
            # skips frames and can make two-bladed rotors appear to slow/reverse.
            step = FAST_STEP_DEGREES if fast else 360 / SLOW_FRAME_COUNT
            angle = direction * frame * step
            disk = Image.new("RGBA", (480, 250))
            if fast:
                for lag, opacity in ((50, 0.08), (40, 0.10), (30, 0.13), (20, 0.18), (10, 0.25)):
                    disk.alpha_composite(alpha_scaled(rotor_at(angle - direction * lag), opacity))
            disk.alpha_composite(rotor_at(angle))
            result.alpha_composite(disk, (hub[0] - 240, hub[1] - 125))
        return result

    overlays = [overlay(frame, True) for frame in range(FAST_FRAME_COUNT)]
    overlays += [overlay(frame, False) for frame in range(SLOW_FRAME_COUNT)]
    # Use one common crop/scale for every layer so neither hub can drift.
    union = body_canvas.getchannel("A")
    for image in overlays:
        union = ImageChops.lighter(union, image.getchannel("A"))
    left, top, right, bottom = union.getbbox()
    bounds = (max(0, left - 3), max(0, top - 3), min(CANVAS_SIZE[0], right + 3), min(CANVAS_SIZE[1], bottom + 3))
    scale = min(116 / (bounds[2] - bounds[0]), 116 / (bounds[3] - bounds[1]))
    size = (round((bounds[2] - bounds[0]) * scale), round((bounds[3] - bounds[1]) * scale))
    position = ((FRAME_SIZE - size[0]) // 2, (FRAME_SIZE - size[1]) // 2)

    def fit(image):
        result = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
        result.alpha_composite(image.crop(bounds).resize(size, RESAMPLE), position)
        return result

    body_frame = fit(body_canvas)
    frames = [fit(image) for image in overlays]
    OUTPUT.mkdir(parents=True, exist_ok=True)
    body_frame.save(OUTPUT / "reignition-mh60.png")
    rows = (len(frames) + SHEET_COLUMNS - 1) // SHEET_COLUMNS
    sheet = Image.new("RGBA", (FRAME_SIZE * SHEET_COLUMNS, FRAME_SIZE * rows))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, ((index % SHEET_COLUMNS) * FRAME_SIZE, (index // SHEET_COLUMNS) * FRAME_SIZE))
    metadata = PngImagePlugin.PngInfo()
    metadata.add_text("FrameSize", "128,128")
    metadata.add_text("FrameAmount", str(len(frames)))
    metadata.add_text("Offset", "0,0")
    sheet.save(OUTPUT / "reignition-mh60-rotors.png", pnginfo=metadata)

    full = Image.alpha_composite(body_canvas, overlays[FAST_FRAME_COUNT])
    icon = full.crop(bounds)
    icon.thumbnail((58, 44), RESAMPLE)
    icon_frame = Image.new("RGBA", (64, 48))
    icon_frame.alpha_composite(icon, ((64 - icon.width) // 2, (48 - icon.height) // 2))
    icon_frame.save(OUTPUT / "reignition-mh60-icon.png")

    previews = []
    for frame in frames[:FAST_FRAME_COUNT]:
        composite = Image.alpha_composite(body_frame, frame)
        background = Image.new("RGBA", composite.size, (22, 30, 39, 255))
        background.alpha_composite(composite)
        previews.append(background.convert("RGB").resize((384, 384), Image.Resampling.NEAREST))
    previews[0].save(
        ROOT / "new-design/nhaw-rotor-preview.gif",
        save_all=True, append_images=previews[1:], duration=40, loop=0, disposal=2,
    )
    # Ensure there is actual animation, and nothing touches a frame's edges.
    assert FAST_FRAME_COUNT * FAST_STEP_DEGREES % 360 == 0
    assert len({frame.tobytes() for frame in frames[:FAST_FRAME_COUNT]}) == FAST_FRAME_COUNT
    for frame in [body_frame, *frames]:
        box = frame.getbbox()
        assert box and box[0] > 0 and box[1] > 0 and box[2] < FRAME_SIZE and box[3] < FRAME_SIZE
    print("Built aligned helicopter body, 24 fast + 12 slow rotor frames, icon and animated preview.")


if __name__ == "__main__":
    build()
