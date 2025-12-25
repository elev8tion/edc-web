# KB Tools - Portable Knowledge Base Toolkit

Create searchable knowledge bases from video tutorials in any project folder.

## 🚀 Quick Start

### Option 1: Copy to Your Project (Recommended - Easiest!)

```bash
# Copy the entire toolkit to your project
cp -r ~/Desktop/kb-tools ~/my-project/

cd ~/my-project
./kb-tools/kb init "MyTopic"
./kb-tools/kb add video-urls.txt
./kb-tools/kb build
```

This creates a self-contained project with its own KB tools.

### Option 2: Install Globally

```bash
cd ~/Desktop/kb-tools
chmod +x install.sh
./install.sh --global
```

Then from any directory:
```bash
kb init "MyTopic"
kb add video-urls.txt
kb build
```

### Option 3: Install to Specific Project

```bash
cd ~/Desktop/kb-tools
./install.sh --project ~/my-awesome-project
```

Then from that project:
```bash
cd ~/my-awesome-project
./kb init "MyTopic"
./kb add urls.txt
./kb build
```

## 📖 Usage

### Initialize a Knowledge Base

```bash
cd ~/my-project
kb init "ReactTutorials"
```

Creates:
```
my-project/
├── .kb-config.json    # KB configuration
├── kb-data/           # Knowledge base storage
├── kb-frames/         # Extracted frames
└── kb-downloads/      # Temporary downloads
```

### Add Videos

Create a file with YouTube URLs (one per line):

**urls.txt:**
```
https://www.youtube.com/watch?v=abc123
https://www.youtube.com/watch?v=def456
https://www.youtube.com/watch?v=ghi789
```

Then add them:
```bash
kb add urls.txt
```

This will:
- Download each video
- Extract ~75 frames per video
- Delete video after extraction
- Save frames to `kb-frames/`

### Build Knowledge Base

```bash
kb build
```

Creates searchable knowledge base organized by:
- Topics (authentication, database, api-design, etc.)
- Technologies
- Code snippets
- Searchable master index

### Query Knowledge Base

```bash
kb query "authentication"
kb query "database setup"
kb query "API endpoints"
```

### Check Status

```bash
kb status
```

Shows:
- Topic name
- Number of videos
- Number of frames
- Available topics
- Last build date

### Clean Up

```bash
kb clean
```

Removes temporary files but keeps:
- Knowledge base data
- Extracted frames
- Configuration

### Export

```bash
kb export json        # Export as JSON
kb export markdown    # Export as Markdown
```

## 🎯 Complete Workflow Example

```bash
# 1. Copy KB tools to your project
cp -r ~/Desktop/kb-tools ~/my-react-project/

# 2. Navigate to your project
cd ~/my-react-project

# 3. Initialize KB
./kb-tools/kb init "ReactPatterns"

# 4. Create URLs file
cat > react-urls.txt << 'EOF'
https://www.youtube.com/watch?v=video1
https://www.youtube.com/watch?v=video2
https://www.youtube.com/watch?v=video3
EOF

# 5. Add videos and build
./kb-tools/kb add react-urls.txt
./kb-tools/kb build

# 6. Query it
./kb-tools/kb query "hooks"
./kb-tools/kb query "state management"

# 7. Use with Claude
# "Using the ReactPatterns knowledge base, help me with useEffect"
```

## 🤖 Using with Claude

Once built, Claude can search your knowledge base when you ask:

```
"Using the ReactPatterns knowledge base, show me examples of custom hooks"

"From my KB, find authentication patterns"

"Search the knowledge base for API integration examples"
```

Claude will:
- Search the topic directories
- Find relevant frames
- Extract patterns and code
- Provide tutorial-based answers

## 📁 Project Structure After Build

```
your-project/
├── .kb-config.json              # Configuration
├── kb-data/                     # Knowledge base (keep in git)
│   ├── metadata.json
│   ├── SEARCH_GUIDE.md
│   ├── topics/
│   │   ├── authentication/
│   │   ├── database/
│   │   └── ...
│   ├── search-index/
│   │   └── master_index.json
│   └── code-snippets/
├── kb-frames/                   # Frames (gitignore)
│   └── ReactPatterns/
│       ├── video-1/
│       ├── video-2/
│       └── ...
└── kb-tools/                    # Toolkit (optional, can gitignore)
    ├── kb
    └── ...
```

## 🔧 Configuration

Edit `.kb-config.json` to customize:

```json
{
  "topic": "ReactPatterns",
  "created_at": "2025-12-25T...",
  "project_root": "/Users/you/project",
  "kb_data": "./kb-data",
  "kb_frames": "./kb-frames",
  "total_videos": 10,
  "total_frames": 750
}
```

## 💡 Tips

### Git Integration

Add to `.gitignore`:
```gitignore
# KB Tools
kb-downloads/
kb-frames/
kb-tools/

# Keep the knowledge base
!kb-data/
```

### Multiple Knowledge Bases

You can have multiple KBs per project:
```bash
kb init "Frontend"
# ... add/build

kb init "Backend"
# ... add/build
```

Each gets its own directory structure.

### Sharing Knowledge Bases

Share just the `kb-data/` directory:
```bash
tar -czf react-kb.tar.gz kb-data/
# Share react-kb.tar.gz

# Recipient:
tar -xzf react-kb.tar.gz
# Now they can query it!
```

## 🔍 Advanced Queries

### Search by Topic
```bash
cd kb-data/topics
ls                          # See available topics
grep -r "pattern" .         # Search across topics
```

### Find Specific Frames
```bash
find kb-frames -name "frame_0050.png"
```

### Query JSON Index
```bash
jq '.videos[] | {name, frame_count}' kb-data/search-index/master_index.json
```

## 📚 Examples

### React Hooks Tutorial KB
```bash
kb init "ReactHooks"
kb add hooks-urls.txt
kb build
kb query "useState"
```

### Node.js API Course KB
```bash
kb init "NodeAPI"
kb add api-urls.txt
kb build
kb query "express routes"
```

### Full-Stack Project KB
```bash
kb init "FullStackCourse"
kb add fullstack-urls.txt
kb build
kb query "database schema"
```

## 🆘 Troubleshooting

### "KB not initialized"
Run `kb init <topic>` first

### "No frames found"
Run `kb add <urls-file>` before `kb build`

### Downloads fail
Check internet connection and video URLs

### Low disk space
KB automatically deletes videos after extraction

## 📖 Commands Reference

| Command | Description |
|---------|-------------|
| `kb init <topic>` | Initialize KB in current project |
| `kb add <urls-file>` | Download and process videos |
| `kb build` | Build searchable knowledge base |
| `kb query <term>` | Search the KB |
| `kb status` | Show KB information |
| `kb clean` | Remove temporary files |
| `kb export <format>` | Export KB (json/markdown) |
| `kb help` | Show help |

## 🎓 Best Practices

1. **One KB per major topic** - Don't mix unrelated topics
2. **Quality over quantity** - 10-20 good videos better than 100 random ones
3. **Organize URLs** - Group related videos together
4. **Build incrementally** - Add videos in batches, build, test
5. **Document** - Add notes to topics as you learn
6. **Share** - Export and share KBs with team

## 🚀 Next Steps

1. Install the toolkit (globally or per-project)
2. Initialize a KB for your current learning topic
3. Add tutorial videos
4. Build the knowledge base
5. Start asking Claude questions using the KB!

---

**Created:** 2025-12-25
**Version:** 1.0
**Location:** ~/Desktop/kb-tools (portable - copy to any project)
