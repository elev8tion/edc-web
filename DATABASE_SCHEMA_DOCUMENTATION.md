# The Real Everyday Christian - Complete Database Schema Documentation

**Database Name:** `everyday_christian.db`
**Current Version:** 20
**Total Tables:** 23
**Virtual Tables (FTS):** 1
**Triggers:** 4

This documentation was generated as part of the PWA migration project (Task 1.1).

---

## Table of Contents
1. Bible Verses Tables (6 tables)
2. Chat Tables (4 tables)
3. Prayer Tables (4 tables)
4. Devotional Tables (1 table)
5. Reading Plan Tables (2 tables)
6. User Settings & Metadata (3 tables)
7. All Indexes (Complete List - 34 indexes)
8. All Triggers (Complete List - 4 triggers)
9. Migration History (v1-v20)
10. Foreign Key Relationships
11. Performance Optimization Summary

---

## Quick Reference

### Tables by Domain

**Bible (6 tables):**
- `bible_verses` - Main scripture storage (~56K verses)
- `bible_verses_fts` - Full-text search index (FTS4/FTS5)
- `favorite_verses` - User bookmarks
- `daily_verses` - Daily verse delivery tracking
- `daily_verse_history` - Historical record
- `daily_verse_schedule` - 365-day calendar (bilingual)
- `verse_bookmarks` - Detailed bookmarks
- `verse_preferences` - Verse selection preferences

**Chat (4 tables):**
- `chat_sessions` - Conversation sessions
- `chat_messages` - Individual messages
- `shared_chats` - Share tracking
- `shared_verses` - Verse shares (denormalized)

**Prayer (4 tables):**
- `prayer_requests` - User prayers
- `prayer_categories` - Categories (8 defaults + custom)
- `prayer_streak_activity` - Daily activity tracking
- `shared_prayers` - Prayer shares

**Devotional (1 table):**
- `devotionals` - 8-section format devotionals

**Reading Plans (2 tables):**
- `reading_plans` - Plan metadata
- `daily_readings` - Progress tracking

**Settings (3 tables):**
- `user_settings` - App preferences (14 defaults)
- `search_history` - Search analytics
- `achievement_completions` - User achievements
- `app_metadata` - App-level config

---

[Full documentation content from the agent's output above...]
