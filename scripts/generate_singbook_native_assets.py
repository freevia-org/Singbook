"""Package the approved transparent Singbook mark into native app assets.

The original transparent book-and-note image is kept intact. Standard app
icons place it on the approved navy tile with an 86% canvas fit. Android's
adaptive foreground and monochrome mask use a centered 66% fit so the complete
mark stays inside the launcher mask's safe region. The existing wordmark files
are intentionally left untouched; this script only regenerates icon/splash
artwork.
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRANDING = ROOT / "assets" / "branding"
DEFAULT_FOREGROUND = BRANDING / "singbook-mark-foreground.png"
NAVY = (8, 27, 51)  # #081B33, the approved flat tile color.
CANVAS_EDGE = 1024
STANDARD_MARK_EDGE = round(CANVAS_EDGE * 0.86)
ANDROID_SAFE_EDGE = round(CANVAS_EDGE * 0.66)

ANDROID_DENSITIES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}
IOS_ICONS = [
    ("20x20", 2, "Icon-App-20x20@2x.png"),
    ("20x20", 3, "Icon-App-20x20@3x.png"),
    ("29x29", 1, "Icon-App-29x29@1x.png"),
    ("29x29", 2, "Icon-App-29x29@2x.png"),
    ("29x29", 3, "Icon-App-29x29@3x.png"),
    ("40x40", 2, "Icon-App-40x40@2x.png"),
    ("40x40", 3, "Icon-App-40x40@3x.png"),
    ("60x60", 2, "Icon-App-60x60@2x.png"),
    ("60x60", 3, "Icon-App-60x60@3x.png"),
    ("20x20", 1, "Icon-App-20x20@1x.png"),
    ("29x29", 1, "Icon-App-29x29@1x.png"),
    ("40x40", 1, "Icon-App-40x40@1x.png"),
    ("76x76", 1, "Icon-App-76x76@1x.png"),
    ("76x76", 2, "Icon-App-76x76@2x.png"),
    ("83.5x83.5", 2, "Icon-App-83.5x83.5@2x.png"),
    ("1024x1024", 1, "Icon-App-1024x1024@1x.png"),
]


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)


def fit_contain(image: Image.Image, edge: int) -> Image.Image:
    image = image.convert("RGBA")
    image.thumbnail((edge, edge), Image.Resampling.LANCZOS)
    return image


def read_mark(foreground_path: Path) -> Image.Image:
    image = Image.open(foreground_path).convert("RGBA")
    alpha_bounds = image.getchannel("A").getbbox()
    if alpha_bounds is None:
        raise ValueError(f"Foreground has no visible artwork: {foreground_path}")
    return image.crop(alpha_bounds)


def place_centered(mark: Image.Image, edge: int, mark_edge: int) -> Image.Image:
    canvas = Image.new("RGBA", (edge, edge), (0, 0, 0, 0))
    fitted = fit_contain(mark, mark_edge)
    offset = ((edge - fitted.width) // 2, (edge - fitted.height) // 2)
    canvas.alpha_composite(fitted, offset)
    return canvas


def make_canonical_icon(mark: Image.Image) -> Image.Image:
    tile = Image.new("RGBA", (CANVAS_EDGE, CANVAS_EDGE), (*NAVY, 255))
    tile.alpha_composite(place_centered(mark, CANVAS_EDGE, STANDARD_MARK_EDGE))
    save_png(tile.convert("RGB"), BRANDING / "singbook-icon.png")
    return tile.convert("RGB")


def make_adaptive_foreground(mark: Image.Image) -> Image.Image:
    foreground = place_centered(mark, CANVAS_EDGE, ANDROID_SAFE_EDGE)
    save_png(foreground, BRANDING / "singbook-android-foreground.png")
    return foreground


def make_monochrome(mark: Image.Image) -> Image.Image:
    placed = place_centered(mark, CANVAS_EDGE, ANDROID_SAFE_EDGE)
    monochrome = Image.new("RGBA", placed.size, (255, 255, 255, 0))
    monochrome.putalpha(placed.getchannel("A"))
    # Confirm both the note in the upper half and the book in the lower half
    # survive in the single-color launcher mask.
    alpha = monochrome.getchannel("A")
    upper = alpha.crop((0, 0, CANVAS_EDGE, CANVAS_EDGE // 2)).getbbox()
    lower = alpha.crop((0, CANVAS_EDGE // 2, CANVAS_EDGE, CANVAS_EDGE)).getbbox()
    if upper is None or lower is None:
        raise ValueError("Monochrome mask must retain both the note and book")
    save_png(monochrome, BRANDING / "singbook-android-monochrome.png")
    return monochrome


def write_resized(image: Image.Image, path: Path, edge: int) -> None:
    save_png(image.resize((edge, edge), Image.Resampling.LANCZOS), path)


def generate(foreground_path: Path) -> None:
    mark = read_mark(foreground_path)
    icon = make_canonical_icon(mark)
    foreground = make_adaptive_foreground(mark)
    monochrome = make_monochrome(mark)

    for density, edge in ANDROID_DENSITIES.items():
        write_resized(
            icon,
            ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{density}" / "ic_launcher.png",
            edge,
        )

    android_resources = ROOT / "android" / "app" / "src" / "main" / "res"
    shutil.copyfile(
        BRANDING / "singbook-android-foreground.png",
        android_resources / "drawable-nodpi" / "singbook_adaptive_foreground.png",
    )
    save_png(monochrome, android_resources / "drawable-nodpi" / "singbook_adaptive_monochrome.png")
    write_resized(icon, android_resources / "drawable" / "singbook_splash.png", 288)

    app_icon_set = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for logical_size, scale, filename in IOS_ICONS:
        edge = round(float(logical_size.split("x")[0]) * scale)
        write_resized(icon, app_icon_set / filename, edge)

    launch_images = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    for filename in ("LaunchImage.png", "LaunchImage@2x.png", "LaunchImage@3x.png"):
        write_resized(icon, launch_images / filename, CANVAS_EDGE)

    # Emit a checkerboard-free preview for visual review at launcher sizes.
    preview = Image.new("RGBA", (48 * 3, 48), (*NAVY, 255))
    preview.alpha_composite(foreground.resize((48, 48), Image.Resampling.LANCZOS).convert("RGBA"), (0, 0))
    preview.alpha_composite(monochrome.resize((48, 48), Image.Resampling.LANCZOS), (48, 0))
    preview.paste(icon.resize((48, 48), Image.Resampling.LANCZOS), (96, 0))
    save_png(preview.convert("RGB"), BRANDING / "singbook-icon-preview-48.png")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--artwork",
        type=Path,
        default=DEFAULT_FOREGROUND,
        help="approved transparent book-and-note foreground image",
    )
    args = parser.parse_args()
    generate(args.artwork)


if __name__ == "__main__":
    main()
