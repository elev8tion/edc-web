#!/usr/bin/env python3
"""
Bible Theme Tagger for Galatians, Ephesians, Philippians, Colossians
Assigns 1-3 relevant biblical themes to verses based on content analysis.
"""

import sqlite3
import json
import re

# Database path
DB_PATH = '/Users/kcdacre8tor/thereal-everyday-christian/assets/bible.db'

# Available themes
THEMES = [
    "hope", "faith", "love", "grace", "mercy", "freedom", "joy", "peace",
    "unity", "humility", "perseverance", "spiritual warfare", "righteousness",
    "holiness", "wisdom", "guidance", "strength", "thanksgiving", "prayer"
]

def analyze_verse(reference, text):
    """
    Analyze verse text and assign 1-3 relevant themes.
    Returns a JSON array of theme strings.
    """
    text_lower = text.lower()
    assigned_themes = []

    # Theme detection patterns (prioritized by specificity)
    theme_patterns = {
        "faith": [r'\bfaith\b', r'\bbeliev', r'\btrust\b'],
        "love": [r'\blove\b', r'\bloved\b', r'\bloving\b', r'\bcharity\b'],
        "grace": [r'\bgrace\b', r'\bgracious\b'],
        "hope": [r'\bhope\b', r'\bhopeful\b'],
        "peace": [r'\bpeace\b', r'\bpeaceful\b', r'\breconcil'],
        "joy": [r'\bjoy\b', r'\bjoying\b', r'\brejoic'],
        "freedom": [r'\bfree\b', r'\bfreedom\b', r'\bliberty\b', r'\bdeliver'],
        "mercy": [r'\bmercy\b', r'\bmerciful\b', r'\bcompassion'],
        "unity": [r'\bunity\b', r'\bunited\b', r'\bone body\b', r'\btogether\b', r'\bknit'],
        "humility": [r'\bhumbl', r'\blowly\b', r'\bmeek\b', r'\bservant\b'],
        "perseverance": [r'\bendur', r'\bpersever', r'\bsteadfast\b', r'\bpatien'],
        "spiritual warfare": [r'\barmor\b', r'\bwarfare\b', r'\bbattle\b', r'\bstruggle\b', r'\bprincipalities\b', r'\bpowers\b', r'\bdarkness\b'],
        "righteousness": [r'\bright', r'\bjust\b', r'\bjustice\b', r'\bholy\b'],
        "holiness": [r'\bholy\b', r'\bholiness\b', r'\bsaint\b', r'\bsanctif'],
        "wisdom": [r'\bwisdom\b', r'\bwise\b', r'\bunderstand'],
        "guidance": [r'\bguide\b', r'\blead\b', r'\bdirect', r'\bwalk\b', r'\bpath\b'],
        "strength": [r'\bstrength\b', r'\bstrong\b', r'\bpower\b', r'\bmight\b'],
        "thanksgiving": [r'\bthank', r'\bgrateful\b', r'\bgratitude\b'],
        "prayer": [r'\bpray\b', r'\bpraying\b', r'\bprayer\b', r'\bintercession\b']
    }

    # Score each theme based on pattern matches
    theme_scores = {}
    for theme, patterns in theme_patterns.items():
        score = sum(1 for pattern in patterns if re.search(pattern, text_lower))
        if score > 0:
            theme_scores[theme] = score

    # Sort by score and take top 3
    sorted_themes = sorted(theme_scores.items(), key=lambda x: x[1], reverse=True)
    assigned_themes = [theme for theme, score in sorted_themes[:3]]

    # Context-based refinements for specific books/chapters
    if "Galatians" in reference:
        if any(re.search(pattern, text_lower) for pattern in [r'\blaw\b', r'\bcircumcis']):
            if "freedom" not in assigned_themes and len(assigned_themes) < 3:
                assigned_themes.append("freedom")
        if re.search(r'\bspirit\b', text_lower) and "holiness" not in assigned_themes and len(assigned_themes) < 3:
            assigned_themes.append("holiness")

    if "Ephesians" in reference:
        if re.search(r'\bchurch\b|\bbody\b', text_lower) and "unity" not in assigned_themes and len(assigned_themes) < 3:
            assigned_themes.append("unity")

    if "Philippians" in reference:
        if any(re.search(pattern, text_lower) for pattern in [r'\bjoy\b', r'\brejoic']) and "joy" not in assigned_themes:
            if len(assigned_themes) < 3:
                assigned_themes.append("joy")
            elif "joy" not in assigned_themes:
                assigned_themes[0] = "joy"

    if "Colossians" in reference:
        if re.search(r'\bchrist\b.*\ball\b|\bfullness\b', text_lower) and len(assigned_themes) < 3:
            if "holiness" not in assigned_themes:
                assigned_themes.append("holiness")

    # Return top 3 themes (or fewer if less were found)
    return assigned_themes[:3]

def main():
    print("Starting Bible Theme Tagger...")
    print(f"Database: {DB_PATH}")

    # Connect to database
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Get verses to tag
    query = """
        SELECT id, reference, text
        FROM verses
        WHERE book IN ('Galatians','Ephesians','Philippians','Colossians')
        AND (themes IS NULL OR LENGTH(themes) <= 2)
    """

    cursor.execute(query)
    verses = cursor.fetchall()

    print(f"Found {len(verses)} verses to tag")

    # Process in batches of 50
    batch_size = 50
    total_updated = 0

    for i in range(0, len(verses), batch_size):
        batch = verses[i:i+batch_size]
        print(f"\nProcessing batch {i//batch_size + 1} ({len(batch)} verses)...")

        for verse_id, reference, text in batch:
            # Analyze and assign themes
            themes = analyze_verse(reference, text)
            themes_json = json.dumps(themes)

            # Update database
            cursor.execute(
                "UPDATE verses SET themes = ? WHERE id = ?",
                (themes_json, verse_id)
            )
            total_updated += 1

            if total_updated % 50 == 0:
                print(f"  Updated {total_updated} verses...")

        # Commit after each batch
        conn.commit()
        print(f"  Batch committed ({total_updated} total)")

    # Final commit
    conn.commit()

    # Verify results
    cursor.execute("""
        SELECT COUNT(*)
        FROM verses
        WHERE book IN ('Galatians','Ephesians','Philippians','Colossians')
        AND themes IS NOT NULL
        AND LENGTH(themes) > 2
    """
    )
    tagged_count = cursor.fetchone()[0]

    print(f"\n{'='*50}")
    print(f"COMPLETE!")
    print(f"Total verses updated: {total_updated}")
    print(f"Total verses with themes: {tagged_count}")
    print(f"{'='*50}")

    # Show sample results
    print("\nSample tagged verses:")
    cursor.execute("""
        SELECT reference, themes
        FROM verses
        WHERE book IN ('Galatians','Ephesians','Philippians','Colossians')
        AND themes IS NOT NULL
        ORDER BY RANDOM()
        LIMIT 5
    """)

    for ref, themes in cursor.fetchall():
        print(f"  {ref}: {themes}")

    conn.close()

if __name__ == "__main__":
    main()
