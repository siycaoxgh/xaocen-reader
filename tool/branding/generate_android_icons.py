"""Generate XAOCEN Android launcher assets from the checked-in ICO source.

The adaptive foreground deliberately contains only the orange mark on
transparent pixels. The white rounded background is supplied by the adaptive
icon XML, so Android does not mask an already-rounded bitmap a second time.
"""

from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets" / "branding" / "xaocen-reader-source.ico"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"


def orange_mask(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    mask = Image.new("L", image.size, 0)
    pixels = image.load()
    output = mask.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            saturation = max(r, g, b) - min(r, g, b)
            # The logo is the only strongly saturated orange object in the
            # source. White background, shadow, and transparent corners are
            # intentionally excluded.
            if a and r > 180 and r > g + 12 and g > b + 30:
                if saturation >= 70:
                    value = 255
                elif saturation <= 5:
                    value = 0
                else:
                    value = int((saturation - 5) * 255 / 65)
                output[x, y] = value
    return mask.filter(ImageFilter.GaussianBlur(radius=0.35))


def build_foreground(source: Image.Image) -> Image.Image:
    mask = orange_mask(source)
    bbox = mask.getbbox()
    if bbox is None:
        raise RuntimeError("orange logo was not found in the source ICO")
    logo = source.convert("RGBA").crop(bbox)
    logo_mask = mask.crop(bbox)
    # Android adaptive icons reserve a central safe zone. Keep the mark well
    # inside it so circular and squircle launchers do not cut its ends.  The
    # extra inset is intentional: Android applies the launcher mask after the
    # foreground is composed, so the visible white background must remain as
    # a clear safety ring around the orange mark instead of letting the mark
    # run right up to the mask edge.
    target_width = 196
    target_height = round(logo.height * target_width / logo.width)
    logo = logo.resize((target_width, target_height), Image.Resampling.LANCZOS)
    logo_mask = logo_mask.resize(
        (target_width, target_height), Image.Resampling.LANCZOS
    )
    logo.putalpha(logo_mask)
    foreground = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    foreground.alpha_composite(
        logo,
        ((foreground.width - logo.width) // 2, (foreground.height - logo.height) // 2),
    )
    return foreground


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    foreground = build_foreground(source)
    foreground_path = ANDROID_RES / "drawable-nodpi" / "ic_launcher_foreground.png"
    foreground_path.parent.mkdir(parents=True, exist_ok=True)
    foreground.save(foreground_path, optimize=True)

    for density, size in {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }.items():
        destination = ANDROID_RES / f"mipmap-{density}" / "ic_launcher.png"
        destination.parent.mkdir(parents=True, exist_ok=True)
        source.resize((size, size), Image.Resampling.LANCZOS).save(
            destination, optimize=True
        )


if __name__ == "__main__":
    main()
