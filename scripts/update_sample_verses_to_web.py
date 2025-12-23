#!/usr/bin/env python3
"""
Update sample_verses.json to use WEB translation from bible.db
"""

import sqlite3
import json
import re

# Sample verses to update
verses_to_fetch = [
    ("Jeremiah", 29, 11),
    ("Philippians", 4, 13),
    ("Isaiah", 41, 10),
    ("Psalms", 23, 1),  # Note: WEB uses "Psalms" not "Psalm"
    ("Romans", 8, 28),
    ("Proverbs", 3, 5),
    ("Matthew", 11, 28),
    ("2 Corinthians", 12, 9),
    ("Joshua", 1, 9),
    ("1 Peter", 5, 7),
]

print("📖 Fetching WEB verses from bible.db...")

# Connect to database
conn = sqlite3.connect('../assets/bible.db')
cursor = conn.cursor()

web_verses = []

for book, chapter, verse_num in verses_to_fetch:
    # Query verse
    cursor.execute('''
        SELECT book, chapter, verse_number, text
        FROM verses
        WHERE book = ? AND chapter = ? AND verse_number = ?
    ''', (book, chapter, verse_num))

    result = cursor.fetchone()

    if result:
        book_name, chap, v_num, text = result

        # Clean up text - remove ALL USFM markup
        cleaned_text = text

        # Step 1: Remove word markers using string replacement (simpler than regex)
        cleaned_text = cleaned_text.replace(r'\+w ', '')
        cleaned_text = cleaned_text.replace(r'\+w*', '')

        # Step 2: Remove Strong's numbers: word|strong="H1234" -> word
        cleaned_text = re.sub(r'\|strong="[^"]+"', '', cleaned_text)

        # Step 3: Remove footnotes: + 1:9 The Hebrew word rendered "God" is "\+wh אֱלֹהִ֑ים\+wh*" (Elohim).
        cleaned_text = re.sub(r'\s*\+\s+\d+:\d+[^.]*\.', '', cleaned_text)

        # Step 4: Remove Hebrew/Greek text with markers: \+wh אֱלֹהִ֑ים\+wh*
        cleaned_text = re.sub(r'\\+wh\s+[^\s]+\s*\\+wh\*', '', cleaned_text)

        # Step 5: Remove any remaining USFM backslash markers
        cleaned_text = re.sub(r'\\+[a-z]+\*?', '', cleaned_text)

        # Step 6: Normalize whitespace
        cleaned_text = ' '.join(cleaned_text.split())

        # Step 7: Remove extra quotes at start/end
        cleaned_text = cleaned_text.strip('"')

        print(f"✅ {book_name} {chap}:{v_num}")
        web_verses.append({
            "book": book_name,
            "chapter": chap,
            "verse": v_num,
            "text": cleaned_text
        })
    else:
        print(f"❌ Not found: {book} {chapter}:{verse_num}")

conn.close()

# Build complete JSON structure
sample_data = {
    "verses": [
        {
            "id": 1,
            "book": web_verses[0]["book"],
            "chapter": web_verses[0]["chapter"],
            "verse": web_verses[0]["verse"],
            "text": web_verses[0]["text"],
            "translation": "WEB",
            "themes": ["hope", "future", "guidance", "trust"]
        },
        {
            "id": 2,
            "book": web_verses[1]["book"],
            "chapter": web_verses[1]["chapter"],
            "verse": web_verses[1]["verse"],
            "text": web_verses[1]["text"],
            "translation": "WEB",
            "themes": ["strength", "perseverance", "faith", "encouragement"]
        },
        {
            "id": 3,
            "book": web_verses[2]["book"],
            "chapter": web_verses[2]["chapter"],
            "verse": web_verses[2]["verse"],
            "text": web_verses[2]["text"],
            "translation": "WEB",
            "themes": ["comfort", "fear", "strength", "presence"]
        },
        {
            "id": 4,
            "book": web_verses[3]["book"],
            "chapter": web_verses[3]["chapter"],
            "verse": web_verses[3]["verse"],
            "text": web_verses[3]["text"],
            "translation": "WEB",
            "themes": ["comfort", "provision", "trust", "peace"]
        },
        {
            "id": 5,
            "book": web_verses[4]["book"],
            "chapter": web_verses[4]["chapter"],
            "verse": web_verses[4]["verse"],
            "text": web_verses[4]["text"],
            "translation": "WEB",
            "themes": ["hope", "purpose", "trust", "guidance"]
        },
        {
            "id": 6,
            "book": web_verses[5]["book"],
            "chapter": web_verses[5]["chapter"],
            "verse": web_verses[5]["verse"],
            "text": web_verses[5]["text"],
            "translation": "WEB",
            "themes": ["trust", "wisdom", "guidance", "surrender"]
        },
        {
            "id": 7,
            "book": web_verses[6]["book"],
            "chapter": web_verses[6]["chapter"],
            "verse": web_verses[6]["verse"],
            "text": web_verses[6]["text"],
            "translation": "WEB",
            "themes": ["rest", "comfort", "burden", "invitation"]
        },
        {
            "id": 8,
            "book": web_verses[7]["book"],
            "chapter": web_verses[7]["chapter"],
            "verse": web_verses[7]["verse"],
            "text": web_verses[7]["text"],
            "translation": "WEB",
            "themes": ["grace", "weakness", "strength", "sufficiency"]
        },
        {
            "id": 9,
            "book": web_verses[8]["book"],
            "chapter": web_verses[8]["chapter"],
            "verse": web_verses[8]["verse"],
            "text": web_verses[8]["text"],
            "translation": "WEB",
            "themes": ["courage", "strength", "presence", "fear"]
        },
        {
            "id": 10,
            "book": web_verses[9]["book"],
            "chapter": web_verses[9]["chapter"],
            "verse": web_verses[9]["verse"],
            "text": web_verses[9]["text"],
            "translation": "WEB",
            "themes": ["anxiety", "care", "worry", "trust"]
        }
    ],
    "themes": {
        "comfort": {
            "description": "Verses for times of sadness, grief, or distress",
            "color": "#87CEEB"
        },
        "strength": {
            "description": "Verses for when you need courage and perseverance",
            "color": "#FF6B6B"
        },
        "guidance": {
            "description": "Verses for decision-making and direction",
            "color": "#4ECDC4"
        },
        "hope": {
            "description": "Verses for encouragement and future faith",
            "color": "#45B7D1"
        },
        "trust": {
            "description": "Verses about relying on God's faithfulness",
            "color": "#96CEB4"
        },
        "peace": {
            "description": "Verses for anxiety and restlessness",
            "color": "#FECA57"
        },
        "gratitude": {
            "description": "Verses for thanksgiving and appreciation",
            "color": "#FF9FF3"
        }
    }
}

# Write to file
output_path = '../assets/data/sample_verses.json'
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(sample_data, f, indent=2, ensure_ascii=False)

print(f"\n✅ Updated {output_path} with WEB translations!")
print(f"📊 {len(web_verses)} verses updated")
