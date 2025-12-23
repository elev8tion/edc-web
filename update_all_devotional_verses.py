#!/usr/bin/env python3
"""
Comprehensive script to replace ALL devotional Bible verses with authentic RVR1909 text.
This handles both single verses and multi-verse references.
"""

import json
import sqlite3
import os
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Spanish book name mappings
BOOK_MAPPINGS = {
    'génesis': 'Génesis', 'éxodo': 'Éxodo', 'levítico': 'Levítico',
    'números': 'Números', 'deuteronomio': 'Deuteronomio', 'josué': 'Josué',
    'jueces': 'Jueces', 'rut': 'Rut', '1 samuel': '1 Samuel', '2 samuel': '2 Samuel',
    '1 reyes': '1 Reyes', '2 reyes': '2 Reyes', '1 crónicas': '1 Crónicas',
    '2 crónicas': '2 Crónicas', 'esdras': 'Esdras', 'nehemías': 'Nehemías',
    'ester': 'Ester', 'job': 'Job', 'salmos': 'Salmos', 'salmo': 'Salmos',
    'proverbios': 'Proverbios', 'eclesiastés': 'Eclesiastés',
    'cantares': 'Cantares', 'isaías': 'Isaías', 'jeremías': 'Jeremías',
    'lamentaciones': 'Lamentaciones', 'ezequiel': 'Ezequiel', 'daniel': 'Daniel',
    'oseas': 'Oseas', 'joel': 'Joel', 'amós': 'Amós', 'abdías': 'Abdías',
    'jonás': 'Jonás', 'miqueas': 'Miqueas', 'nahúm': 'Nahúm', 'habacuc': 'Habacuc',
    'sofonías': 'Sofonías', 'hageo': 'Hageo', 'zacarías': 'Zacarías',
    'malaquías': 'Malaquías', 'mateo': 'Mateo', 'marcos': 'Marcos', 'lucas': 'Lucas',
    'juan': 'Juan', 'hechos': 'Hechos', 'romanos': 'Romanos', '1 corintios': '1 Corintios',
    '2 corintios': '2 Corintios', 'gálatas': 'Gálatas', 'efesios': 'Efesios',
    'filipenses': 'Filipenses', 'colosenses': 'Colosenses', '1 tesalonicenses': '1 Tesalonicenses',
    '2 tesalonicenses': '2 Tesalonicenses', '1 timoteo': '1 Timoteo', '2 timoteo': '2 Timoteo',
    'tito': 'Tito', 'filemón': 'Filemón', 'hebreos': 'Hebreos', 'santiago': 'Santiago',
    '1 pedro': '1 Pedro', '2 pedro': '2 Pedro', '1 juan': '1 Juan', '2 juan': '2 Juan',
    '3 juan': '3 Juan', 'judas': 'Judas', 'apocalipsis': 'Apocalipsis'
}

class DevotionalUpdater:
    def __init__(self, db_path: str, devotionals_dir: str):
        self.db_path = db_path
        self.devotionals_dir = devotionals_dir
        self.conn = None
        self.updates_made = 0
        self.errors = []

    def connect_db(self):
        """Connect to RVR1909 database."""
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row

    def close_db(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()

    def parse_verse_range(self, verse_part: str) -> List[int]:
        """Parse verse range like '1-3' or single verse '5'."""
        if '-' in verse_part:
            start, end = verse_part.split('-')
            return list(range(int(start), int(end) + 1))
        else:
            return [int(verse_part)]

    def parse_reference(self, reference: str) -> Optional[Tuple[str, int, List[int]]]:
        """
        Parse Bible reference into (book, chapter, verse_list).
        Handles: "Salmos 107:1", "Mateo 2:1-2", "Mateo 2:1-2, 9-10"
        """
        reference = reference.strip()

        # Pattern: Book Chapter:Verses (e.g., "Mateo 2:1-2, 9-10")
        pattern = r'^([0-9]?\s*[A-Za-zá-úÁ-Ú]+)\s+(\d+):(.+)$'
        match = re.match(pattern, reference)

        if not match:
            return None

        book_raw, chapter, verses_part = match.groups()
        book_normalized = self._normalize_book_name(book_raw)

        if not book_normalized:
            return None

        # Parse verse parts (e.g., "1-2, 9-10")
        verse_numbers = []
        for part in verses_part.split(','):
            part = part.strip()
            verse_numbers.extend(self.parse_verse_range(part))

        return (book_normalized, int(chapter), verse_numbers)

    def _normalize_book_name(self, book_raw: str) -> Optional[str]:
        """Normalize book name to database format."""
        book_lower = book_raw.strip().lower()
        return BOOK_MAPPINGS.get(book_lower)

    def get_verses_from_db(self, book: str, chapter: int, verses: List[int]) -> Optional[str]:
        """Retrieve multiple verses from RVR1909 database and combine them."""
        cursor = self.conn.cursor()
        verse_texts = []

        for verse_num in verses:
            cursor.execute(
                "SELECT text FROM verses WHERE book = ? AND chapter = ? AND verse_number = ?",
                (book, chapter, verse_num)
            )
            row = cursor.fetchone()
            if row:
                verse_texts.append(row['text'].strip())
            else:
                return None

        if not verse_texts:
            return None

        # Combine verses with space
        return ' '.join(verse_texts)

    def update_devotional_file(self, file_path: Path) -> Dict:
        """Update all verses in a single devotional file."""
        with open(file_path, 'r', encoding='utf-8') as f:
            devotionals = json.load(f)

        file_updates = 0
        file_errors = []

        for devotional in devotionals:
            dev_id = devotional.get('id', 'unknown')

            # Update openingScripture
            if 'openingScripture' in devotional:
                updated, error = self._update_verse(devotional['openingScripture'])
                if updated:
                    file_updates += 1
                elif error:
                    file_errors.append(f"{dev_id}/openingScripture: {error}")

            # Update keyVerseSpotlight
            if 'keyVerseSpotlight' in devotional:
                updated, error = self._update_verse(devotional['keyVerseSpotlight'])
                if updated:
                    file_updates += 1
                elif error:
                    file_errors.append(f"{dev_id}/keyVerseSpotlight: {error}")

        # Write updated file
        if file_updates > 0:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(devotionals, f, indent=2, ensure_ascii=False)

        return {
            'file': file_path.name,
            'updates': file_updates,
            'errors': file_errors
        }

    def _update_verse(self, verse_obj: Dict) -> Tuple[bool, Optional[str]]:
        """Update a single verse object. Returns (was_updated, error_message)."""
        reference = verse_obj.get('reference', '')
        current_text = verse_obj.get('text', '')

        # Skip if it's a placeholder
        if '[' in current_text and ']' in current_text:
            return False, None

        # Parse reference
        parsed = self.parse_reference(reference)

        if not parsed:
            return False, f"Could not parse reference: {reference}"

        book, chapter, verses = parsed

        # Get correct RVR1909 text
        db_text = self.get_verses_from_db(book, chapter, verses)

        if not db_text:
            return False, f"Verse not found: {reference}"

        # Normalize for comparison
        current_normalized = ' '.join(current_text.split())
        db_normalized = ' '.join(db_text.split())

        # Update if different
        if current_normalized != db_normalized:
            verse_obj['text'] = db_text
            return True, None

        return False, None

    def run_full_update(self):
        """Run complete update on all devotional files."""
        self.connect_db()

        print("=" * 70)
        print("🔄 UPDATING ALL DEVOTIONALS TO AUTHENTIC RVR1909")
        print("=" * 70)

        devotional_files = sorted(Path(self.devotionals_dir).glob('*.json'))

        for file_path in devotional_files:
            print(f"\n📖 Processing: {file_path.name}")
            result = self.update_devotional_file(file_path)

            if result['updates'] > 0:
                print(f"  ✅ Made {result['updates']} updates")
                self.updates_made += result['updates']

            if result['errors']:
                print(f"  ⚠️  {len(result['errors'])} errors:")
                for error in result['errors']:
                    print(f"    - {error}")
                self.errors.extend(result['errors'])

        self.close_db()

        print("\n" + "=" * 70)
        print("📊 SUMMARY")
        print("=" * 70)
        print(f"✅ Total verse updates: {self.updates_made}")
        print(f"⚠️  Total errors: {len(self.errors)}")

        if self.errors:
            print("\n⚠️  ERRORS:")
            for error in self.errors:
                print(f"  - {error}")

        print("\n✅ Done!")

def main():
    db_path = 'assets/spanish_bible_rvr1909.db'
    devotionals_dir = 'assets/devotionals/es'

    if not os.path.exists(db_path):
        print(f"❌ Database not found: {db_path}")
        return

    if not os.path.exists(devotionals_dir):
        print(f"❌ Devotionals directory not found: {devotionals_dir}")
        return

    updater = DevotionalUpdater(db_path, devotionals_dir)
    updater.run_full_update()

if __name__ == '__main__':
    main()
