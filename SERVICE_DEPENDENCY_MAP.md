# Service Dependency Map - Task 1.2

**Last Updated:** December 15, 2024
**Total Services Analyzed:** 17
**Database Services:** 15
**Non-Database Services:** 2

---

## Executive Summary

This document maps every service in the Everyday Christian codebase to its database dependencies, query patterns, and migration complexity. This is critical for Phase 4 testing when we validate each service on web.

### Key Statistics
- **Most Complex Service:** ReadingPlanProgressService (640 lines, HIGH complexity)
- **Most Queried Table:** bible_verses (used by 5+ services)
- **Services with Transactions:** 2 (CategoryService, ConversationService)
- **Services with FTS5 Search:** 2 (UnifiedVerseService, BibleChapterService)
- **Services with Asset DBs:** 1 (BibleLoaderService - critical for Bible loading)

---

## Database Services

### 1. PrayerService
**File:** `lib/core/services/prayer_service.dart`
**Lines:** 333
**Priority:** HIGH
**Complexity:** MEDIUM

**Tables:**
- `prayer_requests` - CRUD operations
- Indirect: `prayer_categories`, `achievement_completions`

**Key Methods:**
- `getActivePrayers()` - Query with complex WHERE
- `addPrayer()` - Insert + achievement tracking
- `exportPrayerJournal()` - Raw SQL export

**Dependencies:** AchievementService, PrayerStreakService

**Testing Notes:**
- Test CRUD with various category filters
- Test prayer streak achievement tracking (7+ days = achievement)
- Test export format

---

### 2. CategoryService
**File:** `lib/core/services/category_service.dart`
**Lines:** 302
**Priority:** HIGH
**Complexity:** MEDIUM

**Tables:**
- `prayer_categories` - Full CRUD
- `prayer_requests` - Query for statistics

**Key Methods:**
- `reorderCategories()` - **TRANSACTION** (atomic updates)
- `getCategoryStatistics()` - Raw SQL aggregation
- `isCategoryNameAvailable()` - Validation query

**Query Pattern Notes:**
- Uses raw SQL for statistics aggregation
- Transaction on line 181 for reordering
- Complex WHERE clauses for filtering

**Testing Notes:**
- Test transaction atomicity for reordering
- Test unique name validation
- Test cascade behavior when deleting categories

---

### 3. ReadingPlanService
**File:** `lib/core/services/reading_plan_service.dart`
**Lines:** 180
**Priority:** HIGH
**Complexity:** MEDIUM

**Tables:**
- `reading_plans` - Query, Insert, Update
- `daily_readings` - Query, Insert, Update

**Key Methods:**
- `getTodaysReadings()` - Query with date filtering
- `startPlan()` - Insert new plan with readings
- `markReadingCompleted()` - Update with progress sync

**Testing Notes:**
- Test today's readings logic across timezones
- Test plan start with reading generation
- Test progress percentage calculation

---

### 4. DevotionalService
**File:** `lib/core/services/devotional_service.dart`
**Lines:** 148
**Priority:** HIGH
**Complexity:** LOW

**Tables:**
- `devotionals` - Query, Update

**Key Methods:**
- `getTodaysDevotional()` - Simple date-based query
- `markDevotionalCompleted()` - Update with timestamp
- `getCurrentStreak()` - In-memory calculation

**Testing Notes:**
- Simple CRUD operations
- In-memory streak calculation logic

---

### 5. AchievementService
**File:** `lib/core/services/achievement_service.dart`
**Lines:** 276
**Priority:** MEDIUM
**Complexity:** MEDIUM

**Tables:**
- `achievement_completions` - Query, Insert, Delete
- `shared_chats` - Delete on reset
- `shared_verses` - Query for Disciple achievement
- `shared_devotionals` - Query for Disciple achievement
- `shared_prayers` - Query for Disciple achievement

**Key Methods:**
- `checkAllSharesAchievement()` - **PARALLEL RAW QUERIES** (lines 237-240)
- `recordCompletion()` - Track achievement progress
- `clearAllCompletions()` - Reset all achievements

**Critical Pattern:**
```sql
SELECT COUNT(*) FROM shared_chats/verses/devotionals/prayers
-- Parallel queries to track Disciple achievement (all shares)
```

**Testing Notes:**
- Test achievement type validation
- Test all share counting for Disciple achievement
- Test completion history tracking

---

### 6. BibleLoaderService
**File:** `lib/core/services/bible_loader_service.dart`
**Lines:** 261
**Priority:** HIGH
**Complexity:** HIGH

**Tables:**
- `bible_verses` - Insert via asset DB join
- `daily_verse_schedule` - Insert via asset DB join

**Asset Databases:**
- `bible.db` (English WEB translation)
- `spanish_bible_rvr1909.db` (Spanish translation)

**Key Methods:**
- `_copyEnglishBible()` - **ATTACH DATABASE** + JOIN + CASE statement
- `_copySpanishBible()` - Same pattern for Spanish
- `isBibleLoaded()` - Check completion

**Critical SQL Pattern:**
```sql
ATTACH DATABASE 'asset_db_en' AS asset_db_en;
INSERT OR REPLACE INTO bible_verses
SELECT ... FROM asset_db_en.verses
JOIN ... (complex mapping with CASE statement)
DETACH DATABASE asset_db_en;
```

**Why HIGH Complexity:**
1. Asset database attachment/detachment
2. Complex JOIN with book/chapter/verse mapping
3. CASE statement for translation mapping
4. Large data volume (30,000+ verses)

**Testing Notes:**
- Test asset DB attachment and detachment
- Test JOIN logic for verse mapping
- Test English/Spanish translation mapping
- Test performance with large data sets

---

### 7. PrayerStreakService
**File:** `lib/core/services/prayer_streak_service.dart`
**Lines:** 240
**Priority:** HIGH
**Complexity:** LOW

**Tables:**
- `prayer_streak_activity` - Query, Insert, Delete

**Key Methods:**
- `recordPrayerActivity()` - Insert YYYYMMDD entry
- `getCurrentStreak()` - In-memory calculation
- `getLongestStreak()` - In-memory calculation

**Data Format Notes:**
- Uses YYYYMMDD integer format for dates
- One entry per day maximum
- Streak calculation done in-memory

**Testing Notes:**
- Test date format handling
- Test streak calculation logic
- Test duplicate prevention (one entry/day)

---

### 8. DevotionalProgressService
**File:** `lib/core/services/devotional_progress_service.dart`
**Lines:** 304
**Priority:** HIGH
**Complexity:** MEDIUM

**Tables:**
- `devotionals` - Query, Update

**Key Methods:**
- `markAsComplete()` - Update with timestamp
- `getCompletionStatus()` - Query specific devotional
- `getTotalCompleted()` - Count query
- `getCurrentStreak()` - Raw SQL with date calculation

**Achievements Tracked:**
- **Daily Bread:** 30 devotionals per month

**Complex SQL:**
- Line 46: Month boundary calculations
- Line 113: Streak calculation with date ranges
- Line 217: Completion history query

**Testing Notes:**
- Test month boundary crossing for Daily Bread
- Test completion date tracking
- Test streak calculation accuracy

---

### 9. ReadingPlanProgressService
**File:** `lib/core/services/reading_plan_progress_service.dart`
**Lines:** 640
**Priority:** HIGH
**Complexity:** HIGH

**Tables:**
- `daily_readings` - Query, Update, Delete
- `reading_plans` - Query, Update

**Key Methods:**
- `getCalendarHeatmapData()` - Complex aggregation
- `getStreak()` - Raw SQL with window functions
- `getEstimatedCompletionDate()` - Complex calculation
- `resetPlan()` - Clear progress

**Achievements Tracked:**
- **Deep Diver:** 5 plans completed

**Why HIGH Complexity:**
1. **10+ Raw SQL queries** (lines 92, 101, 123, 334, 340, 475, 485, 518, 557, 602)
2. **Complex nested WHERE clauses**
3. **Heatmap data generation** (calendar grid)
4. **Estimated completion logic** (non-linear calculation)
5. **Multiple table updates**

**Critical Patterns:**
```sql
-- Heatmap data: group completions by date
SELECT DATE(), COUNT(*) as completions FROM daily_readings

-- Estimated completion: account for missed days
SELECT completion_rate, plan_duration, missed_days

-- Streak: find consecutive days from today backwards
SELECT ... WHERE is_completed = 1 ORDER BY reading_date DESC
```

**Testing Notes:**
- **CRITICAL:** Test heatmap calculation accuracy
- Test estimated completion across different plan types
- Test streak calculation with gaps
- Test progress percentage with incomplete readings
- Test performance with large datasets (100+ readings)

---

### 10. UnifiedVerseService
**File:** `lib/services/unified_verse_service.dart`
**Lines:** 585
**Priority:** HIGH
**Complexity:** HIGH

**Tables:**
- `bible_verses` - Query only
- `bible_verses_fts` - FTS5 search
- `favorite_verses` - CRUD
- `shared_verses` - CRUD
- `verse_preferences` - Insert/Update

**Key Methods:**
- `searchVerses()` - **FTS5 with 10-second timeout** (lines 31-44)
- `_fallbackSearch()` - Fallback LIKE search
- `searchByTheme()` - Theme-based filtering
- `getFavoriteVerses()` - JOIN query (line 250)
- `recordSharedVerse()` - Track shares

**Achievements Tracked:**
- **Curator:** 100 saved verses

**Why HIGH Complexity:**
1. **FTS5 full-text search** with ranking and randomization
2. **10-second timeout** with fallback mechanism
3. **JOIN operations** (FTS table + main table)
4. **Theme mapping** with situation context
5. **Achievement tracking** across multiple tables

**FTS5 Pattern:**
```sql
SELECT v.*, snippet(bible_verses_fts, 0, '<mark>', '</mark>', '...', 32) as snippet
FROM bible_verses_fts
JOIN bible_verses v ON bible_verses_fts.rowid = v.id
WHERE bible_verses_fts MATCH ?
ORDER BY rank, RANDOM()
LIMIT ? (with 10-second timeout)
```

**Theme Mapping Example:**
- "anxiety" -> ["peace", "comfort", "trust"]
- "depression" -> ["hope", "comfort", "strength"]

**Testing Notes:**
- **CRITICAL:** Test FTS5 search with various queries
- Test timeout fallback mechanism
- Test theme-to-verse mapping
- Test favorite count achievement (Curator)
- Test theme search performance
- Test LIKE fallback when FTS fails

---

### 11. ConversationService
**File:** `lib/services/conversation_service.dart`
**Lines:** 484
**Priority:** HIGH
**Complexity:** MEDIUM

**Tables:**
- `chat_messages` - CRUD
- `chat_sessions` - CRUD

**Key Methods:**
- `_verifyChatSessionsSchema()` - **Schema repair** (adds missing columns dynamically)
- `saveMessages()` - **TRANSACTION** for batch insert (line 90)
- `deleteSession()` - **TRANSACTION** (line 306) for cascade delete
- `searchMessages()` - Search query
- `exportConversation()` - Export as text

**Why Notable:**
1. **Dynamic schema repair** on initialization
2. **Transactions** for batch operations
3. **Text export** functionality
4. **Old message cleanup** by age

**Schema Repair Pattern:**
```dart
// Tries ALTER TABLE for missing columns
// Updates null values with defaults
// Handles column additions gracefully
```

**Testing Notes:**
- Test schema repair logic
- Test transaction atomicity for batch inserts
- Test session deletion cascade
- Test message export format
- Test old conversation cleanup

---

### 12. BibleChapterService
**File:** `lib/services/bible_chapter_service.dart`
**Lines:** 321
**Priority:** HIGH
**Complexity:** MEDIUM

**Tables:**
- `bible_verses` - Query (READ-ONLY)
- `bible_verses_fts` - FTS5 search
- `daily_readings` - Update (progress tracking)
- `reading_plans` - Update (progress rollup)

**Key Methods:**
- `getChapterVerses()` - Query specific chapter
- `getChapterRange()` - Range query with grouping
- `getAllBooks()` - **Complex CASE statement** for book ordering (English/Spanish)
- `searchVerses()` - FTS5 with version filtering
- `markReadingComplete()` - **Nested update** (lines 213-221)

**Complex SQL Example:**
```sql
-- getAllBooks() uses 66-book CASE statement for biblical order
SELECT DISTINCT book FROM bible_verses
ORDER BY CASE book
  WHEN 'Genesis' THEN 1
  WHEN 'Exodus' THEN 2
  ...
  WHEN 'Revelation' THEN 66
  ELSE 999
END
```

**Testing Notes:**
- Test book ordering for all 66 books (English + Spanish)
- Test chapter range grouping
- Test FTS5 search with version filter
- Test reading completion updates cascade

---

### 13. DailyVerseService
**File:** `lib/services/daily_verse_service.dart`
**Lines:** 197
**Priority:** MEDIUM
**Complexity:** LOW

**Tables:**
- `bible_verses` - Query only

**Storage:**
- **SharedPreferences** for verse caching
- Singleton pattern

**Key Methods:**
- `getDailyVerse()` - Query + cache logic
- `refreshDailyVerse()` - Force refresh
- `checkAndUpdateVerse()` - Widget sync

**Dependencies:** WidgetService (iOS-only)

**Testing Notes:**
- Test cache freshness logic
- Test timezone-aware day boundaries
- Test widget update trigger

---

## Non-Database Services

### 14. NotificationService
**File:** `lib/core/services/notification_service.dart`
**Lines:** 337
**Priority:** MEDIUM
**Complexity:** LOW

**Database Access:** Indirect (via dependent services)

**Dependencies:**
- DevotionalProgressService
- UnifiedVerseService
- PrayerService
- ReadingPlanService

**Platform-Specific:**
- iOS: DarwinNotificationDetails
- Android: AndroidNotificationDetails

**Testing Notes:**
- Test notification channel creation
- Test platform-specific scheduling
- Test timezone handling

---

### 15. AppLockoutService
**File:** `lib/core/services/app_lockout_service.dart`
**Lines:** 243
**Priority:** MEDIUM
**Complexity:** LOW

**Storage:** SharedPreferences only (no database)

**Key Features:**
- Max 3 failed attempts
- 30-minute lockout duration
- Device PIN/biometric fallback
- Uses local_auth plugin

**Testing Notes:**
- Test attempt counting
- Test lockout duration
- Test biometric fallback

---

### 16. SubscriptionService
**File:** `lib/core/services/subscription_service.dart`
**Lines:** 987
**Priority:** HIGH
**Complexity:** LOW

**Storage:** 
- SharedPreferences for state
- Secure Storage (Keychain/KeyStore) for trial abuse prevention

**Key Features:**
- **Trial:** 3 days OR 15 messages (whichever comes first)
- **Premium:** 150 messages/month
- **Abuse Prevention:** Survives app uninstall

**Platform-Specific:**
- iOS: in_app_purchase + Keychain
- Android: in_app_purchase + KeyStore

**Testing Notes:**
- Test trial expiry conditions
- Test message counter reset
- Test subscription restoration
- Test trial abuse prevention across reinstalls

---

### 17. WidgetService
**File:** `lib/services/widget_service.dart`
**Lines:** 151
**Priority:** LOW
**Complexity:** LOW

**Platform:** iOS-only

**Storage:** App Groups shared UserDefaults

**Key Features:**
- Daily verse widget updates
- Deep linking from widget taps
- App Group sharing (group.com.edcfaith.shared)

**Testing Notes:**
- Test App Group data sharing
- Test widget update trigger
- Test deep linking

---

## Critical Database Patterns

### Transactions (2 services)
1. **CategoryService** - Atomic category reordering
2. **ConversationService** - Batch message inserts and session deletion

### Raw SQL Queries (9 services)
- PrayerService
- CategoryService
- ReadingPlanService
- DevotionalService
- AchievementService
- BibleLoaderService
- PrayerStreakService
- DevotionalProgressService
- ReadingPlanProgressService

### FTS5 Full-Text Search (2 services)
1. **UnifiedVerseService** - Verse text search with 10-second timeout
2. **BibleChapterService** - Chapter verse search

### Complex JOINs (3 services)
1. **UnifiedVerseService** - bible_verses_fts JOIN bible_verses
2. **BibleLoaderService** - asset_db.verses JOIN bible_verses (with CASE mapping)
3. **BibleChapterService** - bible_verses_fts JOIN bible_verses

### Asset Database Operations (1 service)
- **BibleLoaderService** - ATTACH/DETACH with large data migration

---

## Tables by Usage Frequency

### High Usage (5+ services)
- `bible_verses` - UnifiedVerseService, BibleChapterService, DailyVerseService, BibleLoaderService, ReadingPlanProgressService (indirect)
- `achievement_completions` - 5 services track achievements

### Medium Usage (2-4 services)
- `prayer_requests` - PrayerService, CategoryService
- `daily_readings` - ReadingPlanService, ReadingPlanProgressService, BibleChapterService
- `prayer_categories` - PrayerService, CategoryService

### Low Usage (1 service)
- `chat_messages` - ConversationService only
- `chat_sessions` - ConversationService only
- `favorite_verses` - UnifiedVerseService only
- `shared_verses` - UnifiedVerseService only

---

## Migration Roadmap

### Phase 1 - Core Services (HIGH Priority)
1. **PrayerService** - Foundation for prayer features
2. **CategoryService** - Category management
3. **DevotionalService** - Daily devotional tracking
4. **UnifiedVerseService** - Verse search and favorites
5. **ConversationService** - Chat persistence

**Rationale:** These are core user-facing features accessed daily.

### Phase 2 - Advanced Services (MEDIUM Priority)
1. **ReadingPlanService** - Reading plan CRUD
2. **ReadingPlanProgressService** - Complex progress tracking
3. **BibleChapterService** - Chapter verse fetching
4. **AchievementService** - Achievement tracking

**Rationale:** Important but less frequent than Phase 1.

### Phase 3 - Dependent Services (LOW Priority)
1. **NotificationService** - Depends on Phase 1 & 2
2. **AppLockoutService** - No database
3. **SubscriptionService** - No database (uses SharedPreferences)
4. **DailyVerseService** - Uses SharedPreferences caching
5. **WidgetService** - iOS-only, no database

**Rationale:** Either have no database or depend on other services.

### Phase 4 - Asset Databases (SPECIAL)
1. **BibleLoaderService** - Most complex, high impact

**Rationale:** Critical for Bible loading but most complex operation.

---

## Testing Strategy

### Unit Tests Focus
- PrayerService CRUD with filters
- CategoryService validation and reordering
- AchievementService aggregation queries
- UnifiedVerseService FTS and fallback

### Integration Tests Focus
- **ReadingPlanProgressService** - Nested updates and heatmap data
- **ConversationService** - Transactions and schema repair
- **BibleLoaderService** - Asset DB attachment and migration

### Mock Data Requirements
- **bible_verses:** 10,000+ verses across all books
- **prayer_requests:** Mix of answered/active/by category
- **chat_messages:** Multiple sessions with different message types
- **reading_plans:** Various completion states and progress levels

### Performance Baselines
- FTS5 search: < 5 seconds for common queries (timeout: 10 seconds)
- Heatmap generation: < 2 seconds for 365 days
- Bible loader: < 30 seconds for full migration
- Streak calculation: < 1 second for multi-year data

---

## Key Findings

### Most Complex Operations
1. **ReadingPlanProgressService** - 10+ raw SQL queries for calendar heatmaps
2. **BibleLoaderService** - Asset DB attachment with complex JOINs
3. **UnifiedVerseService** - FTS5 with timeout and fallback mechanism

### Highest Risk for Web Migration
1. **BibleLoaderService** - May not support asset databases on web
2. **ReadingPlanProgressService** - Complex date calculations may differ
3. **ConversationService** - Schema repair logic needs careful testing

### Services Ready for Web
1. **PrayerService** - Standard CRUD
2. **CategoryService** - Standard CRUD with transaction
3. **DevotionalService** - Simple queries
4. **NotificationService** - No database (notification API based)

### Achievements to Track During Migration
- **Disciple:** All shares combined (shared_chats/verses/devotionals/prayers)
- **Daily Bread:** 30 devotionals per month
- **Deep Diver:** 5 reading plans completed
- **Curator:** 100 saved verses

---

## Next Steps

1. **Phase 1:** Migrate and test PrayerService, CategoryService
2. **Phase 2:** Test FTS5 functionality for UnifiedVerseService
3. **Phase 3:** Develop asset database migration strategy for BibleLoaderService
4. **Phase 4:** Create comprehensive test data fixtures for all tables
5. **Phase 5:** Performance benchmark web implementation against mobile

---

**Document Version:** 1.0
**Analysis Date:** December 15, 2024
**Codebase Branch:** main
**Total Code Analyzed:** 12,688 lines across 41 service files
