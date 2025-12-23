#!/bin/bash
# Helper script to connect MCP SQLite Server to the iOS simulator database
# Automatically finds the everyday_christian.db file in the simulator directory

echo "🔍 Searching for everyday_christian.db in iOS simulator..."

# Find the most recently modified database file
DB_PATH=$(find ~/Library/Developer/CoreSimulator/Devices \
  -name "everyday_christian.db" \
  -type f \
  2>/dev/null \
  -exec stat -f "%m %N" {} \; | \
  sort -rn | \
  head -1 | \
  cut -d' ' -f2-)

if [ -z "$DB_PATH" ]; then
  echo "❌ Database not found!"
  echo "   Make sure the app is installed and has been run at least once."
  echo "   Try running: flutter run"
  exit 1
fi

echo "📍 Found database: $DB_PATH"
echo "📊 Database size: $(du -h "$DB_PATH" | cut -f1)"
echo "🚀 Starting MCP SQLite Server..."
echo ""

# Launch the MCP server
npx -y mcp-sqlite "$DB_PATH"
