#!/usr/bin/env python3
"""
Download and create World English Bible (WEB) SQLite database
"""

import sqlite3
import urllib.request
import json

print("📖 Downloading World English Bible (WEB)...")

# Download WEB Bible JSON
url = "https://raw.githubusercontent.com/scrollmapper/bible_databases/master/bibles/en-web.json"
try:
    with urllib.request.urlopen(url) as response:
        web_data = json.loads(response.read().decode())
    print(f"✅ Downloaded {len(web_data.get('verses', []))} verses")
except Exception as e:
    print(f"❌ Failed to download: {e}")
    print("\n🔄 Trying alternative source...")

    # Try alternative: https://github.com/unyieldinggrace/BibleData
    url2 = "https://raw.githubusercontent.com/godlytalias/Bible-Database/master/English/WEB.json"
    try:
        with urllib.request.urlopen(url2) as response:
            web_data = json.loads(response.read().decode())
        print(f"✅ Downloaded from alternative source")
    except Exception as e2:
        print(f"❌ Alternative also failed: {e2}")
        exit(1)

# Create SQLite database
db_path = "../assets/bible.db"
print(f"\n💾 Creating SQLite database at {db_path}...")

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create verses table
cursor.execute('''
    CREATE TABLE IF NOT EXISTS verses (
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
    CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5(
        text,
        content=verses,
        tokenize='porter ascii'
    )
''')

print("📝 Inserting verses...")

# Insert verses
verse_count = 0
for verse in web_data.get('verses', web_data.get('resultset', {}).get('row', [])):
    book = verse.get('book', verse.get('field', [{}])[0].get('value', ''))
    chapter = verse.get('chapter', verse.get('field', [{}])[1].get('value', 1))
    verse_num = verse.get('verse', verse.get('field', [{}])[2].get('value', 1))
    text = verse.get('text', verse.get('field', [{}])[3].get('value', ''))

    reference = f"{book} {chapter}:{verse_num}"

    cursor.execute('''
        INSERT INTO verses (book, chapter, verse_number, text, translation, reference)
        VALUES (?, ?, ?, ?, 'WEB', ?)
    ''', (book, chapter, verse_num, text, reference))

    verse_count += 1
    if verse_count % 1000 == 0:
        print(f"  {verse_count} verses inserted...")

# Create indexes
print("\n🔍 Creating indexes...")
cursor.execute('CREATE INDEX IF NOT EXISTS idx_book_chapter ON verses(book, chapter)')
cursor.execute('CREATE INDEX IF NOT EXISTS idx_reference ON verses(reference)')

conn.commit()
conn.close()

print(f"\n✅ Complete! {verse_count} verses in WEB SQLite database")
print(f"📍 Location: {db_path}")
