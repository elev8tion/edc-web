#!/bin/bash
# Cloudflare Pages build script for Flutter PWA

set -e  # Exit on error

echo "=== Installing Flutter SDK ==="
git clone https://github.com/flutter/flutter.git --depth 1 -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "=== Flutter Doctor ==="
flutter doctor -v

echo "=== Getting Dependencies ==="
flutter pub get

echo "=== Building Web Release ==="
flutter build web --release --no-tree-shake-icons

echo "=== Build Complete ==="
ls -la build/web/
