#!/usr/bin/env python3
"""
Comprehensive audit of Spanish devotional Bible verses against RVR1909 database.
This script performs a thorough character-by-character comparison.
"""

import json
import sqlite3
import os
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Spanish book name mappings to database format
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

class VerseAuditor:
    def __init__(self, db_path: str, devotionals_dir: str):
        self.db_path = db_path
        self.devotionals_dir = devotionals_dir
        self.conn = None
        self.mismatches = []
        self.matches = []
        self.errors = []

    def connect_db(self):
        """Connect to RVR1909 database."""
        self.conn = sqlite3.connect(self.db_path)
        self.conn.row_factory = sqlite3.Row

    def close_db(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()

    def parse_reference(self, reference: str) -> Optional[Tuple[str, int, int]]:
        """
        Parse Bible reference into (book, chapter, verse).
        Handles simple references like "Salmos 107:1"
        Returns None for complex references like "Mateo 2:1-2, 9-10"
        """
        # Clean up reference
        reference = reference.strip()

        # Pattern: Book Chapter:Verse (e.g., "Salmos 107:1")
        pattern = r'^([0-9]?\s*[A-Za-zá-úÁ-Ú]+)\s+(\d+):(\d+)$'
        match = re.match(pattern, reference)

        if not match:
            return None

        book_raw, chapter, verse = match.groups()
        book_normalized = self._normalize_book_name(book_raw)

        if not book_normalized:
            return None

        return (book_normalized, int(chapter), int(verse))

    def _normalize_book_name(self, book_raw: str) -> Optional[str]:
        """Normalize book name to database format."""
        book_lower = book_raw.strip().lower()
        return BOOK_MAPPINGS.get(book_lower)

    def get_verse_from_db(self, book: str, chapter: int, verse: int) -> Optional[str]:
        """Retrieve verse text from RVR1909 database."""
        cursor = self.conn.cursor()
        cursor.execute(
            "SELECT text FROM verses WHERE book = ? AND chapter = ? AND verse_number = ?",
            (book, chapter, verse)
        )
        row = cursor.fetchone()
        return row['text'] if row else None

    def compare_verses(self, devotional_text: str, db_text: str) -> bool:
        """
        Compare devotional verse text with database text.
        Returns True if they match (allowing for minor whitespace differences).
        """
        # Normalize whitespace
        dev_normalized = ' '.join(devotional_text.split())
        db_normalized = ' '.join(db_text.split())

        return dev_normalized == db_normalized

    def audit_devotional_file(self, file_path: Path) -> Dict:
        """Audit all verses in a single devotional file."""
        with open(file_path, 'r', encoding='utf-8') as f:
            devotionals = json.load(f)

        file_results = {
            'file': file_path.name,
            'devotionals_count': len(devotionals),
            'verses_checked': 0,
            'matches': 0,
            'mismatches': 0,
            'errors': 0,
            'details': []
        }

        for devotional in devotionals:
            dev_id = devotional.get('id', 'unknown')

            # Check openingScripture
            if 'openingScripture' in devotional:
                result = self._check_verse(
                    dev_id,
                    'openingScripture',
                    devotional['openingScripture']
                )
                file_results['details'].append(result)
                file_results['verses_checked'] += 1

                if result['status'] == 'match':
                    file_results['matches'] += 1
                elif result['status'] == 'mismatch':
                    file_results['mismatches'] += 1
                else:
                    file_results['errors'] += 1

            # Check keyVerseSpotlight
            if 'keyVerseSpotlight' in devotional:
                result = self._check_verse(
                    dev_id,
                    'keyVerseSpotlight',
                    devotional['keyVerseSpotlight']
                )
                file_results['details'].append(result)
                file_results['verses_checked'] += 1

                if result['status'] == 'match':
                    file_results['matches'] += 1
                elif result['status'] == 'mismatch':
                    file_results['mismatches'] += 1
                else:
                    file_results['errors'] += 1

        return file_results

    def _check_verse(self, dev_id: str, field: str, verse_obj: Dict) -> Dict:
        """Check a single verse against database."""
        reference = verse_obj.get('reference', '')
        devotional_text = verse_obj.get('text', '')

        # Parse reference
        parsed = self.parse_reference(reference)

        if not parsed:
            return {
                'devotional_id': dev_id,
                'field': field,
                'reference': reference,
                'status': 'error',
                'error': 'Could not parse reference',
                'devotional_text': devotional_text[:100] + '...' if len(devotional_text) > 100 else devotional_text
            }

        book, chapter, verse = parsed

        # Get database text
        db_text = self.get_verse_from_db(book, chapter, verse)

        if not db_text:
            return {
                'devotional_id': dev_id,
                'field': field,
                'reference': reference,
                'status': 'error',
                'error': f'Verse not found in database: {book} {chapter}:{verse}',
                'devotional_text': devotional_text[:100] + '...' if len(devotional_text) > 100 else devotional_text
            }

        # Compare texts
        matches = self.compare_verses(devotional_text, db_text)

        if matches:
            return {
                'devotional_id': dev_id,
                'field': field,
                'reference': reference,
                'status': 'match'
            }
        else:
            return {
                'devotional_id': dev_id,
                'field': field,
                'reference': reference,
                'status': 'mismatch',
                'devotional_text': devotional_text,
                'database_text': db_text
            }

    def run_full_audit(self) -> Dict:
        """Run complete audit on all devotional files."""
        self.connect_db()

        results = {
            'total_files': 0,
            'total_verses': 0,
            'total_matches': 0,
            'total_mismatches': 0,
            'total_errors': 0,
            'files': []
        }

        devotional_files = sorted(Path(self.devotionals_dir).glob('*.json'))

        for file_path in devotional_files:
            print(f"\n📖 Auditing: {file_path.name}")
            file_results = self.audit_devotional_file(file_path)

            results['files'].append(file_results)
            results['total_files'] += 1
            results['total_verses'] += file_results['verses_checked']
            results['total_matches'] += file_results['matches']
            results['total_mismatches'] += file_results['mismatches']
            results['total_errors'] += file_results['errors']

            print(f"  ✅ Matches: {file_results['matches']}")
            print(f"  ❌ Mismatches: {file_results['mismatches']}")
            print(f"  ⚠️  Errors: {file_results['errors']}")

        self.close_db()
        return results

    def generate_report(self, results: Dict, output_file: str = 'verse_audit_report.json'):
        """Generate detailed audit report."""
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)

        print("\n" + "="*70)
        print("📊 COMPREHENSIVE VERSE AUDIT REPORT")
        print("="*70)
        print(f"Total Files Audited: {results['total_files']}")
        print(f"Total Verses Checked: {results['total_verses']}")
        print(f"✅ Matches: {results['total_matches']}")
        print(f"❌ Mismatches: {results['total_mismatches']}")
        print(f"⚠️  Errors (unparseable): {results['total_errors']}")
        print(f"\nMatch Rate: {results['total_matches'] / results['total_verses'] * 100:.1f}%")

        # Show all mismatches
        if results['total_mismatches'] > 0:
            print("\n" + "="*70)
            print("❌ MISMATCHES FOUND:")
            print("="*70)

            for file_result in results['files']:
                for detail in file_result['details']:
                    if detail['status'] == 'mismatch':
                        print(f"\n📍 {detail['devotional_id']} - {detail['field']}")
                        print(f"   Reference: {detail['reference']}")
                        print(f"   Devotional: {detail['devotional_text'][:150]}")
                        print(f"   Database:   {detail['database_text'][:150]}")

        print(f"\n💾 Full report saved to: {output_file}")
        print("="*70)

def main():
    db_path = 'assets/spanish_bible_rvr1909.db'
    devotionals_dir = 'assets/devotionals/es'

    if not os.path.exists(db_path):
        print(f"❌ Database not found: {db_path}")
        return

    if not os.path.exists(devotionals_dir):
        print(f"❌ Devotionals directory not found: {devotionals_dir}")
        return

    auditor = VerseAuditor(db_path, devotionals_dir)
    results = auditor.run_full_audit()
    auditor.generate_report(results)

if __name__ == '__main__':
    main()
