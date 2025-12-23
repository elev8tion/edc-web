#!/usr/bin/env python3
"""
Spanish Localization Agent for Everyday Christian App
Uses Claude Code session credentials for AI-powered translation
"""

import os
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Set

try:
    from anthropic import Anthropic
except ImportError:
    print("❌ Error: anthropic package not installed")
    print("Install it with: pip install anthropic")
    sys.exit(1)


class LocalizationAgent:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.lib_dir = self.project_root / "lib"
        self.l10n_dir = self.project_root / "lib" / "l10n"
        self.extracted_strings: Dict[str, str] = {}
        self.client = self._init_anthropic_client()

    def _init_anthropic_client(self) -> Anthropic:
        """Initialize Anthropic client using API key from environment"""
        # Check for API key in environment
        api_key = os.getenv('ANTHROPIC_API_KEY')

        if not api_key:
            print("❌ ANTHROPIC_API_KEY not found in environment")
            print("\n📝 To use this script, you need an Anthropic API key.")
            print("   Since you have Claude Code Pro, you can:")
            print("   1. Get your API key from: https://console.anthropic.com/settings/keys")
            print("   2. Set it as an environment variable:")
            print("      export ANTHROPIC_API_KEY='your-key-here'")
            print("   3. Or add it to your ~/.zshrc or ~/.bashrc")
            print("\n   Note: API usage will be billed separately from Claude Code Pro")
            sys.exit(1)

        print("✅ Using ANTHROPIC_API_KEY from environment")
        return Anthropic(api_key=api_key)

    def extract_strings_from_file(self, file_path: Path) -> Set[str]:
        """Extract hardcoded English strings from a Dart file"""
        strings = set()

        try:
            content = file_path.read_text(encoding='utf-8')

            # Pattern for single-quoted strings
            single_quoted = re.findall(r"'([^'\\]*(?:\\.[^'\\]*)*)'", content)
            strings.update(single_quoted)

            # Pattern for double-quoted strings
            double_quoted = re.findall(r'"([^"\\]*(?:\\.[^"\\]*)*)"', content)
            strings.update(double_quoted)

        except Exception as e:
            print(f"⚠️  Error reading {file_path}: {e}")

        # Filter out non-UI strings
        filtered = set()
        for s in strings:
            # Skip empty, very short, or code-like strings
            if len(s) < 2 or s.startswith('assets/') or s.startswith('lib/'):
                continue
            # Skip common code patterns
            if s in ['id', 'name', 'text', 'title', 'value', 'key']:
                continue
            # Keep strings that look like UI text
            if any(c.isalpha() for c in s) and ' ' in s or len(s) > 10:
                filtered.add(s)

        return filtered

    def scan_project(self):
        """Scan all Dart files in the project for strings"""
        print(f"\n🔍 Scanning project: {self.project_root}")

        dart_files = list(self.lib_dir.rglob("*.dart"))
        print(f"📁 Found {len(dart_files)} Dart files")

        all_strings = set()
        for dart_file in dart_files:
            strings = self.extract_strings_from_file(dart_file)
            all_strings.update(strings)

        print(f"📝 Extracted {len(all_strings)} unique strings")

        # Create key-value pairs
        for i, string in enumerate(sorted(all_strings)):
            # Generate a key from the string
            key = self._generate_key(string, i)
            self.extracted_strings[key] = string

        return self.extracted_strings

    def _generate_key(self, string: str, index: int) -> str:
        """Generate a camelCase key from a string"""
        # Remove special characters and split into words
        words = re.sub(r'[^a-zA-Z0-9\s]', '', string).split()
        if not words:
            return f"string{index}"

        # Convert to camelCase
        key = words[0].lower()
        for word in words[1:4]:  # Limit to first 4 words
            key += word.capitalize()

        # Add index if key would be duplicate
        return f"{key}{index}" if len(key) < 5 else key

    def translate_to_spanish(self, strings: Dict[str, str]) -> Dict[str, str]:
        """Use Claude to translate strings to Spanish"""
        print(f"\n🤖 Translating {len(strings)} strings to Spanish using Claude...")

        # Prepare strings for translation
        strings_json = json.dumps(strings, indent=2, ensure_ascii=False)

        prompt = f"""You are translating a Christian mobile app interface from English to Spanish.

Please translate the following JSON object containing UI strings. The keys should remain in English, but translate all the values to natural, conversational Spanish appropriate for a faith-based application.

Important guidelines:
- Use formal "usted" form for user-facing text
- Keep religious terms accurate (e.g., "prayer" = "oración", "Bible" = "Biblia")
- Maintain any formatting like {{variable}} placeholders
- Keep button text concise
- Use natural Spanish phrasing, not literal translations

English strings to translate:
{strings_json}

Return ONLY a valid JSON object with the same keys but Spanish values. Do not include any explanations or markdown formatting."""

        try:
            response = self.client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=4096,
                messages=[{
                    "role": "user",
                    "content": prompt
                }]
            )

            spanish_json = response.content[0].text.strip()

            # Remove markdown code blocks if present
            spanish_json = re.sub(r'```json\n?', '', spanish_json)
            spanish_json = re.sub(r'```\n?', '', spanish_json)

            spanish_strings = json.loads(spanish_json)
            print(f"✅ Translation complete: {len(spanish_strings)} strings translated")
            return spanish_strings

        except Exception as e:
            print(f"❌ Translation error: {e}")
            sys.exit(1)

    def generate_arb_files(self, english: Dict[str, str], spanish: Dict[str, str]):
        """Generate ARB files for Flutter localization"""
        print(f"\n📄 Generating ARB files...")

        # Create l10n directory
        self.l10n_dir.mkdir(exist_ok=True)

        # Generate app_en.arb
        en_arb = {
            "@@locale": "en",
            "@@context": "Everyday Christian App - English Localization"
        }
        for key, value in english.items():
            en_arb[key] = value
            en_arb[f"@{key}"] = {
                "description": f"English text for {key}"
            }

        en_arb_path = self.l10n_dir / "app_en.arb"
        with open(en_arb_path, 'w', encoding='utf-8') as f:
            json.dump(en_arb, f, indent=2, ensure_ascii=False)
        print(f"✅ Created: {en_arb_path}")

        # Generate app_es.arb
        es_arb = {
            "@@locale": "es",
            "@@context": "Everyday Christian App - Spanish Localization"
        }
        for key, value in spanish.items():
            es_arb[key] = value
            es_arb[f"@{key}"] = {
                "description": f"Spanish text for {key}"
            }

        es_arb_path = self.l10n_dir / "app_es.arb"
        with open(es_arb_path, 'w', encoding='utf-8') as f:
            json.dump(es_arb, f, indent=2, ensure_ascii=False)
        print(f"✅ Created: {es_arb_path}")

        return en_arb_path, es_arb_path

    def generate_l10n_yaml(self):
        """Generate l10n.yaml configuration file"""
        l10n_yaml = self.project_root / "l10n.yaml"

        config = """arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
"""

        with open(l10n_yaml, 'w') as f:
            f.write(config)

        print(f"✅ Created: {l10n_yaml}")
        return l10n_yaml

    def run(self):
        """Main execution flow"""
        print("=" * 60)
        print("🌍 Everyday Christian App - Spanish Localization Agent")
        print("=" * 60)

        # Step 1: Scan project for strings
        english_strings = self.scan_project()

        if not english_strings:
            print("❌ No strings found to translate!")
            return

        # Step 2: Translate to Spanish
        spanish_strings = self.translate_to_spanish(english_strings)

        # Step 3: Generate ARB files
        en_path, es_path = self.generate_arb_files(english_strings, spanish_strings)

        # Step 4: Generate l10n.yaml
        yaml_path = self.generate_l10n_yaml()

        # Summary
        print("\n" + "=" * 60)
        print("✅ LOCALIZATION COMPLETE!")
        print("=" * 60)
        print(f"📊 Statistics:")
        print(f"   - Strings extracted: {len(english_strings)}")
        print(f"   - Strings translated: {len(spanish_strings)}")
        print(f"\n📁 Files created:")
        print(f"   - {en_path}")
        print(f"   - {es_path}")
        print(f"   - {yaml_path}")
        print(f"\n📝 Next steps:")
        print(f"   1. Add to pubspec.yaml:")
        print(f"      generate: true")
        print(f"   2. Run: flutter gen-l10n")
        print(f"   3. Import: import 'package:flutter_gen/gen_l10n/app_localizations.dart';")
        print(f"   4. Use: AppLocalizations.of(context)!.yourKey")
        print(f"   5. Test both languages in the app")
        print("=" * 60)


def main():
    agent = LocalizationAgent()
    agent.run()


if __name__ == "__main__":
    main()
