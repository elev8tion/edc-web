# SQLite MCP Server Setup

This setup allows you to interact with the `everyday_christian.db` SQLite database during development using Claude Code's MCP (Model Context Protocol) integration.

## What It Does

- **Query the database** without stopping your Flutter app
- **Inspect tables and schemas** in real-time
- **Test SQL queries** before adding to Dart code
- **Add/modify test data** on the fly
- **Verify migrations** after database changes

## Setup Instructions

### 1. Make sure the app is running

The database must exist before connecting:
```bash
flutter run
```

### 2. Configure Claude Code

Add this to your Claude Code MCP configuration:

**Using Claude Code UI:**
1. Open Command Palette (Cmd+Shift+P)
2. Type "MCP: Configure Servers"
3. Add a new server with these settings:
   - **Name**: `everyday-christian-db`
   - **Command**: `bash`
   - **Args**: `["./scripts/connect-db.sh"]`
   - **Working Directory**: `/Users/kcdacre8tor/ everyday-christian`

**Or manually edit `~/.claude.json`:**
```json
{
  "projects": {
    "/Users/kcdacre8tor/ everyday-christian": {
      "mcpServers": {
        "everyday-christian-db": {
          "command": "bash",
          "args": ["./scripts/connect-db.sh"]
        }
      }
    }
  }
}
```

### 3. Restart Claude Code

After adding the configuration, restart Claude Code to load the MCP server.

## Available Tools

Once connected, you can ask Claude Code to:

### Database Information
```
"Show me database info"
"List all tables"
"Show schema for bible_verses table"
```

### Query Data
```
"How many verses are in the database?"
"Show me 5 random verses"
"Find all verses with the theme 'hope'"
```

### CRUD Operations
```
"Add a test verse to bible_verses"
"Update verse with id 123"
"Delete test data"
```

### Custom SQL
```
"Run this SQL: SELECT COUNT(*) FROM bible_verses WHERE version='WEB'"
"Show me the first 10 verses from Psalms"
```

## Example Queries

### Check migration success
```
List all tables
→ Should show bible_verses (not verses)

Show schema for bible_verses
→ Should show: version, book, chapter, verse, text, language

Count verses in bible_verses
→ Should return 31,103
```

### Verify data
```
Show 5 verses from John chapter 3
→ SELECT * FROM bible_verses WHERE book='John' AND chapter=3 LIMIT 5

Check which translations we have
→ SELECT DISTINCT version FROM bible_verses
```

## Troubleshooting

**"Database not found" error:**
- Make sure the Flutter app has been run at least once
- The database is created on first launch
- Try: `flutter run` then retry

**MCP server not showing in Claude Code:**
- Restart Claude Code after configuration
- Check the script is executable: `ls -l scripts/connect-db.sh`
- Should show: `-rwxr-xr-x` (x means executable)

**Wrong database path:**
- The script automatically finds the most recent database
- If you have multiple simulators, it uses the most recently modified one
- Check manually: `find ~/Library/Developer/CoreSimulator/Devices -name "everyday_christian.db"`

## Technical Details

- **Database Location**: iOS Simulator's Documents directory
- **Auto-detection**: Script finds the most recently modified database
- **MCP Server**: Uses `mcp-sqlite` npm package
- **Connection**: Direct SQLite connection via Node.js

## Need Help?

The script output shows:
- Database path found
- Database size
- Any connection errors

Check the script output in Claude Code's MCP logs if issues occur.
