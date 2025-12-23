#!/bin/bash
# Helper script to run Flutter app with environment variables

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Run Flutter with --dart-define for API key
flutter run --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" "$@"
