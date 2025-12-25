#!/usr/bin/env python3
"""
Intelligent Knowledge Base Builder

Creates AI-analyzed, searchable knowledge bases from video tutorials.
This system enables Claude to use the knowledge base as a resource when helping users.
"""

import os
import json
import subprocess
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any
import base64

# Configuration
HOME = Path.home()
KB_BASE_DIR = HOME / "knowledge-bases"


class KnowledgeBaseBuilder:
    """Build intelligent, searchable knowledge bases from video tutorials"""

    def __init__(self, topic: str, source_dir: Path):
        self.topic = topic
        self.source_dir = source_dir
        self.kb_dir = KB_BASE_DIR / topic
        self.topics_dir = self.kb_dir / "topics"
        self.tech_dir = self.kb_dir / "technologies"
        self.code_dir = self.kb_dir / "code-snippets"
        self.search_dir = self.kb_dir / "search-index"

        # Create directory structure
        for dir_path in [self.kb_dir, self.topics_dir, self.tech_dir,
                         self.code_dir, self.search_dir]:
            dir_path.mkdir(parents=True, exist_ok=True)

    def log(self, message: str, level="INFO"):
        """Log with timestamp and color"""
        colors = {
            "INFO": "\033[0;34m",
            "SUCCESS": "\033[0;32m",
            "WARNING": "\033[1;33m",
            "ERROR": "\033[0;31m",
        }
        reset = "\033[0m"
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        color = colors.get(level, "")
        print(f"{color}[{timestamp}] [{level}]{reset} {message}")

    def analyze_frame_with_ai(self, frame_path: Path) -> Dict[str, Any]:
        """
        Analyze a frame using Claude's vision capabilities

        This would integrate with Claude API to analyze frames.
        For now, returns a structured template.
        """
        return {
            "frame_path": str(frame_path),
            "screen_type": "unknown",  # IDE, browser, terminal, docs, diagram
            "visible_code": [],
            "ui_components": [],
            "technologies": [],
            "concepts": [],
            "difficulty": "unknown",
            "context": ""
        }

    def extract_topics_from_frames(self, frame_directories: List[Path]) -> Dict[str, List[str]]:
        """
        Analyze all frames and extract topics

        Returns mapping of topic -> list of relevant frame paths
        """
        topics = {
            "authentication": [],
            "database": [],
            "api-design": [],
            "frontend": [],
            "deployment": [],
            "testing": [],
            "configuration": [],
        }

        self.log(f"Analyzing {len(frame_directories)} video frame sets...")

        for video_dir in frame_directories:
            frames = sorted(video_dir.glob("*.png"))
            self.log(f"Processing {len(frames)} frames from {video_dir.name}")

            # Sample frames for analysis (every Nth frame to save time)
            sample_interval = max(1, len(frames) // 20)  # Sample ~20 frames per video
            sampled_frames = frames[::sample_interval]

            for frame in sampled_frames:
                # In a full implementation, this would use AI to analyze
                # For now, we organize by video
                # This is where Claude vision API would be called
                pass

        return topics

    def build_topic_structure(self, topics: Dict[str, List[str]]):
        """Create organized topic directories with metadata"""
        for topic_name, frame_paths in topics.items():
            topic_dir = self.topics_dir / topic_name
            topic_dir.mkdir(exist_ok=True)

            # Create subdirectories
            (topic_dir / "concepts").mkdir(exist_ok=True)
            (topic_dir / "code-examples").mkdir(exist_ok=True)
            (topic_dir / "frames").mkdir(exist_ok=True)

            # Create topic metadata
            metadata = {
                "topic": topic_name,
                "frame_count": len(frame_paths),
                "last_updated": datetime.now().isoformat(),
                "frames": [str(p) for p in frame_paths]
            }

            with open(topic_dir / "metadata.json", 'w') as f:
                json.dump(metadata, f, indent=2)

            # Create concepts guide (template)
            concepts_md = topic_dir / "concepts" / "overview.md"
            concepts_md.write_text(f"""# {topic_name.title()} Concepts

## Overview

This topic covers {topic_name} concepts from the {self.topic} tutorial series.

## Key Concepts

_To be populated with AI-extracted concepts_

## Code Examples

See the `code-examples/` directory for implementations.

## Related Topics

_To be populated with related topics_

## Frames

{len(frame_paths)} frames reference this topic.
""")

    def create_master_index(self, frame_directories: List[Path]):
        """Create master searchable index"""
        index = {
            "knowledge_base": self.topic,
            "created_at": datetime.now().isoformat(),
            "total_videos": len(frame_directories),
            "total_frames": sum(len(list(d.glob("*.png"))) for d in frame_directories),
            "topics": {},
            "technologies": {},
            "videos": []
        }

        for video_dir in frame_directories:
            frames = list(video_dir.glob("*.png"))
            video_info = {
                "directory": str(video_dir),
                "name": video_dir.name,
                "frame_count": len(frames),
                "frames": [str(f) for f in frames]
            }
            index["videos"].append(video_info)

        # Save master index
        index_path = self.search_dir / "master_index.json"
        with open(index_path, 'w') as f:
            json.dump(index, f, indent=2)

        self.log(f"Master index created: {index_path}", "SUCCESS")
        return index

    def create_search_guide(self):
        """Create guide for searching the knowledge base"""
        guide_path = self.kb_dir / "SEARCH_GUIDE.md"
        guide_path.write_text(f"""# {self.topic} Knowledge Base Search Guide

## Quick Start

This knowledge base can be searched in multiple ways:

### 1. Browse by Topic

```bash
cd {self.topics_dir}
ls
```

Topics include:
- authentication
- database
- api-design
- frontend
- deployment
- testing
- configuration

### 2. Browse by Technology

```bash
cd {self.tech_dir}
ls
```

### 3. Search Code Snippets

```bash
cd {self.code_dir}
find . -name "*.js" -o -name "*.py" -o -name "*.json"
```

### 4. Query with JSON Index

```python
import json

with open("{self.search_dir}/master_index.json") as f:
    index = json.load(f)

# Search for frames
for video in index["videos"]:
    print(f"{{video['name']}}: {{video['frame_count']}} frames")
```

## Using with Claude

When working with Claude, you can ask:

- "Show me frames related to authentication"
- "Find code examples for database setup"
- "What topics are covered in video 5?"
- "Extract all API endpoint examples"

Claude can navigate this knowledge base structure to find relevant information.

## Advanced Queries

### Find Specific Frame
```bash
find {self.kb_dir} -name "frame_0045.png"
```

### Search Topics
```bash
grep -r "authentication" {self.topics_dir}
```

### List All Code Files
```bash
find {self.code_dir} -type f
```

---

**Last Updated:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
""")

        self.log(f"Search guide created: {guide_path}", "SUCCESS")

    def build(self):
        """Main build process"""
        self.log("="*60)
        self.log(f"Building Knowledge Base: {self.topic}")
        self.log("="*60)

        # Find all frame directories
        frame_dirs = [d for d in self.source_dir.iterdir()
                     if d.is_dir() and list(d.glob("*.png"))]

        if not frame_dirs:
            self.log("No frame directories found!", "ERROR")
            return False

        self.log(f"Found {len(frame_dirs)} video frame sets", "SUCCESS")

        # Extract topics
        self.log("\n📊 Extracting topics from frames...")
        topics = self.extract_topics_from_frames(frame_dirs)

        # Build topic structure
        self.log("\n📁 Building topic structure...")
        self.build_topic_structure(topics)

        # Create master index
        self.log("\n🔍 Creating master search index...")
        index = self.create_master_index(frame_dirs)

        # Create search guide
        self.log("\n📖 Creating search guide...")
        self.create_search_guide()

        # Create metadata
        metadata = {
            "topic": self.topic,
            "created_at": datetime.now().isoformat(),
            "source_directory": str(self.source_dir),
            "total_videos": index["total_videos"],
            "total_frames": index["total_frames"],
            "topics": list(topics.keys()),
            "version": "2.0"
        }

        with open(self.kb_dir / "metadata.json", 'w') as f:
            json.dump(metadata, f, indent=2)

        # Final summary
        self.log("\n" + "="*60)
        self.log("KNOWLEDGE BASE BUILD COMPLETE", "SUCCESS")
        self.log("="*60)
        self.log(f"Location: {self.kb_dir}")
        self.log(f"Videos: {index['total_videos']}")
        self.log(f"Frames: {index['total_frames']}")
        self.log(f"Topics: {len(topics)}")
        self.log("\n📖 Next Steps:")
        self.log(f"1. Review the search guide: {self.kb_dir}/SEARCH_GUIDE.md")
        self.log(f"2. Browse topics: {self.topics_dir}")
        self.log(f"3. Ask Claude to search the knowledge base!")

        return True


def main():
    """Main entry point"""
    import sys

    if len(sys.argv) < 3:
        print("Usage: python intelligent_kb_builder.py <topic> <source_directory>")
        print("Example: python intelligent_kb_builder.py NoCodeBackend ~/xtractedyt/frames/NoCodeBackend")
        sys.exit(1)

    topic = sys.argv[1]
    source_dir = Path(sys.argv[2])

    if not source_dir.exists():
        print(f"Error: Source directory not found: {source_dir}")
        sys.exit(1)

    builder = KnowledgeBaseBuilder(topic, source_dir)
    success = builder.build()

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
