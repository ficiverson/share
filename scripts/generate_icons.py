#!/usr/bin/env python3
"""
generate_icons.py — Genera todos los iconos de app para iOS, Android y Web
desde una imagen fuente (idealmente 1024x1024 o mayor).

Uso:
    python3 scripts/generate_icons.py icon_source.png

La imagen fuente debe estar en la raíz del proyecto o pasar la ruta completa.
"""

import sys
import os
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Instalando Pillow...")
    os.system("pip3 install Pillow --break-system-packages -q")
    from PIL import Image


def resize(img: Image.Image, size: int) -> Image.Image:
    return img.resize((size, size), Image.LANCZOS)


def save(img: Image.Image, path: Path, size: int):
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = resize(img, size)
    resized.save(str(path), "PNG", optimize=True)
    print(f"  ✓ {path.relative_to(ROOT)}  ({size}x{size})")


# ── Configuración ──────────────────────────────────────────────────────────────

ROOT = Path(__file__).parent.parent

IOS_DIR  = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
AND_DIR  = ROOT / "android/app/src/main/res"
WEB_DIR  = ROOT / "web"
MAC_DIR  = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset"

# iOS: filename → pixel size
IOS_ICONS = {
    "Icon-App-20x20@1x.png":      20,
    "Icon-App-20x20@2x.png":      40,
    "Icon-App-20x20@3x.png":      60,
    "Icon-App-29x29@1x.png":      29,
    "Icon-App-29x29@2x.png":      58,
    "Icon-App-29x29@3x.png":      87,
    "Icon-App-40x40@1x.png":      40,
    "Icon-App-40x40@2x.png":      80,
    "Icon-App-40x40@3x.png":     120,
    "Icon-App-60x60@2x.png":     120,
    "Icon-App-60x60@3x.png":     180,
    "Icon-App-76x76@1x.png":      76,
    "Icon-App-76x76@2x.png":     152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png":1024,
}

# Android: mipmap-folder → pixel size
ANDROID_ICONS = {
    "mipmap-mdpi":    48,
    "mipmap-hdpi":    72,
    "mipmap-xhdpi":   96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi":192,
}

# macOS
MAC_ICONS = {
    "app_icon_16.png":   16,
    "app_icon_32.png":   32,
    "app_icon_64.png":   64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png":1024,
}


def main():
    if len(sys.argv) < 2:
        # Busca automáticamente en la raíz
        candidates = list(ROOT.glob("icon*.png")) + list(ROOT.glob("Icon*.png")) + list(ROOT.glob("app_icon*.png"))
        if not candidates:
            print("Uso: python3 scripts/generate_icons.py <ruta_imagen_fuente.png>")
            sys.exit(1)
        src_path = candidates[0]
        print(f"Usando imagen encontrada: {src_path.name}")
    else:
        src_path = Path(sys.argv[1])
        if not src_path.is_absolute():
            src_path = ROOT / src_path

    if not src_path.exists():
        print(f"Error: no se encuentra {src_path}")
        sys.exit(1)

    img = Image.open(src_path).convert("RGBA")
    print(f"\nImagen fuente: {src_path.name} ({img.width}x{img.height})\n")

    # ── iOS ───────────────────────────────────────────────────────────────────
    print("iOS:")
    for filename, size in IOS_ICONS.items():
        save(img, IOS_DIR / filename, size)

    # ── Android ───────────────────────────────────────────────────────────────
    print("\nAndroid:")
    for folder, size in ANDROID_ICONS.items():
        save(img, AND_DIR / folder / "ic_launcher.png", size)
        save(img, AND_DIR / folder / "ic_launcher_round.png", size)

    # ── Web ───────────────────────────────────────────────────────────────────
    print("\nWeb:")
    save(img, WEB_DIR / "favicon.png",              32)
    save(img, WEB_DIR / "icons/Icon-192.png",      192)
    save(img, WEB_DIR / "icons/Icon-512.png",      512)
    save(img, WEB_DIR / "icons/Icon-maskable-192.png", 192)
    save(img, WEB_DIR / "icons/Icon-maskable-512.png", 512)

    # ── macOS ─────────────────────────────────────────────────────────────────
    print("\nmacOS:")
    for filename, size in MAC_ICONS.items():
        save(img, MAC_DIR / filename, size)

    print("\n✅ Todos los iconos generados correctamente.")


if __name__ == "__main__":
    main()
