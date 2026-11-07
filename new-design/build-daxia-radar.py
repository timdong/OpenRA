"""Build the Reignition radar badge from the supplied Daxia reference (Pillow)."""

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "new-design/daxia-emblem-reference.png"
OUTPUT = ROOT / "mods/reignition/uibits"


def extract_emblem():
    # Trace the outer ring and the star tip. A silhouette mask preserves the
    # badge's dark interior while excluding the caption and corner text.
    image = Image.open(SOURCE).convert("RGBA")
    assert image.size == (463, 501), "Update the mask for a different reference."
    alpha = Image.new("L", (image.width * 4, image.height * 4))
    draw = ImageDraw.Draw(alpha)
    draw.ellipse(tuple(v * 4 for v in (28, 26, 415, 404)), fill=255)
    draw.polygon([(x * 4, y * 4) for x, y in ((221, 16), (233, 32), (210, 32))], fill=255)
    alpha = alpha.resize(image.size, Image.Resampling.LANCZOS)
    image.putalpha(alpha)
    return image.crop(alpha.getbbox())


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    emblem = extract_emblem()
    emblem.save(OUTPUT / "daxia-emblem.png")

    original = Image.open(ROOT / "mods/ra/uibits/sidebar.png").convert("RGBA")
    sidebar = original.copy()
    badge = emblem.copy()
    badge.thumbnail((200, 200), Image.Resampling.LANCZOS)
    position = ((222 - badge.width) // 2, (222 - badge.height) // 2)

    # The replacement must cover the old Allied triangle completely.
    coverage = Image.new("L", (222, 222))
    coverage.paste(badge.getchannel("A"), position)
    old_logo = Image.new("L", (222, 222))
    ImageDraw.Draw(old_logo).polygon(((42, 60), (181, 60), (111, 172)), fill=255)
    assert all(not old or new == 255 for old, new in zip(old_logo.tobytes(), coverage.tobytes()))

    sidebar.alpha_composite(badge, (290 + position[0], 67 + position[1]))
    sidebar.save(OUTPUT / "sidebar.png")
    sidebar.crop((290, 67, 512, 289)).save(ROOT / "new-design/daxia-radar-preview.png")
    print("Built Daxia radar badge and Reignition sidebar atlas.")


if __name__ == "__main__":
    main()
