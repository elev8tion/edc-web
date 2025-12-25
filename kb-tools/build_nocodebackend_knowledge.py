#!/usr/bin/env python3
"""
NoCodeBackend Knowledge Base Builder

Analyzes extracted frames and builds a searchable knowledge base using memvid.
"""

import os
import json
import subprocess
from pathlib import Path
from datetime import datetime
import sys

# Configuration
HOME = Path.home()
NOCODEBACKEND_DIR = HOME / "xtractedyt" / "frames" / "NoCodeBackend"
KNOWLEDGE_BASE_NAME = "nocodebackend-tutorials"
KNOWLEDGE_BASE_DIR = NOCODEBACKEND_DIR / "knowledge_base"


def log(message, level="INFO"):
    """Log messages with timestamp"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    colors = {
        "INFO": "\033[0;34m",
        "SUCCESS": "\033[0;32m",
        "WARNING": "\033[1;33m",
        "ERROR": "\033[0;31m",
    }
    reset = "\033[0m"
    color = colors.get(level, "")
    print(f"{color}[{timestamp}] [{level}]{reset} {message}")


def find_all_frame_directories():
    """Find all directories containing extracted frames"""
    frame_dirs = []

    if not NOCODEBACKEND_DIR.exists():
        log(f"NoCodeBackend directory not found: {NOCODEBACKEND_DIR}", "ERROR")
        return frame_dirs

    for item in NOCODEBACKEND_DIR.iterdir():
        if item.is_dir():
            # Check if directory contains PNG frames
            png_files = list(item.glob("*.png"))
            if png_files:
                frame_dirs.append({
                    "path": item,
                    "name": item.name,
                    "frame_count": len(png_files),
                    "frames": sorted(png_files)
                })

    return frame_dirs


def create_knowledge_index(frame_dirs):
    """Create an index of all frames for knowledge base"""
    index_data = {
        "created_at": datetime.now().isoformat(),
        "total_videos": len(frame_dirs),
        "total_frames": sum(d["frame_count"] for d in frame_dirs),
        "videos": []
    }

    for video_data in frame_dirs:
        video_info = {
            "name": video_data["name"],
            "frame_count": video_data["frame_count"],
            "directory": str(video_data["path"]),
            "frames": [str(f) for f in video_data["frames"]]
        }
        index_data["videos"].append(video_info)

    return index_data


def create_markdown_documentation(frame_dirs, index_data):
    """Create comprehensive markdown documentation for all videos"""
    doc_path = KNOWLEDGE_BASE_DIR / "NoCodeBackend_Learning_Guide.md"

    content = f"""# NoCodeBackend Tutorial Learning Guide

**Generated:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
**Total Videos:** {index_data['total_videos']}
**Total Frames:** {index_data['total_frames']}

---

## 📚 Tutorial Collection Overview

This knowledge base contains extracted frames and learning materials from a comprehensive NoCodeBackend tutorial series.

### Contents

"""

    for idx, video in enumerate(index_data['videos'], 1):
        content += f"{idx}. **{video['name']}** - {video['frame_count']} frames\n"

    content += f"""
---

## 🎯 Frame Analysis

### Frame Distribution

"""

    for video in index_data['videos']:
        content += f"#### {video['name']}\n\n"
        content += f"- **Frames:** {video['frame_count']}\n"
        content += f"- **Directory:** `{video['directory']}`\n\n"

        # List sample frames
        sample_frames = video['frames'][:5]
        content += "Sample frames:\n"
        for frame in sample_frames:
            content += f"- `{Path(frame).name}`\n"

        if video['frame_count'] > 5:
            content += f"- ... and {video['frame_count'] - 5} more frames\n"

        content += "\n"

    content += """
---

## 🔍 How to Use This Knowledge Base

### Manual Frame Analysis

To analyze individual frames with Claude:

1. Navigate to a frame directory
2. Open frames in sequence
3. Document key concepts, code snippets, and UI elements
4. Build your understanding progressively

### Memvid Search (If Available)

If memvid is installed and configured:

```bash
# Search for specific topics
memvid search "authentication setup" nocodebackend-tutorials

# Search for UI components
memvid search "database schema" nocodebackend-tutorials

# Search for code patterns
memvid search "API endpoints" nocodebackend-tutorials
```

### Building Projects

Use the extracted frames as reference to:

1. **Understand Architecture** - See how NoCodeBackend projects are structured
2. **Learn Patterns** - Identify common design patterns and best practices
3. **Copy Configurations** - Reference setup and configuration steps
4. **Debug Issues** - Compare your implementation with tutorial examples

---

## 📊 Learning Recommendations

### For Beginners

1. Start with the first video in the series
2. Go through frames sequentially
3. Take notes on key concepts
4. Try to implement concepts in a test project

### For Intermediate Learners

1. Focus on specific topics of interest
2. Compare different implementation approaches
3. Extract reusable code patterns
4. Build reference implementations

### For Advanced Users

1. Study architecture decisions
2. Analyze optimization techniques
3. Document best practices
4. Create templates and starter kits

---

## 🛠️ Tools & Resources

- **Frame Extraction:** FFmpeg
- **Video Source:** YouTube (NoCodeBackend tutorials)
- **Analysis Tools:** Claude Code, Python scripts
- **Knowledge Base:** Memvid (optional)

---

## 📝 Notes

This is a living document. As you analyze frames and learn from the tutorials, consider:

1. Adding your own notes and insights
2. Creating code snippets from visible examples
3. Building a personal reference library
4. Sharing learnings with others

---

**Next Steps:**

1. Review frame inventory
2. Start with first tutorial series
3. Document key learnings
4. Build reference projects
"""

    doc_path.parent.mkdir(parents=True, exist_ok=True)
    doc_path.write_text(content)

    return doc_path


def build_memvid_knowledge_base(index_data):
    """Build a memvid knowledge base if memvid is available"""

    # Check if memvid is available
    try:
        result = subprocess.run(
            ["which", "memvid"],
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            log("Memvid not found. Skipping memvid knowledge base creation.", "WARNING")
            log("Install memvid from: https://github.com/mem0ai/memvid", "INFO")
            return False
    except Exception as e:
        log(f"Could not check for memvid: {e}", "WARNING")
        return False

    log("Building memvid knowledge base...", "INFO")

    # Create a temporary markdown file with all frame paths and metadata
    temp_doc = KNOWLEDGE_BASE_DIR / "temp_memvid_input.md"
    content = f"# NoCodeBackend Tutorials\n\n"

    for video in index_data['videos']:
        content += f"## {video['name']}\n\n"
        for frame_path in video['frames']:
            content += f"- Frame: {frame_path}\n"

    temp_doc.write_text(content)

    try:
        # Create memvid knowledge base
        cmd = [
            "memvid",
            "create",
            KNOWLEDGE_BASE_NAME,
            str(temp_doc)
        ]

        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            log("Memvid knowledge base created successfully!", "SUCCESS")
            return True
        else:
            log(f"Failed to create memvid knowledge base: {result.stderr}", "ERROR")
            return False

    except Exception as e:
        log(f"Error creating memvid knowledge base: {e}", "ERROR")
        return False


def main():
    """Main execution"""
    log("=" * 50)
    log("NoCodeBackend Knowledge Base Builder")
    log("=" * 50)

    # Find all frame directories
    log("Scanning for frame directories...")
    frame_dirs = find_all_frame_directories()

    if not frame_dirs:
        log("No frame directories found. Please run the video processing script first.", "ERROR")
        sys.exit(1)

    log(f"Found {len(frame_dirs)} video frame sets", "SUCCESS")
    for fd in frame_dirs:
        log(f"  - {fd['name']}: {fd['frame_count']} frames")

    # Create knowledge index
    log("\nCreating knowledge index...")
    index_data = create_knowledge_index(frame_dirs)

    # Save index as JSON
    index_path = KNOWLEDGE_BASE_DIR / "frame_index.json"
    index_path.parent.mkdir(parents=True, exist_ok=True)

    with open(index_path, 'w') as f:
        json.dump(index_data, f, indent=2)

    log(f"Index saved to: {index_path}", "SUCCESS")

    # Create markdown documentation
    log("\nGenerating learning guide...")
    doc_path = create_markdown_documentation(frame_dirs, index_data)
    log(f"Learning guide created: {doc_path}", "SUCCESS")

    # Try to build memvid knowledge base
    log("\nAttempting to build memvid knowledge base...")
    memvid_success = build_memvid_knowledge_base(index_data)

    # Final summary
    log("\n" + "=" * 50)
    log("KNOWLEDGE BASE BUILD COMPLETE", "SUCCESS")
    log("=" * 50)
    log(f"Total Videos: {index_data['total_videos']}")
    log(f"Total Frames: {index_data['total_frames']}")
    log(f"Index File: {index_path}")
    log(f"Learning Guide: {doc_path}")
    log(f"Memvid KB: {'Created' if memvid_success else 'Not Created'}")

    log("\n📖 Next Steps:")
    log("1. Open the learning guide to start exploring")
    log("2. Use Claude Code to analyze specific frames")
    log("3. Document your learnings as you progress")

    if memvid_success:
        log(f"\n🔍 Search the knowledge base:")
        log(f"   memvid search '<your query>' {KNOWLEDGE_BASE_NAME}")


if __name__ == "__main__":
    main()
