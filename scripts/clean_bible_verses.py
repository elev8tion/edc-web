#!/usr/bin/env python3
"""
Clean Bible Verses Script
Removes Strong's numbers and footnotes from WEB Bible database
Creates clean_text column for training data
"""

import sqlite3
import re
import sys

def clean_verse_text(text):
    """
    Remove Strong's numbers, footnotes, and markup from verse text

    Examples:
    Input: '\\+w For|strong="G1063"\\+w* God'
    Output: 'For God'
    """
    if not text:
        return ''

    # Remove all \+w markers (opening and closing)
    text = re.sub(r'\\\+w\s*', '', text)
    text = re.sub(r'\\\+w\*', '', text)

    # Remove remaining +w markers without backslash
    text = re.sub(r'\+w\s*', '', text)
    text = re.sub(r'\+w\*', '', text)

    # Remove Strong's numbers
    text = re.sub(r'\|strong="[HG]\d+"', '', text)

    # Remove footnotes: + N:NN text
    text = re.sub(r'\s*\+\s*\d+:\d+\s+[^+]*(?=\+|$)', '', text)

    # Remove standalone asterisks and pluses
    text = re.sub(r'\*', '', text)
    text = re.sub(r'\+', '', text)

    # Remove extra whitespace
    text = re.sub(r'\s+', ' ', text)
    text = text.strip()

    return text

def add_clean_text_column(db_path):
    """Add clean_text column to verses table"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Check if column already exists
        cursor.execute("PRAGMA table_info(verses)")
        columns = [row[1] for row in cursor.fetchall()]

        if 'clean_text' not in columns:
            print("Adding clean_text column...")
            cursor.execute("ALTER TABLE verses ADD COLUMN clean_text TEXT")
            conn.commit()
            print("✓ Column added")
        else:
            print("clean_text column already exists")

        return True
    except Exception as e:
        print(f"✗ Error adding column: {e}")
        return False
    finally:
        conn.close()

def clean_all_verses(db_path):
    """Clean all verses in the database"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Get all verses
        print("Fetching verses...")
        cursor.execute("SELECT id, text FROM verses")
        verses = cursor.fetchall()

        print(f"Cleaning {len(verses)} verses...")
        cleaned_count = 0

        for verse_id, text in verses:
            clean_text = clean_verse_text(text)
            cursor.execute(
                "UPDATE verses SET clean_text = ? WHERE id = ?",
                (clean_text, verse_id)
            )
            cleaned_count += 1

            if cleaned_count % 1000 == 0:
                print(f"  Cleaned {cleaned_count}/{len(verses)}...")
                conn.commit()

        conn.commit()
        print(f"✓ Cleaned {cleaned_count} verses")

        return True
    except Exception as e:
        print(f"✗ Error cleaning verses: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()

def verify_cleaning(db_path):
    """Verify cleaning by checking sample verses"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    print("\n" + "="*60)
    print("Sample Cleaned Verses:")
    print("="*60)

    # Check famous verses
    test_references = [
        "John 3:16",
        "Psalms 23:1",
        "Philippians 4:6",
        "Romans 8:28",
        "Jeremiah 29:11"
    ]

    for ref in test_references:
        cursor.execute(
            "SELECT reference, clean_text FROM verses WHERE reference = ?",
            (ref,)
        )
        result = cursor.fetchone()

        if result:
            reference, clean_text = result
            print(f"\n{reference}:")
            print(f"  {clean_text}")
        else:
            print(f"\n{ref}: NOT FOUND")

    conn.close()
    print("\n" + "="*60)

def main():
    db_path = "../assets/bible.db"

    print("WEB Bible Verse Cleaner")
    print("="*60)
    print(f"Database: {db_path}\n")

    # Step 1: Add clean_text column
    if not add_clean_text_column(db_path):
        print("\n✗ Failed to add column. Exiting.")
        sys.exit(1)

    # Step 2: Clean all verses
    if not clean_all_verses(db_path):
        print("\n✗ Failed to clean verses. Exiting.")
        sys.exit(1)

    # Step 3: Verify
    verify_cleaning(db_path)

    print("\n✓ All done! clean_text column is ready for training data.")

if __name__ == "__main__":
    main()
