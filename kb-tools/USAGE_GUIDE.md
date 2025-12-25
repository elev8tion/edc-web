# NoCodeBackend Knowledge Base - Usage Guide

## Knowledge Base Summary

**Topic:** NoCodeBackend
**Videos Processed:** 16
**Total Frames:** 1,245
**Last Built:** 2025-12-25

### Available Topics

The knowledge base is organized into 7 main topics:

1. **Authentication** - User authentication, login, sessions
2. **Database** - Database setup, schemas, queries
3. **API Design** - REST APIs, endpoints, routing
4. **Frontend** - UI components, forms, interfaces
5. **Deployment** - Hosting, deployment, production
6. **Testing** - Unit tests, integration tests
7. **Configuration** - Project setup, environment config

---

## How to Use the Knowledge Base

### Option 1: Use with Claude Code

You can ask Claude to search the knowledge base directly:

```
"Using the NoCodeBackend knowledge base, show me how to set up authentication"

"From my KB, find examples of database schemas"

"Search the knowledge base for API endpoint patterns"

"What does the knowledge base say about deployment?"
```

Claude can:
- Navigate the topic directories
- View relevant frames
- Extract patterns and code examples
- Provide tutorial-based answers

### Option 2: Use the CLI Tool

```bash
# Check knowledge base status
./kb status

# Search for specific topics
./kb query "authentication"
./kb query "database"
./kb query "API endpoints"

# Export the knowledge base
./kb export json
./kb export markdown
```

### Option 3: Manual Exploration

#### Browse by Topic
```bash
cd kb-data/topics
ls -la

# View a specific topic
cd authentication
cat concepts/overview.md
```

#### Search the Master Index
```bash
# View all videos and frame counts
jq '.videos[] | {name: .name, frames: .frame_count}' kb-data/search-index/master_index.json

# Find specific video
jq '.videos[] | select(.name | contains("14"))' kb-data/search-index/master_index.json
```

#### View Frames
```bash
# List all frames for a video
ls kb-frames/NoCodeBackend/1766644945-NoCodeBackend-1-dBRBeQASq28/

# View a specific frame (with an image viewer)
open kb-frames/NoCodeBackend/1766644945-NoCodeBackend-1-dBRBeQASq28/frame_0001.png
```

---

## Example Queries for Claude

Here are some effective ways to query the knowledge base with Claude:

### General Questions
```
"Give me an overview of what's covered in the NoCodeBackend tutorials"

"What topics are most heavily covered in the knowledge base?"

"Show me the structure of the NoCodeBackend knowledge base"
```

### Topic-Specific Questions
```
"Using the authentication topic, explain the login flow"

"From the database topic, show me schema examples"

"What API design patterns are shown in the frontend topic?"

"How is deployment configured according to the KB?"
```

### Frame Analysis
```
"Show me frames 10-20 from video 1"

"Analyze frame_0045 from the first NoCodeBackend video"

"What's shown in the frames for authentication topic?"
```

### Code Extraction
```
"Extract all code snippets related to database queries"

"Find API endpoint examples in the knowledge base"

"Show me configuration file examples"
```

### Learning Path
```
"Create a learning path based on the NoCodeBackend tutorials"

"What should I learn first from this knowledge base?"

"Explain the progression from video 1 to video 16"
```

---

## Knowledge Base Structure

```
kb-tools/
├── .kb-config.json              # Configuration
├── kb-data/                     # Knowledge base (searchable)
│   ├── metadata.json            # KB metadata
│   ├── SEARCH_GUIDE.md          # Search instructions
│   ├── topics/                  # Organized by topic
│   │   ├── authentication/
│   │   │   ├── concepts/
│   │   │   ├── code-examples/
│   │   │   ├── frames/
│   │   │   └── metadata.json
│   │   ├── database/
│   │   ├── api-design/
│   │   ├── frontend/
│   │   ├── deployment/
│   │   ├── testing/
│   │   └── configuration/
│   ├── search-index/
│   │   └── master_index.json   # Master video/frame index
│   ├── code-snippets/          # Extracted code
│   └── technologies/           # Tech stack info
├── kb-frames/                   # Video frames (1245 images)
│   └── NoCodeBackend/
│       ├── 1766644945-NoCodeBackend-1-dBRBeQASq28/
│       ├── 1766644957-NoCodeBackend-2-t2Zps53hn9U/
│       ├── ... (16 video directories)
│       └── 1766645219-NoCodeBackend-17-ujSjXS-DG-E/
└── USAGE_GUIDE.md              # This file
```

---

## Video List

The knowledge base contains frames from these 16 videos:

1. `1766644945-NoCodeBackend-1-dBRBeQASq28` - 62 frames
2. `1766644957-NoCodeBackend-2-t2Zps53hn9U` - 80 frames
3. `1766644969-NoCodeBackend-3-HqoeT0u7TAU` - 78 frames
4. `1766644980-NoCodeBackend-4-X5WZUNlqDHk` - 75 frames
5. `1766644997-NoCodeBackend-5-6Iv6VjuE5kI` - 76 frames
6. `1766645013-NoCodeBackend-6-D6cIXOBOrgM` - 75 frames
7. `1766645072-NoCodeBackend-7-TNsytblvPF0` - 78 frames
8. `1766645092-NoCodeBackend-8-XsLeqKCuc8s` - 79 frames
9. `1766645113-NoCodeBackend-10-0kcjQYwc2g0` - 76 frames
10. `1766645131-NoCodeBackend-11-uIKqAZjLYJI` - 79 frames
11. `1766645149-NoCodeBackend-12-fWawXeA_-w0` - 76 frames
12. `1766645168-NoCodeBackend-13-MKQvkNz6DQk` - 76 frames
13. `1766645187-NoCodeBackend-14-dKv3K797M30` - 82 frames
14. `1766645200-NoCodeBackend-15-9lTCB87pHVw` - 99 frames
15. `1766645209-NoCodeBackend-16-Kyji73kykm4` - 78 frames
16. `1766645219-NoCodeBackend-17-ujSjXS-DG-E` - 76 frames

**Total:** 1,245 frames across 16 videos

---

## Advanced Usage

### Python Script Access

```python
import json
from pathlib import Path

# Load the master index
with open('kb-data/search-index/master_index.json') as f:
    kb = json.load(f)

# Find all videos
for video in kb['videos']:
    print(f"{video['name']}: {video['frame_count']} frames")

# Search for specific video
target = "NoCodeBackend-1"
for video in kb['videos']:
    if target in video['name']:
        print(f"Found: {video['name']}")
        print(f"Frames: {len(video['frames'])}")
```

### Bash Queries

```bash
# Count total frames
find kb-frames/NoCodeBackend -name "*.png" | wc -l

# Find frames containing specific numbers
find kb-frames -name "frame_00[1-5]*.png"

# Search topic documentation
grep -r "authentication" kb-data/topics/

# List all video directories
ls -1 kb-frames/NoCodeBackend/
```

### jq Queries

```bash
# Get video names only
jq -r '.videos[].name' kb-data/search-index/master_index.json

# Find videos with most frames
jq '.videos | sort_by(.frame_count) | reverse | .[0:3]' kb-data/search-index/master_index.json

# Count topics
jq '.topics | length' kb-data/metadata.json
```

---

## Tips for Best Results

### When Working with Claude

1. **Be specific**: Instead of "tell me about authentication", try "show me the authentication flow in frames 20-30 of video 1"

2. **Reference topics**: "Using the database topic in my KB, explain schema design"

3. **Request frame analysis**: "Analyze frame_0050.png from video 14 and extract the code shown"

4. **Progressive learning**: "Start with video 1 and explain what's being taught step by step"

### Searching Effectively

1. **Use topic structure**: Navigate to specific topics first
2. **Check master index**: Find which videos cover your topic
3. **Sample frames**: Look at every 10th frame for overview
4. **Deep dive**: Examine sequential frames for detailed learning

### Maintaining the KB

```bash
# Check KB status regularly
./kb status

# Clean up if needed
./kb clean

# Export for backup
./kb export json > nocodebackend_backup.json
```

---

## Troubleshooting

### "No results found"
- Check if topic exists: `ls kb-data/topics/`
- Verify frames exist: `ls kb-frames/NoCodeBackend/`
- Review master index: `jq . kb-data/search-index/master_index.json`

### "Frame not found"
- List available frames: `find kb-frames -name "*.png" | head`
- Check video directory exists
- Verify frame numbering (frame_0001.png, not frame_1.png)

### "KB not initialized"
- Verify `.kb-config.json` exists
- Check `kb-data/` directory exists
- Re-run `./kb build` if needed

---

## Next Steps

1. **Explore with Claude**: Ask Claude to give you an overview of the knowledge base
2. **Browse topics**: Navigate through the 7 topic directories
3. **View frames**: Open some frames to see what's captured
4. **Query**: Try the example queries above
5. **Build projects**: Use the KB as a reference while coding

---

**Knowledge Base Version:** 2.0
**Last Updated:** 2025-12-25
**Project:** kb-tools @ ~/Desktop/kb-tools
