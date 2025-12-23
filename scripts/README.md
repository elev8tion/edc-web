# Localization Scripts

Automated Spanish localization for Everyday Christian App using Claude Code AI.

## Prerequisites

- Python 3.x installed
- Claude Code Pro subscription (logged in)
- `anthropic` Python package (auto-installed by script)

## Usage

### Quick Start

Run the automated localization script:

```bash
./scripts/localize.sh
```

This will:
1. Extract all English strings from Dart files
2. Translate them to Spanish using Claude AI
3. Generate ARB files (`app_en.arb`, `app_es.arb`)
4. Create `l10n.yaml` configuration
5. Prompt to commit and push to GitHub

### Manual Mode

Run just the Python agent without auto-commit:

```bash
python3 scripts/localize_agent.py
```

## How It Works

### 1. String Extraction
- Scans all `.dart` files in `lib/` directory
- Extracts hardcoded English strings
- Filters out code patterns, keeping only UI text
- Generates camelCase keys for each string

### 2. AI Translation
- Uses Claude Sonnet 4 via your Claude Code session
- Translates with context awareness for religious terms
- Maintains formatting and placeholders
- Uses formal Spanish ("usted") appropriate for the app

### 3. ARB File Generation
- Creates `lib/l10n/app_en.arb` (English)
- Creates `lib/l10n/app_es.arb` (Spanish)
- Includes metadata for each translation
- Flutter-compatible ARB format

### 4. Configuration
- Generates `l10n.yaml` for Flutter localization
- Ready for `flutter gen-l10n` command

## Authentication

The script uses your Claude Code session credentials from `~/.claude.json`.

**Fallback:** If session file not found, it will use `ANTHROPIC_API_KEY` environment variable.

## Next Steps After Running

1. **Update `pubspec.yaml`:**
   ```yaml
   flutter:
     generate: true
   ```

2. **Generate localization code:**
   ```bash
   flutter gen-l10n
   ```

3. **Import in your app:**
   ```dart
   import 'package:flutter_gen/gen_l10n/app_localizations.dart';
   ```

4. **Use in widgets:**
   ```dart
   Text(AppLocalizations.of(context)!.yourStringKey)
   ```

5. **Configure MaterialApp:**
   ```dart
   MaterialApp(
     localizationsDelegates: AppLocalizations.localizationsDelegates,
     supportedLocales: AppLocalizations.supportedLocales,
     // ...
   )
   ```

## Files Created

```
lib/l10n/
├── app_en.arb          # English strings
└── app_es.arb          # Spanish translations

l10n.yaml               # Flutter localization config
```

## Troubleshooting

### "anthropic package not installed"
```bash
pip3 install anthropic
```

### "No API key found"
Make sure you're logged into Claude Code, or set:
```bash
export ANTHROPIC_API_KEY=your_key_here
```

### Translation quality issues
Edit `app_es.arb` manually to refine specific translations.

## Contributing

To improve translations:
1. Edit `app_es.arb` directly
2. Test in the app
3. Commit changes
4. Re-run script to update with new strings (preserves manual edits)

## License

Part of Everyday Christian App - see main LICENSE file.
