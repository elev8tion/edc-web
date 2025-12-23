#!/bin/bash
# Automated Spanish Localization Script for Everyday Christian App
# Uses Claude Code session credentials via Anthropic Agent SDK

set -e  # Exit on error

echo "🌍 Starting Spanish Localization Automation..."
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed"
    exit 1
fi

# Check if anthropic package is installed
if ! python3 -c "import anthropic" 2>/dev/null; then
    echo "📦 Installing Anthropic SDK..."
    pip3 install anthropic
fi

# Navigate to project root
cd "$(dirname "$0")/.."

# Run the localization agent
echo "🤖 Running localization agent..."
python3 scripts/localize_agent.py

# Check if ARB files were created
if [ -f "lib/l10n/app_en.arb" ] && [ -f "lib/l10n/app_es.arb" ]; then
    echo ""
    echo "✅ Localization files generated successfully!"
    echo ""

    # Ask user if they want to commit
    read -p "📝 Commit and push changes to GitHub? (y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Stage the files
        git add lib/l10n/
        git add l10n.yaml

        # Commit with descriptive message
        git commit -m "🌍 Add Spanish localization via AI agent

- Generated app_en.arb with extracted English strings
- Generated app_es.arb with AI-translated Spanish strings
- Created l10n.yaml configuration for Flutter localization
- Ready for flutter gen-l10n to generate localization code

🤖 Generated with Claude Code Localization Agent

Co-Authored-By: Claude <noreply@anthropic.com>"

        # Push to remote
        echo "🚀 Pushing to GitHub..."
        git push

        echo ""
        echo "✅ Changes committed and pushed to GitHub!"
        echo ""
        echo "📝 Next steps:"
        echo "   1. Add 'generate: true' to pubspec.yaml"
        echo "   2. Run: flutter gen-l10n"
        echo "   3. Test the app in both languages"
    else
        echo ""
        echo "⏸️  Changes staged but not committed"
        echo "   Run 'git status' to see changes"
    fi
else
    echo "❌ Localization failed - ARB files not created"
    exit 1
fi
