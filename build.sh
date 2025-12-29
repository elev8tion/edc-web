#!/bin/bash
set -e

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$PWD/flutter/bin"

echo "Setting up Flutter for web..."
flutter precache --web

echo "Building Flutter web app..."
flutter build web --release --no-tree-shake-icons

echo "Build complete!"
