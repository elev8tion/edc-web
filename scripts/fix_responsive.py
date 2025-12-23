#!/usr/bin/env python3
"""
Batch convert fixed font sizes to responsive sizing across all Flutter screens.
"""

import re
import os
from pathlib import Path

# Screens to update
SCREENS = [
    'auth_screen.dart',
    'onboarding_screen.dart',
    'splash_screen.dart',
    'reading_plan_screen.dart',
    'profile_screen.dart',
    'prayer_journal_screen.dart',
    'settings_screen.dart',
    'daily_verse_screen.dart',
    'verse_library_screen.dart',
    'chat_screen.dart',
]

SCREENS_DIR = Path('/Users/kcdacre8tor/ everyday-christian/lib/screens')

# Font size mappings: base_size -> (minSize, maxSize)
FONT_SIZE_MAP = {
    6: (5, 7),
    8: (7, 9),
    9: (8, 11),
    10: (9, 12),
    11: (9, 13),
    12: (10, 14),
    13: (11, 15),
    14: (12, 16),
    15: (13, 17),
    16: (14, 18),
    18: (16, 20),
    20: (18, 24),
    22: (19, 26),
    24: (20, 28),
    26: (22, 30),
    28: (24, 32),
    30: (26, 34),
    32: (28, 36),
    36: (30, 40),
    40: (34, 46),
    48: (40, 54),
    64: (54, 72),
}

# Icon size mappings
ICON_SIZE_MAP = {
    12: (11, 14),
    14: (12, 16),
    16: (14, 18),
    18: (16, 20),
    20: (18, 22),
    22: (20, 24),
    24: (21, 27),
    28: (24, 32),
    32: (28, 36),
    36: (32, 40),
    40: (36, 44),
    48: (42, 54),
    64: (56, 72),
}

def add_import_if_missing(content):
    """Add responsive utils import if not present."""
    if 'responsive_utils.dart' in content:
        return content

    # Find the last import statement
    import_pattern = r"(import ['\"].*?['\"];)"
    imports = list(re.finditer(import_pattern, content))

    if imports:
        last_import = imports[-1]
        insert_pos = last_import.end()
        new_import = "\nimport '../utils/responsive_utils.dart';"
        content = content[:insert_pos] + new_import + content[insert_pos:]

    return content

def convert_font_sizes(content):
    """Convert fixed fontSize to ResponsiveUtils.fontSize."""

    # Pattern: fontSize: 24,  or  fontSize: 24.0,
    pattern = r'fontSize:\s*(\d+)(?:\.0)?\s*,'

    def replace_font_size(match):
        size = int(match.group(1))
        min_size, max_size = FONT_SIZE_MAP.get(size, (int(size * 0.85), int(size * 1.15)))
        return f'fontSize: ResponsiveUtils.fontSize(context, {size}, minSize: {min_size}, maxSize: {max_size}),'

    content = re.sub(pattern, replace_font_size, content)

    return content

def convert_icon_sizes(content):
    """Convert fixed icon sizes to ResponsiveUtils.iconSize."""

    # Pattern: size: 24,  or  size: 24.0,  (inside Icon widgets)
    pattern = r'(Icon\([^)]+?size:\s*)(\d+)(?:\.0)?(\s*,)'

    def replace_icon_size(match):
        prefix = match.group(1)
        size = int(match.group(2))
        suffix = match.group(3)
        return f'{prefix}ResponsiveUtils.iconSize(context, {size}){suffix}'

    content = re.sub(pattern, replace_icon_size, content)

    return content

def convert_const_to_non_const(content):
    """Convert const TextStyle to TextStyle where ResponsiveUtils is used."""

    # Find TextStyle with ResponsiveUtils and remove const
    pattern = r'const\s+(TextStyle\([^)]*ResponsiveUtils[^)]*\))'
    content = re.sub(pattern, r'\1', content)

    # Also handle const Text with ResponsiveUtils in style
    pattern2 = r'const\s+(Text\([^;]*?style:\s*TextStyle\([^)]*ResponsiveUtils[^)]*\)[^;]*?\))'
    content = re.sub(pattern2, r'\1', content)

    return content

def process_file(filepath):
    """Process a single Dart file."""
    print(f"Processing {filepath.name}...")

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Add import
    content = add_import_if_missing(content)

    # Convert sizes
    content = convert_font_sizes(content)
    content = convert_icon_sizes(content)
    content = convert_const_to_non_const(content)

    # Only write if changed
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"  ✓ Updated {filepath.name}")
        return True
    else:
        print(f"  - No changes needed for {filepath.name}")
        return False

def main():
    """Main entry point."""
    print("Starting batch responsive conversion...\n")

    updated_count = 0

    for screen_name in SCREENS:
        filepath = SCREENS_DIR / screen_name
        if filepath.exists():
            if process_file(filepath):
                updated_count += 1
        else:
            print(f"  ⚠ File not found: {screen_name}")

    print(f"\n✓ Complete! Updated {updated_count}/{len(SCREENS)} files.")

if __name__ == '__main__':
    main()
