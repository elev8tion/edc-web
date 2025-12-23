#!/usr/bin/env python3
"""
Generate PWA icons with gradient background and centered logo
Creates: Icon-192.png, Icon-512.png, Icon-maskable-192.png, Icon-maskable-512.png
"""

from PIL import Image
import os

# Paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ASSETS_DIR = os.path.join(PROJECT_ROOT, 'assets', 'images')
WEB_ICONS_DIR = os.path.join(PROJECT_ROOT, 'web', 'icons')

BACKGROUND_PATH = os.path.join(ASSETS_DIR, 'gradient_background.png')
LOGO_PATH = os.path.join(ASSETS_DIR, 'logo_transparent.png')

def create_pwa_icon(size, is_maskable=False):
    """
    Create a PWA icon with gradient background and centered logo

    Args:
        size: Icon size (192 or 512)
        is_maskable: If True, adds safe zone padding for maskable icons
    """
    # Load and resize background
    background = Image.open(BACKGROUND_PATH).convert('RGBA')
    background = background.resize((size, size), Image.Resampling.LANCZOS)

    # Load logo
    logo = Image.open(LOGO_PATH).convert('RGBA')

    # Calculate logo size
    # For maskable icons, use 60% of canvas (leaves 20% safe zone on each side)
    # For regular icons, use 80% of canvas
    logo_scale = 0.6 if is_maskable else 0.8
    logo_size = int(size * logo_scale)

    # Resize logo maintaining aspect ratio
    logo.thumbnail((logo_size, logo_size), Image.Resampling.LANCZOS)

    # Calculate position to center logo
    logo_x = (size - logo.width) // 2
    logo_y = (size - logo.height) // 2

    # Create final image
    final_image = background.copy()
    final_image.paste(logo, (logo_x, logo_y), logo)

    # Generate filename
    maskable_suffix = '-maskable' if is_maskable else ''
    filename = f'Icon{maskable_suffix}-{size}.png'
    output_path = os.path.join(WEB_ICONS_DIR, filename)

    # Save
    final_image.save(output_path, 'PNG', optimize=True)
    print(f'✅ Created: {filename} ({size}×{size})')

    return output_path

def main():
    # Ensure output directory exists
    os.makedirs(WEB_ICONS_DIR, exist_ok=True)

    print('🎨 Generating PWA icons with gradient background...\n')

    # Create all required icons
    create_pwa_icon(192, is_maskable=False)   # Icon-192.png
    create_pwa_icon(512, is_maskable=False)   # Icon-512.png
    create_pwa_icon(192, is_maskable=True)    # Icon-maskable-192.png
    create_pwa_icon(512, is_maskable=True)    # Icon-maskable-512.png

    print(f'\n✅ All PWA icons generated successfully!')
    print(f'📁 Location: {WEB_ICONS_DIR}')
    print('\n💡 Next steps:')
    print('   1. Run: flutter build web --release --no-tree-shake-icons')
    print('   2. Icons will be included in build/web/icons/')

if __name__ == '__main__':
    main()
