# NoCodeBackend Knowledge Base Search Guide

## Quick Start

This knowledge base can be searched in multiple ways:

### 1. Browse by Topic

```bash
cd /Users/kcdacre8tor/knowledge-bases/NoCodeBackend/topics
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
cd /Users/kcdacre8tor/knowledge-bases/NoCodeBackend/technologies
ls
```

### 3. Search Code Snippets

```bash
cd /Users/kcdacre8tor/knowledge-bases/NoCodeBackend/code-snippets
find . -name "*.js" -o -name "*.py" -o -name "*.json"
```

### 4. Query with JSON Index

```python
import json

with open("/Users/kcdacre8tor/knowledge-bases/NoCodeBackend/search-index/master_index.json") as f:
    index = json.load(f)

# Search for frames
for video in index["videos"]:
    print(f"{video['name']}: {video['frame_count']} frames")
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
find /Users/kcdacre8tor/knowledge-bases/NoCodeBackend -name "frame_0045.png"
```

### Search Topics
```bash
grep -r "authentication" /Users/kcdacre8tor/knowledge-bases/NoCodeBackend/topics
```

### List All Code Files
```bash
find /Users/kcdacre8tor/knowledge-bases/NoCodeBackend/code-snippets -type f
```

---

**Last Updated:** 2025-12-25 03:16:34
