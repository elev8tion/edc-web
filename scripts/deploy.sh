#!/bin/bash
# =============================================================================
# Everyday Christian - Production Deployment Script
# =============================================================================
# This is the ONLY way to deploy to Netlify production.
# Do NOT modify or use alternative deployment methods.
# =============================================================================

set -e  # Exit on any error

echo "🚀 Starting Everyday Christian deployment..."
echo ""

# Step 1: Build the Flutter web app
echo "📦 Building Flutter web app..."
flutter build web --release --no-tree-shake-icons

# Step 2: Deploy to Netlify production
echo ""
echo "☁️  Deploying to Netlify production..."
netlify deploy --prod --dir=build/web

echo ""
echo "✅ Deployment complete!"
echo "🌐 Live at: https://app.everydaychristian.app"
