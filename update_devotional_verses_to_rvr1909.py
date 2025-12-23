#!/usr/bin/env python3
"""
Script to update Spanish devotional Bible verse texts to RVR1909 translation.

This script:
1. Reads all Spanish devotional JSON files
2. Extracts Bible references from openingScripture and keyVerseSpotlight
3. Looks up the correct RVR1909 text from the database
4. Updates the verse texts in the JSON files
"""

import json
import sqlite3
import re
import os
from pathlib import Path

# Database path
DB_PATH = "assets/spanish_bible_rvr1909.db"

# Devotionals directory
DEVOTIONALS_DIR = "assets/devotionals/es"

# Spanish book name mapping (for parsing references)
SPANISH_BOOK_NAMES = {
    "génesis": "Génesis", "éxodo": "Éxodo", "levítico": "Levítico",
    "números": "Números", "deuteronomio": "Deuteronomio", "josué": "Josué",
    "jueces": "Jueces", "rut": "Rut", "1 samuel": "1 Samuel", "2 samuel": "2 Samuel",
    "1 reyes": "1 Reyes", "2 reyes": "2 Reyes", "1 crónicas": "1 Crónicas",
    "2 crónicas": "2 Crónicas", "esdras": "Esdras", "nehemías": "Nehemías",
    "ester": "Ester", "job": "Job", "salmos": "Salmos", "proverbios": "Proverbios",
    "eclesiastés": "Eclesiastés", "cantares": "Cantares", "isaías": "Isaías",
    "jeremías": "Jeremías", "lamentaciones": "Lamentaciones", "ezequiel": "Ezequiel",
    "daniel": "Daniel", "oseas": "Oseas", "joel": "Joel", "amós": "Amós",
    "abdías": "Abdías", "jonás": "Jonás", "miqueas": "Miqueas", "nahúm": "Nahúm",
    "habacuc": "Habacuc", "sofonías": "Sofonías", "hageo": "Hageo", "zacarías": "Zacarías",
    "malaquías": "Malaquías", "mateo": "Mateo", "marcos": "Marcos", "lucas": "Lucas",
    "juan": "Juan", "hechos": "Hechos", "romanos": "Romanos", "1 corintios": "1 Corintios",
    "2 corintios": "2 Corintios", "gálatas": "Gálatas", "efesios": "Efesios",
    "filipenses": "Filipenses", "colosenses": "Colosenses", "1 tesalonicenses": "1 Tesalonicenses",
    "2 tesalonicenses": "2 Tesalonicenses", "1 timoteo": "1 Timoteo", "2 timoteo": "2 Timoteo",
    "tito": "Tito", "filemón": "Filemón", "hebreos": "Hebreos", "santiago": "Santiago",
    "1 pedro": "1 Pedro", "2 pedro": "2 Pedro", "1 juan": "1 Juan", "2 juan": "2 Juan",
    "3 juan": "3 Juan", "judas": "Judas", "apocalipsis": "Apocalipsis"
}

def parse_reference(reference):
    """
    Parse a Bible reference like 'Salmos 107:1' or 'Santiago 1:17' or '1 Timoteo 4:4-5'
    Returns (book, chapter, verse_start, verse_end) or None if parsing fails
    """
    # Pattern: Book Chapter:Verse or Book Chapter:Verse-Verse
    pattern = r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$'
    match = re.match(pattern, reference.strip())

    if not match:
        return None

    book = match.group(1).strip()
    chapter = int(match.group(2))
    verse_start = int(match.group(3))
    verse_end = int(match.group(4)) if match.group(4) else verse_start

    return (book, chapter, verse_start, verse_end)

def get_rvr1909_verse(db_conn, book, chapter, verse_number):
    """
    Retrieve the RVR1909 verse text from the database
    """
    cursor = db_conn.cursor()
    cursor.execute(
        "SELECT text FROM verses WHERE book = ? AND chapter = ? AND verse_number = ?",
        (book, chapter, verse_number)
    )
    result = cursor.fetchone()
    return result[0] if result else None

def get_verse_range_text(db_conn, book, chapter, verse_start, verse_end):
    """
    Get text for a range of verses (e.g., verses 4-5)
    """
    verses = []
    for verse_num in range(verse_start, verse_end + 1):
        text = get_rvr1909_verse(db_conn, book, chapter, verse_num)
        if text:
            verses.append(text)

    return " ".join(verses) if verses else None

def update_devotional_file(db_conn, file_path):
    """
    Update a single devotional JSON file with RVR1909 verse texts
    """
    print(f"\n📖 Processing: {os.path.basename(file_path)}")

    with open(file_path, 'r', encoding='utf-8') as f:
        devotionals = json.load(f)

    updates_count = 0
    errors = []

    for dev in devotionals:
        dev_id = dev.get('id', 'unknown')

        # Update openingScripture
        if 'openingScripture' in dev:
            ref = dev['openingScripture'].get('reference', '')
            parsed = parse_reference(ref)

            if parsed:
                book, chapter, verse_start, verse_end = parsed
                new_text = get_verse_range_text(db_conn, book, chapter, verse_start, verse_end)

                if new_text:
                    old_text = dev['openingScripture']['text']
                    if old_text != new_text:
                        dev['openingScripture']['text'] = new_text
                        updates_count += 1
                        print(f"  ✓ Updated {dev_id} openingScripture: {ref}")
                else:
                    errors.append(f"{dev_id}: Could not find verse for {ref}")
            else:
                errors.append(f"{dev_id}: Could not parse reference '{ref}'")

        # Update keyVerseSpotlight
        if 'keyVerseSpotlight' in dev:
            ref = dev['keyVerseSpotlight'].get('reference', '')
            parsed = parse_reference(ref)

            if parsed:
                book, chapter, verse_start, verse_end = parsed
                new_text = get_verse_range_text(db_conn, book, chapter, verse_start, verse_end)

                if new_text:
                    old_text = dev['keyVerseSpotlight']['text']
                    if old_text != new_text:
                        dev['keyVerseSpotlight']['text'] = new_text
                        updates_count += 1
                        print(f"  ✓ Updated {dev_id} keyVerseSpotlight: {ref}")
                else:
                    errors.append(f"{dev_id}: Could not find verse for {ref}")
            else:
                errors.append(f"{dev_id}: Could not parse reference '{ref}'")

    # Write updated JSON back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(devotionals, f, ensure_ascii=False, indent=2)

    print(f"  ✅ Made {updates_count} updates")

    if errors:
        print(f"  ⚠️  {len(errors)} errors:")
        for error in errors[:5]:  # Show first 5 errors
            print(f"    - {error}")

    return updates_count, errors

def main():
    """
    Main function to update all Spanish devotional files
    """
    print("=" * 70)
    print("🔄 UPDATING SPANISH DEVOTIONALS TO RVR1909")
    print("=" * 70)

    # Connect to database
    if not os.path.exists(DB_PATH):
        print(f"❌ Error: Database not found at {DB_PATH}")
        return

    db_conn = sqlite3.connect(DB_PATH)
    print(f"✅ Connected to database: {DB_PATH}")

    # Get all devotional files
    devotional_files = sorted(Path(DEVOTIONALS_DIR).glob("batch_*.json"))
    print(f"📚 Found {len(devotional_files)} devotional batch files")

    total_updates = 0
    all_errors = []

    # Process each file
    for file_path in devotional_files:
        updates, errors = update_devotional_file(db_conn, file_path)
        total_updates += updates
        all_errors.extend(errors)

    # Close database
    db_conn.close()

    # Summary
    print("\n" + "=" * 70)
    print("📊 SUMMARY")
    print("=" * 70)
    print(f"✅ Total verse updates: {total_updates}")
    print(f"⚠️  Total errors: {len(all_errors)}")

    if all_errors:
        print("\n⚠️  ERRORS FOUND:")
        for error in all_errors[:20]:  # Show first 20 errors
            print(f"  - {error}")
        if len(all_errors) > 20:
            print(f"  ... and {len(all_errors) - 20} more")

    print("\n✅ Done!")

if __name__ == "__main__":
    main()
