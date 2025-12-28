#!/bin/bash
# Preview Flutter web app with SonnetTunnel
# Usage: ./scripts/preview.sh [--tunnel]

set -e

PROJECT_DIR="/Users/kcdacre8tor/edc_web"
TUNNEL_DIR="/Users/kcdacre8tor/SonnetTunnel"
PORT=8000

cd "$PROJECT_DIR"

echo "🔨 Building Flutter web..."
flutter build web --no-tree-shake-icons

echo ""
echo "🌐 Starting local server on port $PORT..."
cd build/web

if [[ "$1" == "--tunnel" ]]; then
    echo ""
    echo "🚇 To use tunnel, run in separate terminals:"
    echo ""
    echo "  Terminal 1 (Server):"
    echo "    cd $TUNNEL_DIR && cargo run --bin sonnettunnel-server"
    echo ""
    echo "  Terminal 2 (Client):"
    echo "    $TUNNEL_DIR/target/release/sonnettunnel --server ws://localhost:5000 --port $PORT --dashboard-port 3000"
    echo ""
    echo "  Then access:"
    echo "    - App: http://<subdomain>.localhost:8080"
    echo "    - Inspector: http://localhost:3000"
    echo ""
fi

echo "📱 App available at: http://localhost:$PORT"
echo ""
echo "Press Ctrl+C to stop"
python3 -m http.server $PORT
