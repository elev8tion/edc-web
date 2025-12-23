#!/usr/bin/env python3
"""
Convert pastoral guidance text files to JSONL training format.
Reads structured pastoral guidance and generates training examples.
"""

import json
import re
import os
from pathlib import Path
from typing import List, Dict, Tuple

# Theme mapping for file names
THEME_MAP = {
    "Anger and Bitterness": "anger",
    "Financial Provision": "provision",
    "Forgiveness": "forgiveness",
    "Grief and Loss": "grief",
    "Jealousy and Envy": "jealousy",
    "Loneliness and Isolation": "loneliness",
    "Relationships and Marriage": "relationships",
    "stop complaining": "gratitude",
    "Deal Aggressively with Sin": "sin",
    "Identity & Assurance": "identity",
    "Posture & Perspective": "perspective",
    "sink": "overwhelm",
    "wt": "time_wisdom",
    "kic": "holiness"
}

# User input patterns for each theme
USER_INPUTS = {
    "anger": [
        "I can't let go of what they did",
        "I'm so angry I can't think straight",
        "They don't deserve forgiveness",
        "I want them to pay for this",
        "I keep replaying it in my mind",
        "This rage is consuming me",
        "I said things I can't take back",
        "How do I stop being so angry",
        "I'm bitter and I know it",
        "I can't control my anger anymore"
    ],
    "provision": [
        "I don't know how I'll pay rent",
        "We can't afford what we need",
        "I'm worried about money constantly",
        "God isn't providing for us",
        "Why do others have more than me",
        "I'm tired of financial struggle",
        "Will God really take care of us",
        "I can't tithe right now",
        "I'm overwhelmed by debt",
        "Where is God's provision"
    ],
    "forgiveness": [
        "I can't forgive them",
        "They never even apologized",
        "How many times do I forgive",
        "I can't forget what happened",
        "They hurt me too badly",
        "Do I have to forgive them",
        "What if they do it again",
        "I want to forgive but I can't",
        "They don't deserve it",
        "I keep holding this grudge"
    ],
    "grief": [
        "I can't stop crying",
        "Nothing feels the same anymore",
        "I miss them so much",
        "Why did this happen",
        "I feel so empty inside",
        "The pain won't go away",
        "Everyone else moved on but I can't",
        "How do I keep going",
        "I'm stuck in this sadness",
        "Will I ever feel normal again"
    ],
    "jealousy": [
        "Why do they have what I want",
        "I can't be happy for them",
        "They don't deserve it",
        "I worked harder than they did",
        "Everyone's life looks perfect but mine",
        "I'm so envious of others",
        "Why am I always left behind",
        "I hate feeling this way",
        "I can't stop comparing myself",
        "Why does God bless them and not me"
    ],
    "loneliness": [
        "I feel so alone",
        "Nobody understands me",
        "Everyone has someone but me",
        "I have no one to talk to",
        "Does God see me",
        "I'm invisible to everyone",
        "I'm tired of being alone",
        "Where is everyone when I need them",
        "I feel forgotten",
        "Even in church I feel lonely"
    ],
    "relationships": [
        "My marriage is falling apart",
        "We keep fighting about the same things",
        "I don't feel loved anymore",
        "How do I save my marriage",
        "We've grown apart",
        "I'm not attracted to them anymore",
        "Communication is broken",
        "Should I stay or leave",
        "I feel alone in this marriage",
        "We've lost the spark"
    ],
    "gratitude": [
        "I'm tired of complaining",
        "I can't find anything to be grateful for",
        "Everything is going wrong",
        "Why should I be thankful",
        "I'm stuck in negativity",
        "My attitude is terrible",
        "I focus on what's wrong",
        "How do I stop complaining",
        "I'm ungrateful and I know it",
        "I need a better perspective"
    ],
    "sin": [
        "I keep falling into the same sin",
        "I can't stop this habit",
        "I feel trapped by sin",
        "How do I overcome this",
        "I hate what I'm doing but I can't stop",
        "I'm living a double life",
        "This addiction has me",
        "I'm tired of failing God",
        "Can I really change",
        "I feel powerless against sin"
    ],
    "identity": [
        "I don't know who I am",
        "I feel worthless",
        "Am I really saved",
        "I don't feel like I belong",
        "What is my value to God",
        "I question my salvation",
        "Who am I in Christ",
        "I feel like an outsider",
        "Do I really matter to God",
        "I'm confused about my identity"
    ],
    "perspective": [
        "I need a new mindset",
        "My thinking is all wrong",
        "How do I see things differently",
        "I'm stuck in negative thinking",
        "I need God's perspective",
        "My attitude needs to change",
        "I can't see clearly right now",
        "Help me think biblically",
        "I'm looking at this wrong",
        "I need wisdom and discernment"
    ],
    "overwhelm": [
        "I'm drowning in responsibilities",
        "Everything feels too heavy",
        "I can't keep up with life",
        "I'm spread too thin",
        "I feel like I'm sinking",
        "There's too much on my plate",
        "I can't handle this storm",
        "I'm completely overwhelmed",
        "I'm barely keeping my head up",
        "I don't know how to keep going"
    ],
    "time_wisdom": [
        "I'm wasting my life",
        "Time is slipping away",
        "I'm not using my time well",
        "I have so many regrets",
        "I keep procrastinating",
        "I'm running out of time",
        "How do I make time count",
        "I'm not living purposefully",
        "I feel like I'm drifting",
        "Life is passing me by"
    ],
    "holiness": [
        "I'm lukewarm in my faith",
        "I'm not taking God seriously",
        "I keep making excuses for sin",
        "I want to live holy",
        "I'm playing with sin",
        "I need revival in my heart",
        "I'm spiritually cold",
        "How do I pursue holiness",
        "I'm compromising too much",
        "I need a holy fear of God"
    ]
}


def extract_numbered_points(content: str, theme: str) -> List[Dict[str, str]]:
    """Extract numbered points from structured pastoral guidance."""
    examples = []

    # Pattern: number. Title\n"quote"\nAdvice: text\nScripture Reference: text
    pattern = r'(\d+)\.\s*([^\n]+)\n"([^"]+)"\nAdvice:\s*([^\n]+(?:\n(?!Scripture|^\d+\.)[^\n]+)*)\nScripture Reference:\s*"?([^"—\n]+)"?\s*—\s*([^\n]+)'

    matches = re.finditer(pattern, content, re.MULTILINE | re.DOTALL)

    inputs = USER_INPUTS.get(theme, [])
    input_idx = 0

    for match in matches:
        num, title, quote, advice, verse_text, reference = match.groups()

        # Clean up text
        advice = advice.strip().replace('\n', ' ')
        verse_text = verse_text.strip()
        reference = reference.strip()

        # Get user input
        user_input = inputs[input_idx % len(inputs)] if inputs else f"Help me with {theme}"
        input_idx += 1

        # Format response: quote + advice + scripture
        response = f"{quote} {advice}"
        if verse_text:
            response += f' "{verse_text}" ({reference})'

        examples.append({
            "input": user_input,
            "response": response,
            "theme": theme,
            "scripture": reference,
            "source": "pastoral"
        })

    return examples


def extract_advice_format(content: str, theme: str) -> List[Dict[str, str]]:
    """Extract advice-Bible format (sink.txt, wt.txt style)."""
    examples = []

    # Pattern: number) title\nadvice: text\nBible: references
    pattern = r'(\d+)\)\s*([^\n]+)\nadvice:\s*([^\n]+(?:\n(?!Bible:|^\d+\))[^\n]+)*)\nBible:\s*([^\n]+(?:\n(?!^\d+\))[^\n]+)*)'

    matches = re.finditer(pattern, content, re.MULTILINE | re.DOTALL | re.IGNORECASE)

    inputs = USER_INPUTS.get(theme, [])
    input_idx = 0

    for match in matches:
        num, title, advice, bible_refs = match.groups()

        # Clean up
        title = title.strip()
        advice = advice.strip().replace('\n', ' ')
        bible_refs = bible_refs.strip().replace('\n', ' ')

        # Extract first scripture reference
        scripture_match = re.search(r'([A-Za-z0-9 ]+\s+\d+:\d+(?:-\d+)?)', bible_refs)
        scripture = scripture_match.group(1) if scripture_match else bible_refs[:50]

        # Get user input
        user_input = inputs[input_idx % len(inputs)] if inputs else f"Help me with {theme}"
        input_idx += 1

        # Format response
        response = f"{title}: {advice} (See {scripture})"

        examples.append({
            "input": user_input,
            "response": response,
            "theme": theme,
            "scripture": scripture,
            "source": "pastoral"
        })

    return examples


def extract_heading_format(content: str, theme: str) -> List[Dict[str, str]]:
    """Extract heading-Advice-Bible format (wt.txt style)."""
    examples = []

    # Pattern: emoji/symbol heading\nAdvice:\ntext\nBible References:\nrefs
    pattern = r'[🕰️✝️🌍📖💡❤️🤝🙏🌅]\s*\d+\.\s*([^\n]+)\nAdvice:\n([^\n]+(?:\n(?!Bible References:|^[🕰️✝️🌍📖💡❤️🤝🙏🌅])[^\n]+)*)\nBible References:\n([^\n]+(?:\n(?!^[🕰️✝️🌍📖💡❤️🤝🙏🌅])[^\n]+)*)'

    matches = re.finditer(pattern, content, re.MULTILINE | re.DOTALL)

    inputs = USER_INPUTS.get(theme, [])
    input_idx = 0

    for match in matches:
        title, advice, bible_refs = match.groups()

        # Clean up
        title = title.strip()
        advice = advice.strip().replace('\n', ' ')
        bible_refs = bible_refs.strip()

        # Extract first scripture reference
        scripture_match = re.search(r'"([^"]+)"\s*—\s*([A-Za-z0-9 :]+)', bible_refs)
        scripture = scripture_match.group(2) if scripture_match else bible_refs[:50]

        # Get user input
        user_input = inputs[input_idx % len(inputs)] if inputs else title
        input_idx += 1

        # Format response
        response = f"{title}. {advice}"

        examples.append({
            "input": user_input,
            "response": response,
            "theme": theme,
            "scripture": scripture,
            "source": "pastoral"
        })

    return examples


def extract_bullet_format(content: str, theme: str) -> List[Dict[str, str]]:
    """Extract bullet point format (stop complaining, posture, identity style)."""
    examples = []

    # Split by lines starting with capital letters or bullets
    lines = content.split('\n')
    current_point = ""
    current_scripture = ""

    inputs = USER_INPUTS.get(theme, [])
    input_idx = 0

    for line in lines:
        line = line.strip()

        # Skip empty lines or title
        if not line or line.isupper():
            continue

        # Check if scripture reference
        scripture_match = re.search(r'\(([A-Za-z0-9 :;–\-]+\d+:\d+[–\-\d]*)\)', line)

        if scripture_match:
            current_scripture = scripture_match.group(1)

        # If line looks like a new point (starts with capital, has period/semicolon, or is short statement)
        if (line and line[0].isupper() and
            (line.endswith('.') or line.endswith(';') or len(line) < 150)):

            if current_point and len(current_point) > 20:
                # Save previous point
                user_input = inputs[input_idx % len(inputs)] if inputs else f"Help me with {theme}"
                input_idx += 1

                response = current_point
                if current_scripture:
                    response += f" (See {current_scripture})"

                examples.append({
                    "input": user_input,
                    "response": response,
                    "theme": theme,
                    "scripture": current_scripture or "General wisdom",
                    "source": "pastoral"
                })

            # Start new point
            current_point = line
            current_scripture = ""
        else:
            # Continue current point
            if current_point:
                current_point += " " + line

    # Save last point
    if current_point and len(current_point) > 20:
        user_input = inputs[input_idx % len(inputs)] if inputs else f"Help me with {theme}"

        response = current_point
        if current_scripture:
            response += f" (See {current_scripture})"

        examples.append({
            "input": user_input,
            "response": response,
            "theme": theme,
            "scripture": current_scripture or "General wisdom",
            "source": "pastoral"
        })

    return examples


def extract_sermon_format(content: str, theme: str) -> List[Dict[str, str]]:
    """Extract key points from sermon-style text (kic.txt style)."""
    examples = []

    # Look for key actionable phrases
    key_phrases = [
        r'you can ([^.]+)\.',
        r"don't ([^.]+)\.",
        r'stop ([^.]+)\.',
        r'start ([^.]+)\.',
        r'([A-Z][^.]+God[^.]+)\.',
        r'increase your ([^.]+)\.',
        r'pray (?:for |asking )?([^.]+)\.',
    ]

    inputs = USER_INPUTS.get(theme, [])
    input_idx = 0

    for pattern in key_phrases:
        matches = re.finditer(pattern, content, re.IGNORECASE)
        for match in matches:
            advice = match.group(0).strip()

            # Skip if too short or too long
            if len(advice) < 30 or len(advice) > 200:
                continue

            # Skip if it's a quote attribution
            if any(skip in advice.lower() for skip in ['said', 'scripture says', 'the bible', 'verse']):
                continue

            user_input = inputs[input_idx % len(inputs)] if inputs else f"Help me with {theme}"
            input_idx += 1

            examples.append({
                "input": user_input,
                "response": advice,
                "theme": theme,
                "scripture": "Matthew 5:29-30",  # Default for sin theme
                "source": "pastoral"
            })

    # Limit to reasonable number
    return examples[:15]


def parse_file(file_path: Path) -> Tuple[str, List[Dict[str, str]]]:
    """Parse a pastoral guidance file and return theme and examples."""
    content = file_path.read_text(encoding='utf-8')

    # Determine theme from filename
    filename = file_path.stem.replace('pastoral guidance ', '').strip()
    theme = None
    for key, value in THEME_MAP.items():
        if key.lower() in filename.lower():
            theme = value
            break

    if not theme:
        print(f"⚠️ Unknown theme for {filename}, using filename as theme")
        theme = filename.lower().replace(' ', '_')

    # Try different extraction methods in order
    examples = extract_numbered_points(content, theme)

    if not examples:
        examples = extract_advice_format(content, theme)

    if not examples:
        examples = extract_heading_format(content, theme)

    if not examples:
        examples = extract_bullet_format(content, theme)

    if not examples:
        examples = extract_sermon_format(content, theme)

    if not examples:
        print(f"⚠️ Could not extract examples from {filename}")

    return theme, examples


def main():
    source_dir = Path.home() / "Documents" / "pastoral_guidance"
    output_dir = Path("/Users/kcdacre8tor/everyday-christian/assets/training_data/pastoral_guidance")
    output_dir.mkdir(exist_ok=True, parents=True)

    all_examples = []
    theme_counts = {}

    print("🔄 Converting pastoral guidance files to JSONL...\n")

    # Process each file
    for txt_file in source_dir.glob("*.txt"):
        if txt_file.stat().st_size == 0:
            print(f"⏭️  Skipping empty file: {txt_file.name}")
            continue

        print(f"📄 Processing: {txt_file.name}")
        theme, examples = parse_file(txt_file)

        if examples:
            all_examples.extend(examples)
            theme_counts[theme] = theme_counts.get(theme, 0) + len(examples)
            print(f"   ✅ Extracted {len(examples)} examples (theme: {theme})")
        else:
            print(f"   ❌ No examples extracted")

    # Write combined output
    output_file = output_dir / "all_pastoral_guidance.jsonl"
    with output_file.open('w', encoding='utf-8') as f:
        for example in all_examples:
            f.write(json.dumps(example) + '\n')

    # Write per-theme files
    for theme in theme_counts:
        theme_examples = [ex for ex in all_examples if ex['theme'] == theme]
        theme_file = output_dir / f"{theme}.jsonl"
        with theme_file.open('w', encoding='utf-8') as f:
            for example in theme_examples:
                f.write(json.dumps(example) + '\n')

    # Summary
    print(f"\n✅ Conversion complete!")
    print(f"📊 Total examples: {len(all_examples)}")
    print(f"📁 Output: {output_file}")
    print(f"\n📈 Examples by theme:")
    for theme, count in sorted(theme_counts.items(), key=lambda x: x[1], reverse=True):
        print(f"   {theme}: {count}")


if __name__ == "__main__":
    main()
