"""Deploy AppIcons pack to all platform targets with black background."""
from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "icons" / "AppIcons (1)"
IOS_SRC = SRC / "Assets.xcassets" / "AppIcon.appiconset" / "_"
IOS_DST = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

BLACK = (0, 0, 0, 255)
TRANSPARENT = (0, 0, 0, 0)
# Logo ocupa ~58% del canvas (zona segura Android ~66%; un poco más pequeño).
LOGO_SCALE = 0.58

IOS_MAP = {
    "40.png": "Icon-App-20x20@2x.png",
    "60.png": "Icon-App-20x20@3x.png",
    "29.png": "Icon-App-29x29@1x.png",
    "58.png": "Icon-App-29x29@2x.png",
    "87.png": "Icon-App-29x29@3x.png",
    "80.png": "Icon-App-40x40@2x.png",
    "120.png": "Icon-App-40x40@3x.png",
    "57.png": "Icon-App-57x57@1x.png",
    "114.png": "Icon-App-57x57@2x.png",
    "120.png": "Icon-App-60x60@2x.png",
    "180.png": "Icon-App-60x60@3x.png",
    "20.png": "Icon-App-20x20@1x.png",
    "50.png": "Icon-App-50x50@1x.png",
    "100.png": "Icon-App-50x50@2x.png",
    "72.png": "Icon-App-72x72@1x.png",
    "144.png": "Icon-App-72x72@2x.png",
    "76.png": "Icon-App-76x76@1x.png",
    "152.png": "Icon-App-76x76@2x.png",
    "167.png": "Icon-App-83.5x83.5@2x.png",
    "1024.png": "Icon-App-1024x1024@1x.png",
}

MIPMAP_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

FG_SIZES = {
    "mdpi": 108,
    "hdpi": 162,
    "xhdpi": 216,
    "xxhdpi": 324,
    "xxxhdpi": 432,
}

MAC_MAP = {
    "16.png": "app_icon_16.png",
    "32.png": "app_icon_32.png",
    "64.png": "app_icon_64.png",
    "128.png": "app_icon_128.png",
    "256.png": "app_icon_256.png",
    "512.png": "app_icon_512.png",
    "1024.png": "app_icon_1024.png",
}


def _is_background(r: int, g: int, b: int, a: int) -> bool:
    if a < 16:
        return True
    return r > 220 and g > 220 and b > 220


def to_black_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    out = Image.new("RGBA", image.size, BLACK)
    src = image.load()
    dst = out.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = src[x, y]
            if not _is_background(r, g, b, a):
                dst[x, y] = (r, g, b, 255)
    return out


def to_adaptive_foreground(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    src = image.load()
    dst = out.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = src[x, y]
            if not _is_background(r, g, b, a):
                dst[x, y] = (r, g, b, 255)
    return out


def _extract_logo(image: Image.Image) -> Image.Image:
    logo = to_adaptive_foreground(image)
    bbox = logo.getbbox()
    return logo.crop(bbox) if bbox else logo


def compose_scaled_icon(
    image: Image.Image,
    canvas_size: int,
    scale: float,
    background: tuple[int, int, int, int],
) -> Image.Image:
    logo = _extract_logo(image)
    target_max = max(1, int(canvas_size * scale))
    logo = logo.copy()
    logo.thumbnail((target_max, target_max), Image.Resampling.LANCZOS)

    out = Image.new("RGBA", (canvas_size, canvas_size), background)
    x = (canvas_size - logo.width) // 2
    y = (canvas_size - logo.height) // 2
    out.paste(logo, (x, y), logo)
    return out


def build_launcher_icon(image: Image.Image, canvas_size: int = 1024) -> Image.Image:
    return compose_scaled_icon(image, canvas_size, LOGO_SCALE, BLACK)


def build_foreground_icon(image: Image.Image, canvas_size: int = 1024) -> Image.Image:
    return compose_scaled_icon(image, canvas_size, LOGO_SCALE, TRANSPARENT)


def load_source() -> Image.Image:
    source_path = IOS_SRC / "1024.png"
    if not source_path.exists():
        source_path = SRC / "appstore.png"
    return Image.open(source_path).convert("RGBA")


def deploy_android_mipmaps(full_icon: Image.Image) -> None:
    for dpi, size in MIPMAP_SIZES.items():
        resized = full_icon.resize((size, size), Image.Resampling.LANCZOS)
        dst = ROOT / "android" / "app" / "src" / "main" / "res" / f"mipmap-{dpi}" / "ic_launcher.png"
        resized.save(dst)
        print(f"android mipmap-{dpi}")


def deploy_android_foregrounds(foreground: Image.Image) -> None:
    for dpi, size in FG_SIZES.items():
        resized = foreground.resize((size, size), Image.Resampling.LANCZOS)
        dst = ROOT / "android" / "app" / "src" / "main" / "res" / f"drawable-{dpi}" / "ic_launcher_foreground.png"
        resized.save(dst)
        print(f"android foreground {dpi}")


def deploy_ios(source: Image.Image) -> None:
    for src_name, dst_name in IOS_MAP.items():
        src = IOS_SRC / src_name
        size = Image.open(src).size[0]
        build_launcher_icon(source, size).save(IOS_DST / dst_name)
    print("ios icons")


def deploy_web(full_icon: Image.Image) -> None:
    web = ROOT / "web"
    full_icon.resize((512, 512), Image.Resampling.LANCZOS).save(web / "icons" / "Icon-512.png")
    full_icon.resize((512, 512), Image.Resampling.LANCZOS).save(web / "icons" / "Icon-maskable-512.png")
    full_icon.resize((192, 192), Image.Resampling.LANCZOS).save(web / "icons" / "Icon-192.png")
    full_icon.resize((192, 192), Image.Resampling.LANCZOS).save(web / "icons" / "Icon-maskable-192.png")
    full_icon.resize((32, 32), Image.Resampling.LANCZOS).save(web / "favicon.png")
    print("web icons")


def deploy_macos(source: Image.Image) -> None:
    dst_dir = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for src_name, dst_name in MAC_MAP.items():
        size = Image.open(IOS_SRC / src_name).size[0]
        build_launcher_icon(source, size).save(dst_dir / dst_name)
    print("macos icons")


def deploy_windows(full_icon: Image.Image) -> None:
    ico_path = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    images = [full_icon.resize(size, Image.Resampling.LANCZOS) for size in sizes]
    images[0].save(
        ico_path,
        format="ICO",
        sizes=[(img.width, img.height) for img in images],
        append_images=images[1:],
    )
    print("windows ico")


def deploy_flutter_assets(full_icon: Image.Image, foreground: Image.Image) -> None:
    assets = ROOT / "assets" / "icons"
    full_icon.save(assets / "app_icon.png")
    foreground.save(assets / "app_icon_foreground.png")
    full_icon.resize((512, 512), Image.Resampling.LANCZOS).save(assets / "app_icon_playstore.png")
    print("flutter asset icons")


def update_web_manifest() -> None:
    manifest_path = ROOT / "web" / "manifest.json"
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    data["name"] = "Battery Guardian"
    data["short_name"] = "Battery Guardian"
    data["description"] = "Monitoreo inteligente de batería y salud del dispositivo."
    data["background_color"] = "#000000"
    data["theme_color"] = "#000000"
    manifest_path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
    print("web manifest")


def main() -> None:
    source = load_source()
    full_icon = build_launcher_icon(source, 1024)
    foreground = build_foreground_icon(source, 1024)

    deploy_flutter_assets(full_icon, foreground)
    deploy_android_mipmaps(full_icon)
    deploy_android_foregrounds(foreground)
    deploy_ios(source)
    deploy_web(full_icon)
    deploy_macos(source)
    deploy_windows(full_icon)
    update_web_manifest()
    print("Done.")


if __name__ == "__main__":
    main()
