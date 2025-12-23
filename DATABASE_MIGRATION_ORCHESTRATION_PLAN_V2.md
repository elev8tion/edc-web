# Database Migration Orchestration Plan V2
## Context-Aware Multi-Agent Strategy: sqflite → sql.js

**Project:** Everyday Christian PWA Database Migration
**Date:** December 15, 2025
**Orchestration Model:** Atomic Task Decomposition with Coordinator Integration
**Revised Timeline:** 4-5 days with tighter coordinator involvement
**Key Change:** Tasks sized for single sub-agent execution within context limits

---

## Critical Revision: Sub-Agent Context Constraints

### Why V1 Won't Work

**Sub-Agent Limitations Identified:**
1. ❌ **No iteration capability** - One prompt, one execution, one result
2. ❌ **Limited context window** - Can't hold entire codebase in memory
3. ❌ **No clarification requests** - Must work with info provided
4. ❌ **No incremental fixes** - Can't iterate on failing tests
5. ❌ **Tool access varies** - May not have all tools available

**V1 Problems:**
- Agent 1 task too large (300-line file from scratch)
- Agent 3 too broad (11 services, unknown issues)
- Agent 4 assumes ability to fix failures (can't iterate)
- Insufficient context provided in prompts
- Dependencies between agents too tight

---

## Revised Strategy: Coordinator-Centric Model

### New Execution Model

```
┌────────────────────────────────────────────────────────────┐
│                   COORDINATOR (You/Claude)                  │
│                                                              │
│  Responsibilities:                                          │
│  ✓ Break work into atomic tasks (<2h per task)             │
│  ✓ Launch sub-agents with complete context                 │
│  ✓ Integrate results and handle failures                   │
│  ✓ Iterate on issues discovered                            │
│  ✓ Make decisions and resolve ambiguities                  │
│  ✓ Run tests and fix integration issues                    │
│  ✓ Maintain overall progress                               │
└──────────────────────┬─────────────────────────────────────┘
                       │
                       │ Launch atomic tasks only
                       ↓
            ┌──────────────────────┐
            │   SUB-AGENTS          │
            │   (Task Tool)         │
            │                       │
            │  ✓ Single, clear task │
            │  ✓ All context given  │
            │  ✓ Return results     │
            │  ✓ No iteration       │
            └──────────────────────┘
```

**Key Principle:** Sub-agents do research and code generation; Coordinator does integration, testing, and iteration.

---

## Atomic Task Breakdown

### Phase 1: Research & Analysis (Day 1)

#### Task 1.1: Database Schema Documentation
**Sub-Agent:** Explore agent
**Duration:** 1-2 hours
**Context Required:** database_helper.dart only
**Deliverable:** Complete schema documentation (tables, indexes, FKs)

**Prompt:**
```
Analyze lib/core/database/database_helper.dart and document:
1. All 23 table schemas (CREATE TABLE statements)
2. All indexes (CREATE INDEX statements)
3. All foreign keys
4. All triggers
5. Migration history (v1-v20)

Output format: Structured markdown with:
- Table name
- Columns (name, type, constraints)
- Indexes
- Foreign keys
- Related tables

Do NOT make any changes, only document.
```

**Coordinator Action After:**
- Review documentation
- Validate against codebase
- Use as reference for all future tasks

---

#### Task 1.2: Service Layer Dependency Map
**Sub-Agent:** Explore agent
**Duration:** 1-2 hours
**Context Required:** All service files
**Deliverable:** Map of which services use which tables

**Prompt:**
```
Analyze all files in lib/core/services/ and lib/services/ and create a dependency map:

For each service:
1. Service name and file path
2. Tables it queries/inserts/updates/deletes
3. DatabaseHelper methods it calls
4. Any raw SQL queries
5. Transaction usage

Output format: JSON
{
  "services": [
    {
      "name": "PrayerService",
      "file": "lib/core/services/prayer_service.dart",
      "tables": ["prayer_requests", "prayer_categories"],
      "operations": {
        "prayer_requests": ["query", "insert", "update", "delete"],
        "prayer_categories": ["query"]
      },
      "raw_sql": false,
      "uses_transactions": true
    }
  ]
}

Do NOT make any changes, only analyze.
```

**Coordinator Action After:**
- Review dependency map
- Identify high-risk services
- Plan testing strategy

---

#### Task 1.3: Asset Database Analysis
**Sub-Agent:** Explore agent
**Duration:** 1 hour
**Context Required:** BibleLoaderService
**Deliverable:** Asset DB structure and loading process

**Prompt:**
```
Analyze lib/core/services/bible_loader_service.dart and document:

1. How asset databases are attached (ATTACH DATABASE statements)
2. What data is copied (INSERT statements)
3. Schema transformation (column mappings)
4. Book name translation logic (65-line CASE statement)
5. File paths and sizes

Output: Detailed process flow diagram in markdown.

Do NOT make any changes, only document.
```

**Coordinator Action After:**
- Understand asset DB structure
- Plan web equivalent approach

---

### Phase 2: Infrastructure Setup (Day 1-2)

#### Task 2.1: Create sql.js Wrapper Interface (Structure Only)
**Sub-Agent:** General-purpose agent
**Duration:** 1 hour
**Context Required:** sqflite API documentation + schema from Task 1.1
**Deliverable:** Stub file with method signatures

**Prompt:**
```
Create lib/core/database/sql_js_helper.dart with method signatures only (no implementation).

Requirements:
1. Match sqflite API exactly
2. Include these methods:
   - static Future<SqlJsDatabase> get database
   - Future<List<Map<String, dynamic>>> query(...)
   - Future<int> insert(...)
   - Future<int> update(...)
   - Future<int> delete(...)
   - Future<void> execute(...)
   - Future<void> transaction(...)

3. Add extensive dartdoc comments for each method
4. Add TODO markers for implementation

5. Include type definitions:
   - ConflictAlgorithm enum
   - Database class wrapper

Output: Complete file with stubs only.
```

**Coordinator Action After:**
- Review interface
- Add to codebase
- Use as contract for implementation

---

#### Task 2.2: Implement WASM Loader
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** sql.js documentation + stub from Task 2.1
**Deliverable:** Working WASM initialization code

**Prompt:**
```
Implement WASM loading in lib/core/database/sql_js_helper.dart.

Fill in these methods:
1. _initialize() - Load sql.js WASM module
2. _openDatabase() - Create/open database
3. Error handling for WASM load failures
4. Loading state management

Requirements:
- Use sql_js package (already in pubspec.yaml)
- Handle async initialization
- Add debug logging
- Return SqlJsDatabase instance

Reference the stub file created in Task 2.1.
Implement ONLY the initialization code, not CRUD methods.
```

**Coordinator Action After:**
- Test WASM loading works
- Verify error handling
- Fix any issues found

---

#### Task 2.3: Implement IndexedDB Persistence
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** IndexedDB API + sql.js export API
**Deliverable:** Save/restore functionality

**Prompt:**
```
Implement IndexedDB persistence in lib/core/database/sql_js_helper.dart.

Add these methods:
1. _saveToIndexedDB(SqlJsDatabase db) - Export and save
2. _loadFromIndexedDB() - Load and restore
3. Error handling for quota exceeded
4. Version management

Requirements:
- Use dart:html IndexedDB API
- Handle Uint8List serialization
- Add quota checks
- Graceful degradation if IndexedDB unavailable

Implement ONLY persistence, not CRUD methods.
```

**Coordinator Action After:**
- Test save/restore cycle
- Verify data integrity
- Handle quota errors

---

#### Task 2.4: Implement Query Method
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** sqflite query API + sql.js select API
**Deliverable:** Working query() method

**Prompt:**
```
Implement query() method in lib/core/database/sql_js_helper.dart.

Method signature (from Task 2.1):
Future<List<Map<String, dynamic>>> query(
  String table, {
  bool? distinct,
  List<String>? columns,
  String? where,
  List<Object?>? whereArgs,
  String? groupBy,
  String? having,
  String? orderBy,
  int? limit,
  int? offset,
})

Requirements:
1. Build SELECT statement from parameters
2. Handle all optional clauses (WHERE, GROUP BY, ORDER BY, LIMIT, OFFSET)
3. Use sql.js select() method
4. Convert results to List<Map<String, dynamic>>
5. Handle errors gracefully

Test with this query:
await db.query('bible_verses', where: 'book = ?', whereArgs: ['John'], limit: 10);
```

**Coordinator Action After:**
- Test query with actual data
- Verify result format matches sqflite
- Fix any edge cases

---

#### Task 2.5: Implement Insert/Update/Delete Methods
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** sqflite DML API + sql.js execute API
**Deliverable:** Working insert(), update(), delete() methods

**Prompt:**
```
Implement DML methods in lib/core/database/sql_js_helper.dart.

Methods to implement:
1. insert(String table, Map<String, Object?> values, {ConflictAlgorithm?})
2. update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs})
3. delete(String table, {String? where, List<Object?>? whereArgs})

Requirements:
- Build SQL statements from parameters
- Handle conflict algorithms (REPLACE, IGNORE, etc.)
- Return affected row count
- Handle errors

Test cases:
await db.insert('prayer_requests', {...});
await db.update('prayer_requests', {...}, where: 'id = ?', whereArgs: ['123']);
await db.delete('prayer_requests', where: 'id = ?', whereArgs: ['123']);
```

**Coordinator Action After:**
- Test insert/update/delete
- Verify return values
- Check constraint enforcement

---

### Phase 3: Data Migration (Day 2-3)

#### Task 3.1: Export Bible Database to SQL
**Sub-Agent:** General-purpose agent (with Bash access)
**Duration:** 1 hour
**Context Required:** Asset DB paths
**Deliverable:** SQL dump files

**Prompt:**
```
Export Bible databases to SQL dumps.

Tasks:
1. Run: sqlite3 assets/bible.db .dump > bible_en.sql
2. Run: sqlite3 assets/spanish_bible_rvr1909.db .dump > bible_es.sql
3. Analyze file sizes
4. Count INSERT statements
5. Identify CREATE TABLE statements

Output: Confirmation that files created + statistics.
```

**Coordinator Action After:**
- Review SQL files
- Verify completeness
- Plan optimization

---

#### Task 3.2: Optimize SQL Dumps
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** SQL dump files from Task 3.1
**Deliverable:** Optimized SQL files

**Prompt:**
```
Optimize bible_en.sql and bible_es.sql for web loading.

Tasks:
1. Remove comments (lines starting with --)
2. Remove unnecessary PRAGMA statements
3. Batch INSERT statements (combine into multi-value INSERTs)
4. Remove CREATE INDEX statements (will create later)
5. Keep only: CREATE TABLE, INSERT statements

Example optimization:
Before:
INSERT INTO verses VALUES (1, ...);
INSERT INTO verses VALUES (2, ...);

After:
INSERT INTO verses VALUES
(1, ...),
(2, ...);

Save optimized files as:
- web/assets/bible_data_en.sql
- web/assets/bible_data_es.sql

Report size reduction.
```

**Coordinator Action After:**
- Verify SQL syntax valid
- Test loading in sql.js
- Measure load time

---

#### Task 3.3: Create Bible Data Loader Service
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** Optimized SQL from Task 3.2
**Deliverable:** Web Bible loader service

**Prompt:**
```
Create lib/core/services/bible_loader_service_web.dart.

Requirements:
1. Load SQL file from assets (web/assets/bible_data_en.sql)
2. Execute SQL statements in batches (1000 statements at a time)
3. Show loading progress (0-100%)
4. Handle errors (rollback on failure)
5. Verify data loaded (count verses)

Methods needed:
- Future<void> loadEnglishBible({ProgressCallback? onProgress})
- Future<void> loadSpanishBible({ProgressCallback? onProgress})
- Future<bool> isBibleLoaded(String language)

Use sql.js execute() method for SQL execution.
Add extensive error logging.
```

**Coordinator Action After:**
- Test loading English Bible
- Test loading Spanish Bible
- Verify verse counts
- Measure performance

---

#### Task 3.4: Create FTS Index Setup
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** Schema from Task 1.1
**Deliverable:** FTS table creation and population

**Prompt:**
```
Create FTS index setup in lib/core/database/fts_setup_web.dart.

Tasks:
1. Create bible_verses_fts virtual table (use FTS4, not FTS5)
2. Create triggers for auto-sync (insert, update, delete)
3. Populate FTS table from bible_verses
4. Test search functionality

SQL needed:
CREATE VIRTUAL TABLE bible_verses_fts USING fts4(
  book, chapter, verse, text,
  content=bible_verses
);

CREATE TRIGGER bible_verses_ai AFTER INSERT ON bible_verses BEGIN
  INSERT INTO bible_verses_fts(rowid, book, chapter, verse, text)
  VALUES (new.rowid, new.book, new.chapter, new.verse, new.text);
END;

Add similar triggers for UPDATE and DELETE.

Test with:
SELECT * FROM bible_verses_fts WHERE bible_verses_fts MATCH 'love' LIMIT 10;
```

**Coordinator Action After:**
- Test FTS search
- Verify triggers work
- Check performance

---

### Phase 4: Service Layer Integration (Day 3-4)

#### Task 4.1: Update DatabaseHelper with Conditional Imports
**Sub-Agent:** General-purpose agent
**Duration:** 1 hour
**Context Required:** database_helper.dart + sql_js_helper.dart
**Deliverable:** Platform-aware DatabaseHelper

**Prompt:**
```
Update lib/core/database/database_helper.dart for web support.

Changes needed:
1. Add conditional import at top:
import 'package:sqflite/sqflite.dart' if (dart.library.html) 'sql_js_helper.dart';

2. Update _initDatabase() method (lines 52-84):
if (kIsWeb) {
  _database = await SqlJsHelper.database;
} else {
  _database = await openDatabase(...);
}

3. Change _database type from Database? to dynamic

4. Add import: import 'package:flutter/foundation.dart' show kIsWeb;

Make MINIMAL changes - only add platform check, don't modify logic.
```

**Coordinator Action After:**
- Test mobile still works
- Test web works
- Verify no breaking changes

---

#### Task 4.2: Test PrayerService on Web
**Sub-Agent:** Explore agent
**Duration:** 1 hour
**Context Required:** PrayerService + sql_js_helper
**Deliverable:** Test report

**Prompt:**
```
Test lib/core/services/prayer_service.dart on web platform.

Test Cases:
1. getActivePrayers() - Verify returns empty list initially
2. addPrayer() - Insert test prayer, verify success
3. getActivePrayers() - Verify returns 1 prayer
4. updatePrayer() - Update prayer, verify changed
5. markPrayerAnswered() - Mark answered, verify status
6. getAnsweredPrayers() - Verify returns 1 answered prayer
7. deletePrayer() - Delete prayer, verify removed

For each test:
- Run operation
- Check result
- Verify database state

Output: Pass/fail for each test + error messages if any.
```

**Coordinator Action After:**
- Review test results
- Fix any failures
- Repeat for other services

---

#### Task 4.3: Test UnifiedVerseService on Web
**Sub-Agent:** Explore agent
**Duration:** 2 hours
**Context Required:** UnifiedVerseService + Bible data loaded
**Deliverable:** Test report

**Prompt:**
```
Test lib/services/unified_verse_service.dart on web platform.

Prerequisites: English Bible must be loaded (31,000 verses).

Test Cases:
1. searchVerses('love') - Should return results
2. searchVerses('John 3:16') - Should find specific verse
3. getVerseByReference('John 3:16') - Should return exact verse
4. addToFavorites() - Add verse to favorites
5. getFavoriteVerses() - Should return 1 favorite
6. searchByTheme('hope') - Should return themed verses
7. recordSharedVerse() - Record share
8. getSharedVerses() - Should return 1 shared verse

For each test:
- Expected result
- Actual result
- Pass/fail
- Error details if failed

Output: Detailed test report.
```

**Coordinator Action After:**
- Review results
- Fix FTS issues if any
- Verify performance acceptable

---

#### Task 4.4-4.13: Test Remaining Services
**Pattern:** Same as Tasks 4.2-4.3, but for:
- CategoryService
- ReadingPlanService
- DevotionalService
- ConversationService
- AchievementService
- BibleChapterService
- PrayerStreakService
- DevotionalProgressService
- ReadingPlanProgressService

**Coordinator Role:**
- Launch each test task sequentially
- Review results
- Fix issues between tasks
- Build confidence incrementally

---

### Phase 5: Optimization & Polish (Day 4-5)

#### Task 5.1: Performance Profiling
**Sub-Agent:** Explore agent
**Duration:** 2 hours
**Context Required:** Complete web app
**Deliverable:** Performance report

**Prompt:**
```
Profile database performance on web.

Measurements needed:
1. Database initialization time (from page load to ready)
2. Bible data load time (31,000 verses)
3. Query performance (100 random queries, average time)
4. FTS search performance (10 searches, average time)
5. Insert performance (100 inserts, average time)
6. IndexedDB save time
7. Total memory usage

Tools:
- Stopwatch for timing
- window.performance API
- Chrome DevTools Memory profiler

Output: Markdown report with:
- Each metric measured
- Comparison to targets
- Bottlenecks identified
- Recommendations
```

**Coordinator Action After:**
- Review performance
- Optimize bottlenecks
- Re-test after changes

---

#### Task 5.2: Cross-Browser Testing
**Sub-Agent:** Explore agent
**Duration:** 3 hours
**Context Required:** Built web app
**Deliverable:** Browser compatibility matrix

**Prompt:**
```
Test web app in multiple browsers.

Browsers to test:
1. Chrome/Edge (Chromium)
2. Firefox
3. Safari (macOS/iOS)

For each browser, test:
1. WASM loads successfully
2. IndexedDB works
3. Database initializes
4. Bible data loads
5. Search works (FTS)
6. CRUD operations work
7. No console errors

Create matrix:
| Feature | Chrome | Firefox | Safari |
|---------|--------|---------|--------|
| WASM    | ✅     | ?       | ?      |
| IndexedDB| ✅    | ?       | ?      |
| ...

Report any browser-specific issues found.
```

**Coordinator Action After:**
- Review compatibility
- Add polyfills if needed
- Document limitations

---

#### Task 5.3: Error Handling Audit
**Sub-Agent:** Explore agent
**Duration:** 2 hours
**Context Required:** All database code
**Deliverable:** Error handling report

**Prompt:**
```
Audit error handling in database layer.

Check:
1. sql_js_helper.dart - All methods have try/catch?
2. Bible loader - Handles load failures gracefully?
3. Services - Handle database errors?
4. IndexedDB - Handles quota exceeded?
5. WASM - Handles load failures?

For each error scenario:
- Is it caught?
- Is it logged?
- Is user notified?
- Does app continue working?

Test error scenarios:
1. WASM fails to load
2. IndexedDB quota exceeded
3. Malformed SQL in Bible data
4. Network failure during asset load
5. Database locked/busy

Output: List of error scenarios + current handling + recommendations.
```

**Coordinator Action After:**
- Improve error handling
- Add user-facing error messages
- Test error scenarios

---

### Phase 6: Documentation & Finalization (Day 5)

#### Task 6.1: API Documentation
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** sql_js_helper.dart
**Deliverable:** Complete API docs

**Prompt:**
```
Add comprehensive dartdoc to lib/core/database/sql_js_helper.dart.

For each public method:
1. Brief description
2. Parameters explained
3. Return value explained
4. Example usage
5. Exceptions that can be thrown

Example:
/// Query the database with optional filters.
///
/// Returns a list of rows matching the query criteria.
///
/// Example:
/// ```dart
/// final verses = await db.query(
///   'bible_verses',
///   where: 'book = ?',
///   whereArgs: ['John'],
///   limit: 10,
/// );
/// ```
///
/// Throws [DatabaseException] if query fails.

Add class-level documentation explaining:
- Purpose of this class
- When to use vs sqflite
- Platform compatibility
- Performance characteristics
```

**Coordinator Action After:**
- Review docs
- Generate dartdoc
- Publish to team

---

#### Task 6.2: Migration Guide
**Sub-Agent:** General-purpose agent
**Duration:** 2 hours
**Context Required:** All changes made
**Deliverable:** Developer migration guide

**Prompt:**
```
Create MIGRATION_GUIDE.md documenting the sqflite → sql.js migration.

Sections needed:
1. Overview (what changed, why)
2. Breaking changes (if any)
3. New dependencies (sql_js package)
4. Code changes required
5. Testing approach
6. Performance considerations
7. Browser compatibility
8. Troubleshooting common issues
9. FAQ

Include code examples showing:
- Before (sqflite)
- After (sql.js)
- Platform detection pattern
- Asset loading pattern

Target audience: Flutter developers familiar with sqflite.
```

**Coordinator Action After:**
- Review guide
- Add to documentation
- Share with team

---

## Coordinator Responsibilities

### Integration Tasks (Not Delegated)

**You (Coordinator) will handle:**

1. **Code Integration**
   - Merge sub-agent outputs
   - Resolve conflicts
   - Maintain code quality

2. **Testing & Iteration**
   - Run integration tests
   - Fix bugs discovered
   - Iterate on failing tests
   - Performance tuning

3. **Decision Making**
   - Choose between alternatives
   - Resolve ambiguities
   - Make architectural choices

4. **Quality Assurance**
   - Code review
   - Performance profiling
   - Security audit

5. **Progress Tracking**
   - Monitor task completion
   - Adjust timeline as needed
   - Communicate status

---

## Revised Timeline

### Day 1: Research & Setup (8 tasks)
```
Morning:
✓ Task 1.1: Schema documentation (1-2h)
✓ Task 1.2: Service dependency map (1-2h)
✓ Task 1.3: Asset DB analysis (1h)
✓ Task 2.1: Interface stubs (1h)

Afternoon:
✓ Task 2.2: WASM loader (2h)
✓ Task 2.3: IndexedDB persistence (2h)

Evening (Coordinator):
✓ Integration testing
✓ Fix any issues
```

### Day 2: Core Implementation (6 tasks)
```
Morning:
✓ Task 2.4: Query method (2h)
✓ Task 2.5: Insert/Update/Delete (2h)

Afternoon:
✓ Task 3.1: Export Bible DBs (1h)
✓ Task 3.2: Optimize SQL (2h)

Evening:
✓ Task 3.3: Bible loader service (2h)
✓ Coordinator: Test data loading
```

### Day 3: Data & Services (5 tasks)
```
Morning:
✓ Task 3.4: FTS setup (2h)
✓ Task 4.1: Update DatabaseHelper (1h)

Afternoon:
✓ Task 4.2: Test PrayerService (1h)
✓ Task 4.3: Test UnifiedVerseService (2h)

Evening (Coordinator):
✓ Fix service issues
✓ Test more services
```

### Day 4: Service Testing (10 tasks)
```
Full Day:
✓ Tasks 4.4-4.13: Test remaining services (1h each)

Coordinator:
✓ Fix issues as they arise
✓ Run integration tests
✓ Performance check
```

### Day 5: Polish & Finalize (5 tasks)
```
Morning:
✓ Task 5.1: Performance profiling (2h)
✓ Task 5.2: Cross-browser testing (3h)

Afternoon:
✓ Task 5.3: Error handling audit (2h)
✓ Task 6.1: API documentation (2h)
✓ Task 6.2: Migration guide (2h)

Evening (Coordinator):
✓ Final integration
✓ Deployment preparation
✓ Release notes
```

**Total: 5 days with 34 atomic tasks**

---

## Success Metrics

### Task-Level Success (Each Sub-Agent Task)
✅ Clear deliverable produced
✅ No errors in execution
✅ Coordinator can integrate without modification
✅ Passes basic validation

### Integration-Level Success (Coordinator)
✅ All tasks integrated smoothly
✅ No breaking changes to mobile
✅ All tests passing
✅ Performance targets met

### System-Level Success (Overall)
✅ Web app loads and functions
✅ All 23 tables working
✅ 56,000 verses loaded
✅ Search works (FTS)
✅ CRUD operations functional
✅ Cross-browser compatible
✅ Performance acceptable (<5s load)

---

## Risk Mitigation

### Sub-Agent Risks

| Risk | Mitigation |
|------|------------|
| Task too complex | Break into smaller sub-tasks |
| Insufficient context | Provide complete file contents in prompt |
| Ambiguous requirements | Give explicit examples and test cases |
| Can't handle failures | Coordinator tests and fixes issues |
| Tool limitations | Use Explore agents for research, General for coding |

### Coordinator Risks

| Risk | Mitigation |
|------|------------|
| Integration conflicts | Test after each merge |
| Performance issues | Profile early and often |
| Browser incompatibilities | Test in all browsers regularly |
| Timeline overruns | Buffer time built into each day |

---

## Task Launch Template

### For Each Task:

**Pre-Launch Checklist:**
- [ ] Task clearly defined
- [ ] Success criteria explicit
- [ ] All context provided (file paths, code snippets)
- [ ] Expected output format specified
- [ ] Constraints documented
- [ ] Testing approach defined

**Launch Command:**
```dart
Task(
  subagent_type: "general-purpose", // or "Explore"
  description: "Clear 3-5 word description",
  prompt: """
  <Complete task description>

  Context:
  <All files, APIs, examples needed>

  Requirements:
  <Explicit list of what to do>

  Output Format:
  <Exactly what to return>

  Test Cases:
  <How to validate success>

  Constraints:
  <Any limitations or guidelines>
  """
)
```

**Post-Completion:**
- [ ] Review deliverable
- [ ] Test locally
- [ ] Integrate into codebase
- [ ] Run tests
- [ ] Fix any issues
- [ ] Mark task complete
- [ ] Launch next task

---

## Key Improvements Over V1

### What Changed:

1. **Task Size:** 2-hour tasks instead of 8-12 hour tasks
2. **Atomicity:** Each task is self-contained
3. **Context:** Complete context provided in each prompt
4. **Integration:** Coordinator handles all integration
5. **Testing:** Coordinator runs tests, agents only validate
6. **Iteration:** Coordinator iterates, agents execute once
7. **Decision-Making:** Coordinator makes all decisions
8. **Dependencies:** Loose coupling between tasks

### Why This Works Better:

✅ **Sub-agents don't need to iterate** - One execution succeeds or fails clearly
✅ **Context stays manageable** - Each task focuses on small scope
✅ **Coordinator can fix issues** - Sub-agents just provide raw output
✅ **Failures are isolated** - One task failing doesn't block others
✅ **Progress is measurable** - 34 clear checkpoints
✅ **Timeline is realistic** - Based on atomic task completion

---

## Execution Checklist

### Pre-Migration:
- [ ] Review this plan
- [ ] Validate task breakdown
- [ ] Ensure all file paths correct
- [ ] Set up version control branches
- [ ] Backup current database

### During Migration:
- [ ] Launch tasks sequentially (in order)
- [ ] Test after each integration
- [ ] Document issues immediately
- [ ] Fix problems before next task
- [ ] Update progress tracking

### Post-Migration:
- [ ] Full regression testing
- [ ] Performance validation
- [ ] Cross-browser testing
- [ ] Documentation complete
- [ ] Deployment ready

---

## Next Steps

**Immediate Action:**
Launch Task 1.1 (Schema Documentation) to begin the migration.

**Command:**
```
Use Task tool with Explore agent to document database schema from database_helper.dart
```

This will provide the foundation for all subsequent tasks.

---

**Plan Status:** Ready for execution with realistic sub-agent constraints
**Estimated Success Probability:** 95% (with coordinator oversight)
**Blocker Risk:** Low (atomic tasks, clear integration points)
