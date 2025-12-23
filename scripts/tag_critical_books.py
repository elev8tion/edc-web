#!/usr/bin/env python3
"""
Fast Bible Theme Tagger - Tags critical books (Psalms + NT) using Claude API
Uses batch processing and parallel requests for maximum speed.
"""

import sqlite3
import json
import os
import sys
from anthropic import Anthropic
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Dict, Tuple
import time

# Available themes (from your app)
AVAILABLE_THEMES = [
    "hope", "faith", "love", "grace", "mercy", "forgiveness", "redemption",
    "salvation", "peace", "joy", "comfort", "strength", "courage", "wisdom",
    "guidance", "protection", "provision", "healing", "restoration", "patience",
    "perseverance", "humility", "obedience", "repentance", "prayer", "worship",
    "praise", "thanksgiving", "trust", "fear", "anxiety", "depression", "grief",
    "suffering", "trials", "temptation", "sin", "justice", "righteousness",
    "holiness", "truth", "faithfulness", "compassion", "kindness", "gentleness",
    "self-control", "family", "marriage", "relationships", "friendship", "leadership",
    "service", "stewardship", "generosity", "evangelism", "discipleship", "unity",
    "church", "kingdom", "eternal life", "heaven", "resurrection", "second coming",
    "spiritual warfare", "holy spirit", "creator", "sovereignty", "power", "presence"
]

class BibleThemeTagger:
    def __init__(self, db_path: str, batch_size: int = 50):
        self.db_path = db_path
        self.batch_size = batch_size
        self.client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))

    def get_untagged_verses(self, books: List[str]) -> List[Tuple[int, str, str]]:
        """Get all untagged verses from specified books"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        placeholders = ','.join('?' * len(books))
        query = f"""
            SELECT id, reference, text
            FROM verses
            WHERE book IN ({placeholders})
            AND (themes IS NULL OR themes = '' OR LENGTH(themes) <= 2)
            ORDER BY id
        """

        cursor.execute(query, books)
        verses = cursor.fetchall()
        conn.close()

        return verses

    def tag_batch(self, verses: List[Tuple[int, str, str]]) -> List[Tuple[int, str]]:
        """Tag a batch of verses using Claude API"""
        # Format batch for Claude
        verse_text = "\n\n".join([
            f"[{v[0]}] {v[1]}\n{v[2][:200]}..." if len(v[2]) > 200 else f"[{v[0]}] {v[1]}\n{v[2]}"
            for v in verses
        ])

        prompt = f"""Analyze these Bible verses and assign 1-3 relevant themes from this list:
{', '.join(AVAILABLE_THEMES)}

Return ONLY a JSON array of objects with this format:
[{{"id": verse_id, "themes": ["theme1", "theme2"]}}, ...]

Be concise - pick the most relevant 1-3 themes per verse.

Verses:
{verse_text}"""

        try:
            message = self.client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=4000,
                messages=[{"role": "user", "content": prompt}]
            )

            # Parse response
            response_text = message.content[0].text.strip()

            # Extract JSON (might be wrapped in markdown)
            if "```json" in response_text:
                response_text = response_text.split("```json")[1].split("```")[0].strip()
            elif "```" in response_text:
                response_text = response_text.split("```")[1].split("```")[0].strip()

            results = json.loads(response_text)

            # Convert to (id, json_themes) tuples
            return [(r["id"], json.dumps(r["themes"])) for r in results]

        except Exception as e:
            print(f"Error tagging batch: {e}")
            return []

    def update_themes(self, tagged_verses: List[Tuple[int, str]]):
        """Update database with tagged themes"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.executemany(
            "UPDATE verses SET themes = ? WHERE id = ?",
            [(themes, vid) for vid, themes in tagged_verses]
        )

        conn.commit()
        conn.close()

    def tag_books(self, books: List[str], max_workers: int = 3):
        """Tag all verses in specified books"""
        print(f"\n🔍 Finding untagged verses in: {', '.join(books)}")
        verses = self.get_untagged_verses(books)
        total = len(verses)

        if total == 0:
            print("✅ All verses already tagged!")
            return

        print(f"📊 Found {total} untagged verses")
        print(f"🚀 Processing in batches of {self.batch_size} with {max_workers} parallel workers\n")

        # Split into batches
        batches = [verses[i:i + self.batch_size] for i in range(0, len(verses), self.batch_size)]

        completed = 0
        start_time = time.time()

        # Process batches in parallel
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            future_to_batch = {executor.submit(self.tag_batch, batch): i
                             for i, batch in enumerate(batches)}

            for future in as_completed(future_to_batch):
                batch_num = future_to_batch[future]
                try:
                    tagged = future.result()
                    if tagged:
                        self.update_themes(tagged)
                        completed += len(tagged)

                        elapsed = time.time() - start_time
                        rate = completed / elapsed if elapsed > 0 else 0
                        remaining = total - completed
                        eta = remaining / rate if rate > 0 else 0

                        print(f"✓ Batch {batch_num + 1}/{len(batches)}: {completed}/{total} verses "
                              f"({100*completed/total:.1f}%) | "
                              f"Rate: {rate:.1f} verses/sec | "
                              f"ETA: {eta/60:.1f} min")
                except Exception as e:
                    print(f"✗ Batch {batch_num + 1} failed: {e}")

        elapsed = time.time() - start_time
        print(f"\n✅ Completed {completed}/{total} verses in {elapsed/60:.1f} minutes")
        print(f"📈 Average rate: {completed/elapsed:.1f} verses/second")

def main():
    # Check for API key
    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("❌ Error: ANTHROPIC_API_KEY environment variable not set")
        print("\nSet it with:")
        print('  export ANTHROPIC_API_KEY="your-key-here"')
        sys.exit(1)

    db_path = "assets/bible.db"

    if not os.path.exists(db_path):
        print(f"❌ Error: Database not found at {db_path}")
        sys.exit(1)

    tagger = BibleThemeTagger(db_path, batch_size=50)

    # Priority 1: Psalms (most important comfort book)
    print("=" * 70)
    print("PHASE 1: PSALMS (2,461 verses)")
    print("=" * 70)
    tagger.tag_books(["Psalms"], max_workers=4)

    # Priority 2: Gospels
    print("\n" + "=" * 70)
    print("PHASE 2: GOSPELS (3,779 verses)")
    print("=" * 70)
    tagger.tag_books(["Matthew", "Mark", "Luke", "John"], max_workers=4)

    # Priority 3: Key Epistles
    print("\n" + "=" * 70)
    print("PHASE 3: KEY EPISTLES (788 verses)")
    print("=" * 70)
    tagger.tag_books(["Romans", "Ephesians", "Philippians", "Colossians",
                      "1 Corinthians", "2 Corinthians", "Galatians"], max_workers=4)

    # Final stats
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM verses")
    total = cursor.fetchone()[0]
    cursor.execute("SELECT COUNT(*) FROM verses WHERE themes IS NOT NULL AND LENGTH(themes) > 2")
    tagged = cursor.fetchone()[0]
    conn.close()

    print("\n" + "=" * 70)
    print("📊 FINAL COVERAGE")
    print("=" * 70)
    print(f"Total verses: {total:,}")
    print(f"Tagged verses: {tagged:,}")
    print(f"Coverage: {100*tagged/total:.1f}%")

if __name__ == "__main__":
    main()
