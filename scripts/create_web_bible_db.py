#!/usr/bin/env python3
"""
Create World English Bible (WEB) SQLite database from raw text
Downloads from ebible.org (official WEB source)
"""

import sqlite3
import urllib.request
import re

print("📖 Downloading World English Bible (WEB) from ebible.org...")

# Download WEB Bible in USFM format (most parseable)
url = "https://ebible.org/Scriptures/engwebp_usfm.zip"

try:
    import zipfile
    import io

    print("⬇️  Downloading ZIP file...")
    with urllib.request.urlopen(url) as response:
        zip_data = response.read()

    print("📦 Extracting USFM files...")
    with zipfile.ZipFile(io.BytesIO(zip_data)) as z:
        # Find all USFM files
        usfm_files = [f for f in z.namelist() if f.endswith('.usfm')]
        print(f"Found {len(usfm_files)} Bible books")

        # Create database
        db_path = "../assets/bible.db"
        print(f"\n💾 Creating SQLite database at {db_path}...")

        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Drop existing tables
        cursor.execute('DROP TABLE IF EXISTS verses')
        cursor.execute('DROP TABLE IF EXISTS verses_fts')

        # Create verses table
        cursor.execute('''
            CREATE TABLE verses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                book TEXT NOT NULL,
                chapter INTEGER NOT NULL,
                verse_number INTEGER NOT NULL,
                text TEXT NOT NULL,
                translation TEXT DEFAULT 'WEB',
                reference TEXT NOT NULL,
                themes TEXT
            )
        ''')

        # Create FTS table for search
        cursor.execute('''
            CREATE VIRTUAL TABLE verses_fts USING fts5(
                text,
                content=verses,
                tokenize='porter ascii'
            )
        ''')

        print("📝 Parsing and inserting verses...\n")

        verse_count = 0
        for usfm_file in sorted(usfm_files):
            content = z.read(usfm_file).decode('utf-8')

            # Extract book name from \h tag
            book_match = re.search(r'\\h (.+)', content)
            book_name = book_match.group(1).strip() if book_match else usfm_file.replace('.usfm', '')

            # Parse chapters and verses
            current_chapter = 0
            for line in content.split('\n'):
                # Chapter marker
                if line.startswith('\\c '):
                    current_chapter = int(line.split()[1])

                # Verse marker
                elif line.startswith('\\v '):
                    # Extract verse number and text
                    match = re.match(r'\\v (\d+)(.+)', line)
                    if match:
                        verse_num = int(match.group(1))
                        verse_text = match.group(2).strip()

                        # Clean up USFM markers
                        verse_text = re.sub(r'\\[a-z]+\*?', '', verse_text)
                        verse_text = ' '.join(verse_text.split())

                        if verse_text and current_chapter > 0:
                            reference = f"{book_name} {current_chapter}:{verse_num}"

                            cursor.execute('''
                                INSERT INTO verses (book, chapter, verse_number, text, translation, reference)
                                VALUES (?, ?, ?, ?, 'WEB', ?)
                            ''', (book_name, current_chapter, verse_num, verse_text, reference))

                            verse_count += 1

            print(f"  ✅ {book_name}: {verse_count} total verses so far")

        # Populate FTS index
        print("\n🔍 Building full-text search index...")
        cursor.execute('INSERT INTO verses_fts(text) SELECT text FROM verses')

        # Create indexes
        print("🔍 Creating indexes...")
        cursor.execute('CREATE INDEX idx_book_chapter ON verses(book, chapter)')
        cursor.execute('CREATE INDEX idx_reference ON verses(reference)')
        cursor.execute('CREATE INDEX idx_book ON verses(book)')

        conn.commit()

        # Verify
        cursor.execute('SELECT COUNT(*) FROM verses')
        total = cursor.fetchone()[0]

        cursor.execute('SELECT COUNT(DISTINCT book) FROM verses')
        books = cursor.fetchone()[0]

        conn.close()

        print(f"\n✅ Complete!")
        print(f"📊 Statistics:")
        print(f"   - Total verses: {total}")
        print(f"   - Bible books: {books}")
        print(f"   - Translation: World English Bible (WEB)")
        print(f"📍 Location: {db_path}")

        # Show database size
        import os
        size_mb = os.path.getsize(db_path) / (1024 * 1024)
        print(f"💾 Database size: {size_mb:.2f} MB")

except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
