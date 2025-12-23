#!/usr/bin/env python3
"""
Fix const Icon issues introduced by the responsive conversion.
Remove 'const' keyword from Icon widgets that use ResponsiveUtils.
"""

import re
from pathlib import Path

SCREENS_DIR = Path('/Users/kcdacre8tor/ everyday-christian/lib/screens')

def fix_const_icons(content):
    """Remove const from Icon widgets that use ResponsiveUtils."""
    # Pattern: const Icon(...ResponsiveUtils...)
    # Need to handle multiline
    pattern = r'const\s+(Icon\s*\([^)]*ResponsiveUtils[^)]*\))'
    content = re.sub(pattern, r'\1', content, flags=re.DOTALL)
    return content

def fix_undefined_context(content):
    """
    Fix cases where ResponsiveUtils uses context outside of build methods.
    Convert to build-time evaluation.
    """
    # For now, we'll identify these and handle manually
    # Most should be in const contexts which we're removing
    return content

def process_file(filepath):
    """Process a single Dart file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    content = fix_const_icons(content)
    content = fix_undefined_context(content)

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✓ Fixed {filepath.name}")
        return True
    else:
        return False

def main():
    """Main entry point."""
    print("Fixing const Icon issues...\n")

    updated_count = 0
    for dart_file in SCREENS_DIR.glob('*.dart'):
        if process_file(dart_file):
            updated_count += 1

    print(f"\n✓ Fixed {updated_count} files.")

if __name__ == '__main__':
    main()
