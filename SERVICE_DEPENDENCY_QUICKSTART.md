# Service Dependency Map - Quick Start Guide

## For Phase 4 Web Migration Testing

### Critical Services Requiring Special Attention

#### 1. BibleLoaderService (HIGHEST PRIORITY)
- **Complexity:** HIGH
- **Risk:** Asset databases may not work on web platform
- **Critical Pattern:** ATTACH DATABASE with complex JOINs
- **Action Required:** Develop web-compatible alternative
- **Test:** Asset attachment/detachment, verse mapping accuracy

#### 2. ReadingPlanProgressService (HIGHEST COMPLEXITY)
- **Complexity:** HIGH  
- **Risk:** Complex date calculations may vary on web
- **Critical Pattern:** 10+ raw SQL queries for heatmap data
- **Action Required:** Comprehensive date/timezone testing
- **Test:** Heatmap accuracy, estimated completion logic

#### 3. UnifiedVerseService (FTS5 CRITICAL)
- **Complexity:** HIGH
- **Risk:** FTS5 timeout (10 seconds) may need tuning for web
- **Critical Pattern:** FTS5 search with fallback LIKE
- **Action Required:** Test search performance and fallback behavior
- **Test:** Search speed, timeout handling, theme mapping

### Database Schema Summary

**18 Core Tables:**
- prayer_requests, prayer_categories, prayer_streak_activity
- reading_plans, daily_readings  
- devotionals
- achievement_completions
- bible_verses, bible_verses_fts, daily_verse_schedule
- chat_messages, chat_sessions
- favorite_verses, shared_verses, shared_chats, shared_devotionals, shared_prayers
- verse_preferences

**2 Asset Databases:**
- bible.db (English WEB)
- spanish_bible_rvr1909.db (Spanish RVR1909)

### Services by Migration Phase

**Phase 1 (CORE - Test First):**
- PrayerService
- CategoryService
- DevotionalService
- UnifiedVerseService
- ConversationService

**Phase 2 (ADVANCED - Test Second):**
- ReadingPlanService
- ReadingPlanProgressService
- BibleChapterService
- AchievementService

**Phase 3 (DEPENDENT - Test Last):**
- NotificationService
- AppLockoutService
- SubscriptionService
- DailyVerseService
- WidgetService

**Phase 4 (SPECIAL - Test with Caution):**
- BibleLoaderService

### Key Database Patterns to Test

| Pattern | Services | Test Focus |
|---------|----------|-----------|
| **Transactions** | CategoryService, ConversationService | Atomicity, rollback |
| **Raw SQL** | 9 services | SQL compatibility, query speed |
| **FTS5 Search** | UnifiedVerseService, BibleChapterService | Timeout behavior, fallback |
| **JOINs** | UnifiedVerseService, BibleLoaderService, BibleChapterService | Join performance, accuracy |
| **Asset DBs** | BibleLoaderService | Attachment/detachment, data migration |

### Critical Operations

1. **Category Reordering** (CategoryService)
   - Uses transaction for atomicity
   - Test: Update all display_order values atomically

2. **Batch Message Insert** (ConversationService)
   - Uses transaction for multiple inserts
   - Test: Atomicity with schema repair

3. **Cascade Session Delete** (ConversationService)
   - Delete messages then session
   - Test: All messages deleted with session

4. **Bible Loading** (BibleLoaderService)
   - ATTACH/DETACH with 30,000+ verses
   - Test: Performance and accuracy

5. **FTS5 Search** (UnifiedVerseService)
   - 10-second timeout with fallback LIKE
   - Test: Speed, timeout handling, results accuracy

### Test Data Requirements

```
bible_verses: 10,000+ entries (multiple books, English & Spanish)
prayer_requests: 100+ mixed (answered, active, by category)
chat_messages: 50+ across 5 sessions
reading_plans: 20+ with various completion states
achievements: Full coverage of all types
```

### Quick Health Checks

Run these before declaring Phase 4 ready:

1. **Bible Loading Speed**
   - Target: < 30 seconds for full migration
   - Measure: Time to populate bible_verses table

2. **FTS5 Search Performance**
   - Target: < 5 seconds for common queries
   - Measure: Time for "faith", "hope", "peace" searches

3. **Heatmap Generation**
   - Target: < 2 seconds for 365 days
   - Measure: Calendar heatmap render time

4. **Streak Calculations**
   - Target: < 1 second for 5+ years of data
   - Measure: Current streak, longest streak queries

5. **Transaction Atomicity**
   - Target: 100% atomicity on transaction operations
   - Measure: Rollback accuracy on simulated failures

### High-Risk Scenarios

These scenarios are most likely to fail on web:

1. **Asset Database Attachment** - May not work on web platform
2. **CASE Statements** - 66-book ordering might be SQL dialect-specific
3. **ATTACH DATABASE** - May require special web permissions
4. **DATE() Functions** - Timezone handling may differ
5. **FTS5 Timeout** - Browser JS execution context differs

### Achievement Tracking

Ensure these are preserved during migration:

- **Disciple:** All shares (chats, verses, devotionals, prayers) combined
- **Daily Bread:** 30 devotionals per month
- **Deep Diver:** 5 reading plans completed
- **Curator:** 100 saved verses

### Success Criteria

Service is ready for web when:

- [ ] All CRUD operations work correctly
- [ ] Transactions maintain atomicity
- [ ] FTS5 searches complete within timeout
- [ ] Join queries return correct results
- [ ] Achievement counts are accurate
- [ ] Date calculations respect timezones
- [ ] Performance baselines met
- [ ] Schema repair logic works
- [ ] Data migrations preserve integrity

### Files to Reference

- `SERVICE_DEPENDENCY_MAP.json` - Full technical details
- `SERVICE_DEPENDENCY_MAP.md` - Detailed service documentation
- `lib/core/database/database_helper.dart` - Database layer
- `lib/core/database/app_database.dart` - Schema definition

### Next Actions

1. **Immediate:** Review BibleLoaderService for web compatibility
2. **Week 1:** Create comprehensive test suite for ReadingPlanProgressService
3. **Week 2:** Performance benchmark UnifiedVerseService FTS5 search
4. **Week 3:** Test all transaction scenarios
5. **Week 4:** End-to-end migration testing

---

**Quick Reference:** 17 total services | 15 database services | 2 non-database services
**Completion Time:** ~8-10 weeks for full Phase 4 migration
