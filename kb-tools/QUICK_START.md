# KB Tools - Quick Start Guide

## Copy-Paste Workflow (Recommended)

### 1. Copy Toolkit to Your Project

```bash
cp -r ~/Desktop/kb-tools ~/your-project-name/
```

**What this does:** Copies the entire KB toolkit into your project folder.

### 2. Navigate to Your Project

```bash
cd ~/your-project-name
```

### 3. Create a Links File

Create a text file with YouTube URLs (one per line):

```bash
cat > tutorial-links.txt << 'EOF'
https://www.youtube.com/watch?v=VIDEO_ID_1
https://www.youtube.com/watch?v=VIDEO_ID_2
https://www.youtube.com/watch?v=VIDEO_ID_3
EOF
```

Or just create `tutorial-links.txt` in any text editor with your URLs.

### 4. Initialize Knowledge Base

```bash
./kb-tools/kb init "MyTopicName"
```

**What this does:** Sets up the KB structure in your project.

### 5. Add Videos and Build

```bash
./kb-tools/kb add tutorial-links.txt
./kb-tools/kb build
```

**What happens:**
- Downloads each video
- Extracts ~75 frames per video
- Deletes video after extraction (saves space)
- Organizes frames by topic
- Creates searchable knowledge base

**Time:** ~5-10 minutes for 10-15 videos

### 6. Check Status

```bash
./kb-tools/kb status
```

Shows:
- Number of videos processed
- Number of frames extracted
- Available topics
- KB location

### 7. Query Your Knowledge Base

```bash
./kb-tools/kb query "search term"
```

Or better yet, **ask Claude**:

```
"Using the MyTopicName knowledge base in my current project,
 help me understand [concept]"

"From my KB, show me examples of [feature]"

"Search my knowledge base for [pattern/code/technique]"
```

## Real-World Example

```bash
# Learn React Hooks
mkdir ~/learn-react-hooks
cp -r ~/Desktop/kb-tools ~/learn-react-hooks/
cd ~/learn-react-hooks

# Create links file
cat > hooks-videos.txt << 'EOF'
https://www.youtube.com/watch?v=TNhaISOUy6Q
https://www.youtube.com/watch?v=dpw9EHDh2bM
https://www.youtube.com/watch?v=O6P86uwfdR0
EOF

# Build the KB
./kb-tools/kb init "ReactHooks"
./kb-tools/kb add hooks-videos.txt
./kb-tools/kb build

# Ask Claude
# "Using the ReactHooks knowledge base, explain useState"
```

## What Gets Created

```
your-project/
├── kb-tools/              # The toolkit (can be gitignored)
│   ├── kb                 # Main CLI
│   ├── install.sh
│   ├── *.py              # Python tools
│   └── README.md
├── kb-data/              # Knowledge base (commit to git!)
│   ├── topics/           # Organized by topic
│   ├── search-index/     # Searchable index
│   └── metadata.json
├── kb-frames/            # Extracted frames (gitignore)
│   └── MyTopicName/
│       ├── video-1/
│       ├── video-2/
│       └── ...
└── tutorial-links.txt    # Your video URLs
```

## Useful Commands

| Command | What It Does |
|---------|--------------|
| `./kb-tools/kb init "Topic"` | Start new KB |
| `./kb-tools/kb add file.txt` | Download & process videos |
| `./kb-tools/kb build` | Create searchable KB |
| `./kb-tools/kb query "term"` | Search KB |
| `./kb-tools/kb status` | Show KB info |
| `./kb-tools/kb clean` | Remove temp files |
| `./kb-tools/kb help` | Show all commands |

## .gitignore Setup

Add to your `.gitignore`:

```gitignore
# KB Tools
kb-downloads/
kb-frames/
kb-tools/

# Keep the knowledge base
!kb-data/
```

## Sharing Your Knowledge Base

```bash
# Export just the knowledge base
tar -czf MyTopic-KB.tar.gz kb-data/

# Share MyTopic-KB.tar.gz with your team
# They extract and can query immediately!
```

## Tips

1. **Quality over quantity** - 10-20 good tutorials > 100 random videos
2. **One topic per KB** - Keep focused (React Hooks, not "All of React")
3. **Build incrementally** - Add 5-10 videos, build, test, repeat
4. **Use with Claude** - Ask specific questions referencing the KB
5. **Commit kb-data/** - Share knowledge with your team via git

## Troubleshooting

**"KB not initialized"**
→ Run `./kb-tools/kb init "TopicName"` first

**"No frames found"**
→ Run `./kb-tools/kb add urls-file.txt` before building

**Downloads fail**
→ Check internet connection and verify YouTube URLs are valid

**Out of disk space**
→ KB auto-deletes videos after extracting frames (very space efficient!)

## Next Steps

1. Pick a topic you want to learn
2. Find 10-15 quality video tutorials
3. Copy kb-tools to a new project folder
4. Follow steps 1-7 above
5. Start asking Claude questions using your new knowledge base!

---

**Location:** `~/Desktop/kb-tools/`
**Full Docs:** See `README.md`
**Version:** 1.0
