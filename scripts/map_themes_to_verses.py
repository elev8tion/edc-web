#!/usr/bin/env python3
"""
Theme-to-Verse Mapping Script
Maps 75 themes to 25 relevant Bible verses each (1,875 total mappings)

Uses keyword matching and manual curation for theological accuracy.
"""

import sqlite3
import json
import re
from collections import defaultdict

# Theme keyword mappings for verse search
THEME_KEYWORDS = {
    # TIER 1: Critical Spiritual (26 themes)
    'doubt': ['doubt', 'unbelief', 'faith', 'believe', 'trust', 'wavering', 'uncertain'],
    'spiritual_dryness': ['dry', 'thirst', 'wilderness', 'desert', 'wait', 'long', 'seek'],
    'backsliding': ['return', 'restore', 'wander', 'stray', 'turn back', 'repent', 'prodigal'],
    'spiritual_warfare': ['enemy', 'devil', 'satan', 'demons', 'armor', 'battle', 'fight', 'war'],
    'bible_reading': ['word', 'scripture', 'law', 'commandments', 'meditate', 'lamp', 'light'],
    'prayer_struggles': ['pray', 'prayer', 'call', 'cry out', 'intercede', 'ask', 'seek'],
    'discernment': ['wisdom', 'discern', 'judge', 'test', 'spirits', 'truth', 'false'],
    'hearing_gods_voice': ['hear', 'voice', 'speak', 'listen', 'call', 'guide', 'lead'],
    'dating': ['marriage', 'unequally yoked', 'love', 'beloved', 'pure', 'wait'],
    'singleness': ['alone', 'unmarried', 'widow', 'single', 'content', 'wait'],
    'parenting': ['children', 'train', 'discipline', 'father', 'mother', 'son', 'daughter'],
    'toxic_relationships': ['flee', 'separate', 'ungodly', 'wicked', 'bad company', 'foolish'],
    'breakup': ['separate', 'leave', 'depart', 'grieve', 'mourn', 'loss'],
    'divorce': ['divorce', 'separate', 'marriage', 'covenant', 'unfaithful', 'adultery'],
    'addiction': ['slave', 'bondage', 'free', 'wine', 'drunk', 'sober', 'self-control'],
    'sexual_purity': ['pure', 'holy', 'sexual immorality', 'fornication', 'flee', 'body temple'],
    'boundaries': ['no', 'limit', 'guard', 'protect', 'separate', 'holy'],
    'bitterness': ['bitter', 'anger', 'resentment', 'forgive', 'grudge', 'root'],
    'unemployment': ['work', 'labor', 'provide', 'job', 'hand', 'diligent'],
    'purpose': ['purpose', 'calling', 'plans', 'works', 'created', 'good works'],
    'transition': ['change', 'new', 'season', 'move', 'go', 'leave'],
    'illness': ['sick', 'heal', 'disease', 'infirm', 'weak', 'body', 'suffer'],
    'church_hurt': ['church', 'brethren', 'offend', 'wound', 'forgive', 'brother'],
    'shame': ['shame', 'condemn', 'guilt', 'righteous', 'clean', 'wash'],
    'guilt': ['guilt', 'forgive', 'cleanse', 'confess', 'sin', 'iniquity'],
    'comparison': ['envy', 'jealous', 'covet', 'compare', 'content', 'eye'],

    # TIER 1: Mental Health (9 themes)
    'anxiety_disorders': ['anxious', 'worry', 'fear', 'afraid', 'peace', 'cast burden', 'care'],
    'depression': ['depress', 'despair', 'downcast', 'soul', 'hope', 'joy', 'sorrow', 'grief'],
    'panic_attacks': ['fear', 'terror', 'tremble', 'overwhelm', 'refuge', 'peace'],
    'trauma': ['wound', 'broken', 'crushed', 'heal', 'bind up', 'restore'],
    'ptsd': ['terror', 'nightmares', 'remember', 'forget', 'peace', 'fear not'],
    'ocd': ['thoughts', 'mind', 'renew', 'peace', 'perfect love casts out fear'],
    'social_anxiety': ['fear man', 'people pleaser', 'afraid', 'bold', 'courage'],
    'burnout': ['weary', 'tired', 'rest', 'burden', 'yoke', 'strength', 'renew'],
    'imposter_syndrome': ['worthy', 'value', 'identity', 'chosen', 'beloved', 'confidence'],
    'perfectionism': ['perfect', 'grace', 'sufficient', 'weakness', 'mercy', 'complete'],

    # TIER 2: Financial (5 themes)
    'debt': ['debt', 'owe', 'borrow', 'lend', 'loan', 'creditor'],
    'poverty': ['poor', 'needy', 'widow', 'orphan', 'oppress', 'justice'],
    'financial_anxiety': ['provide', 'need', 'supply', 'bread', 'daily', 'wealth', 'money'],
    'materialism': ['treasure', 'riches', 'possess', 'store up', 'moth', 'rust', 'money'],
    'tithing_giving': ['give', 'tithe', 'offering', 'generous', 'cheerful giver', 'first fruits'],

    # TIER 2: Career (6 themes)
    'career_uncertainty': ['work', 'labor', 'hand', 'calling', 'purpose', 'plans'],
    'workplace_conflict': ['conflict', 'enemy', 'persecution', 'master', 'serve', 'work'],
    'calling_purpose': ['purpose', 'calling', 'plans', 'will', 'good works', 'created'],
    'retirement': ['old age', 'gray hair', 'youth', 'strength', 'declare', 'generation'],
    'work_life_balance': ['rest', 'sabbath', 'balance', 'time', 'family', 'work'],

    # TIER 2: Family (7 themes)
    'aging_parents': ['father', 'mother', 'honor', 'parents', 'old', 'care'],
    'infertility': ['barren', 'womb', 'conceive', 'child', 'children', 'offspring'],
    'blended_families': ['family', 'household', 'children', 'father', 'mother', 'love'],
    'adult_children': ['children', 'son', 'daughter', 'prodigal', 'train', 'depart'],
    'family_conflict': ['brother', 'family', 'strife', 'peace', 'reconcile', 'forgive'],
    'sibling_rivalry': ['brother', 'jealous', 'envy', 'cain', 'abel', 'favoritism'],

    # TIER 2: Social (5 themes)
    'loneliness': ['alone', 'lonely', 'friend', 'companion', 'forsake', 'leave'],
    'friendship_struggles': ['friend', 'companion', 'brother', 'neighbor', 'love', 'betray'],
    'social_media_comparison': ['envy', 'jealous', 'compare', 'covet', 'content'],
    'rejection': ['reject', 'despise', 'forsake', 'abandon', 'accept', 'chosen'],
    'conflict_resolution': ['conflict', 'forgive', 'brother', 'offend', 'reconcile', 'peace'],

    # TIER 2: Young Adult (5 themes)
    'identity_formation': ['identity', 'who', 'called', 'created', 'chosen', 'beloved'],
    'college_faith': ['youth', 'young', 'remember', 'wisdom', 'knowledge', 'teaching'],
    'quarter_life_crisis': ['purpose', 'plans', 'future', 'hope', 'path', 'way'],
    'dating_apps': ['marriage', 'pure', 'holy', 'love', 'wait', 'patience'],
    'student_debt': ['debt', 'borrow', 'owe', 'free', 'burden', 'provide'],

    # TIER 3: Cultural & Identity (12 themes)
    'racial_justice': ['justice', 'oppression', 'poor', 'equity', 'image of god', 'favoritism'],
    'gender_confusion': ['male', 'female', 'created', 'image', 'man', 'woman'],
    'lgbtq_struggles': ['sexual immorality', 'love', 'sin', 'holy', 'pure', 'temple'],
    'immigration': ['stranger', 'foreigner', 'alien', 'sojourn', 'welcome', 'hospitable'],
    'cultural_identity': ['nation', 'tribe', 'tongue', 'people', 'gather', 'diversity'],
    'information_overload': ['peace', 'quiet', 'still', 'know', 'meditate', 'think'],
    'decision_fatigue': ['wisdom', 'choose', 'decision', 'guide', 'lead', 'path'],
    'hustle_culture': ['rest', 'sabbath', 'weary', 'burden', 'peace', 'work'],
    'cancel_culture': ['forgive', 'mercy', 'condemn', 'judge', 'grace', 'restore'],
    'conspiracy_theories': ['truth', 'lies', 'deceive', 'discern', 'wisdom', 'fear'],
    'ai_anxiety': ['future', 'fear not', 'trust', 'sovereign', 'control', 'peace'],
    'gun_violence': ['violence', 'murder', 'kill', 'sword', 'peace', 'justice', 'mourn'],

    # FOUNDATIONAL (5 themes)
    'hope': ['hope', 'anchor', 'promise', 'future', 'wait', 'expectation'],
    'strength': ['strength', 'strong', 'power', 'mighty', 'weak', 'renew'],
    'comfort': ['comfort', 'mourn', 'grieve', 'sorrow', 'weep', 'console'],
    'love': ['love', 'beloved', 'loved', 'agape', 'compassion', 'mercy'],
    'identity_in_christ': ['in christ', 'new creation', 'child of god', 'chosen', 'righteous'],
}

def normalize_text(text):
    """Normalize text for keyword matching"""
    return text.lower().strip()

def search_verses_for_theme(cursor, theme_name, keywords, limit=50):
    """
    Search for verses matching theme keywords
    Returns list of tuples: (verse_id, reference, clean_text, match_score)
    """
    results = []

    for keyword in keywords:
        # Search in clean_text column
        query = """
            SELECT id, reference, clean_text
            FROM verses
            WHERE clean_text LIKE ?
            LIMIT ?
        """

        # Use wildcards for flexible matching
        pattern = f'%{keyword}%'
        cursor.execute(query, (pattern, limit))

        for verse_id, reference, clean_text in cursor.fetchall():
            # Calculate simple match score (number of keyword matches)
            score = sum(1 for kw in keywords if kw in normalize_text(clean_text))
            results.append((verse_id, reference, clean_text, score))

    # Sort by match score (highest first) and deduplicate
    seen_verses = set()
    unique_results = []
    for verse_id, reference, clean_text, score in sorted(results, key=lambda x: x[3], reverse=True):
        if verse_id not in seen_verses:
            seen_verses.add(verse_id)
            unique_results.append({
                'verse_id': verse_id,
                'reference': reference,
                'text': clean_text,
                'match_score': score
            })

    return unique_results[:25]  # Return top 25 verses

def create_theme_verse_mappings(db_path, output_path):
    """Create mappings for all 75 themes"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    all_mappings = {}

    print("🔍 Mapping themes to Bible verses...\n")

    for theme_name, keywords in THEME_KEYWORDS.items():
        print(f"  Processing: {theme_name} ({len(keywords)} keywords)")

        verses = search_verses_for_theme(cursor, theme_name, keywords)

        all_mappings[theme_name] = {
            'theme': theme_name,
            'keywords': keywords,
            'verse_count': len(verses),
            'verses': verses
        }

        print(f"    ✓ Found {len(verses)} verses\n")

    conn.close()

    # Save to JSON
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(all_mappings, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Created mappings for {len(all_mappings)} themes")
    print(f"📄 Saved to: {output_path}")

    # Print summary statistics
    total_verses = sum(len(m['verses']) for m in all_mappings.values())
    avg_verses = total_verses / len(all_mappings)

    print(f"\n📊 Statistics:")
    print(f"  Total themes: {len(all_mappings)}")
    print(f"  Total verse mappings: {total_verses}")
    print(f"  Average verses per theme: {avg_verses:.1f}")

    return all_mappings

def verify_mappings(mappings):
    """Verify mapping quality and print sample"""
    print("\n" + "="*60)
    print("Sample Theme-Verse Mappings:")
    print("="*60)

    # Show samples from different tiers
    sample_themes = ['anxiety_disorders', 'doubt', 'hope', 'racial_justice', 'parenting']

    for theme in sample_themes:
        if theme in mappings:
            mapping = mappings[theme]
            print(f"\n📖 {theme.upper().replace('_', ' ')}")
            print(f"Keywords: {', '.join(mapping['keywords'][:5])}...")
            print(f"Verses found: {mapping['verse_count']}")

            # Show top 3 verses
            for i, verse in enumerate(mapping['verses'][:3], 1):
                print(f"\n  {i}. {verse['reference']} (score: {verse['match_score']})")
                # Truncate long verses
                text = verse['text'][:100] + "..." if len(verse['text']) > 100 else verse['text']
                print(f"     {text}")

    print("\n" + "="*60)

def main():
    db_path = "../assets/bible.db"
    output_path = "../assets/training_data/theme_verse_mappings.json"

    print("Theme-to-Verse Mapping Script")
    print("="*60)
    print(f"Database: {db_path}")
    print(f"Output: {output_path}\n")

    # Create mappings
    mappings = create_theme_verse_mappings(db_path, output_path)

    # Verify and show samples
    verify_mappings(mappings)

    print("\n✅ Theme-verse mapping complete!")
    print("\n📋 Next steps:")
    print("  1. Review mappings for theological accuracy")
    print("  2. Manually adjust verses if needed")
    print("  3. Generate training examples using these mappings")

if __name__ == "__main__":
    main()
