#!/bin/bash
# Post-build script to add cache-busting hashes to Flutter web assets
# This runs after `flutter build web` to add version hashes to JS files

set -e

BUILD_DIR="build/web"

echo "Adding cache-busting hashes to Flutter web build..."

# Generate hash from main.dart.js content
if [ -f "$BUILD_DIR/main.dart.js" ]; then
    # Use md5 on macOS, md5sum on Linux
    if command -v md5 &> /dev/null; then
        MAIN_HASH=$(md5 -q "$BUILD_DIR/main.dart.js" | cut -c1-8)
    else
        MAIN_HASH=$(md5sum "$BUILD_DIR/main.dart.js" | cut -c1-8)
    fi
    echo "main.dart.js hash: $MAIN_HASH"

    # Update flutter_bootstrap.js to use versioned main.dart.js
    sed -i.bak "s|\"main.dart.js\"|\"main.dart.js?v=$MAIN_HASH\"|g" "$BUILD_DIR/flutter_bootstrap.js"
    rm -f "$BUILD_DIR/flutter_bootstrap.js.bak"

    echo "Updated flutter_bootstrap.js with cache-busting hash"
else
    echo "Warning: main.dart.js not found in $BUILD_DIR"
fi

# Also add hash to service worker version to force SW update
if [ -f "$BUILD_DIR/flutter_service_worker.js" ]; then
    if command -v md5 &> /dev/null; then
        SW_HASH=$(md5 -q "$BUILD_DIR/flutter_service_worker.js" | cut -c1-8)
    else
        SW_HASH=$(md5sum "$BUILD_DIR/flutter_service_worker.js" | cut -c1-8)
    fi
    echo "flutter_service_worker.js hash: $SW_HASH"

    # Update the service worker version in flutter_bootstrap.js
    sed -i.bak "s|serviceWorkerVersion: \"[0-9]*\"|serviceWorkerVersion: \"$SW_HASH\"|g" "$BUILD_DIR/flutter_bootstrap.js"
    rm -f "$BUILD_DIR/flutter_bootstrap.js.bak"

    echo "Updated service worker version with content hash"
fi

echo "Cache-busting complete!"
