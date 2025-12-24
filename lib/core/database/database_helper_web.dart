/// Web-specific DatabaseHelper implementation
///
/// Uses sql.js (via SqlJsHelper) for web platform SQLite access.
/// This implementation uses BibleDataLoaderWeb and BibleFtsSetupWeb for
/// initial data loading.
library database_helper_web;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'sql_js_helper.dart';
import '../services/bible_data_loader_web.dart';
import '../services/bible_fts_setup_web.dart';
import '../logging/app_logger.dart';
import 'database_interface.dart';

/// Web database implementation using sql.js
class DatabaseHelperImpl implements DatabaseInterface {
  // Singleton pattern
  DatabaseHelperImpl._privateConstructor();
  static final DatabaseHelperImpl instance =
      DatabaseHelperImpl._privateConstructor();

  static SqlJsDatabase? _database;
  static final AppLogger _logger = AppLogger.instance;
  static bool _isInitialized = false;

  /// Get database instance
  @override
  Future<SqlJsDatabase> get database async {
    try {
      if (_database != null) return _database!;

      _logger.info('Initializing web database...',
          context: 'DatabaseHelperImpl');

      // Get sql.js database instance
      _database = await SqlJsHelper.database;

      // Check if database needs initialization
      if (!_isInitialized) {
        _logger.info('First launch detected, initializing database...',
            context: 'DatabaseHelperImpl');
        await _initialize(_database!);
        _isInitialized = true;
      }

      return _database!;
    } catch (e, stackTrace) {
      _logger.fatal(
        'Failed to get database instance',
        context: 'DatabaseHelperImpl',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Initialize database on first launch
  ///
  /// This is called when the database is empty (first web launch).
  /// It performs the following steps:
  /// 1. Create all 23 table schemas
  /// 2. Load Bible data (English + Spanish)
  /// 3. Setup FTS indexes
  /// 4. Insert default data (settings, categories, etc.)
  Future<void> _initialize(SqlJsDatabase db) async {
    try {
      // Check if already initialized
      final isInitialized = await _checkIfInitialized(db);
      if (isInitialized) {
        _logger.info('Database already initialized',
            context: 'DatabaseHelperImpl');
        return;
      }

      _logger.info('Starting database initialization...',
          context: 'DatabaseHelperImpl');

      // Step 1: Create schema (all 23 tables)
      _logger.info('Creating database schema...',
          context: 'DatabaseHelperImpl');
      await _createSchema(db);

      // Step 2: Load Bible data
      _logger.info('Loading Bible data...', context: 'DatabaseHelperImpl');
      final loader = BibleDataLoaderWeb(db);

      await for (final progress in loader.loadBibleData()) {
        debugPrint(
            '📖 Bible loading progress: ${(progress * 100).toStringAsFixed(1)}%');
      }

      // Step 3: Setup FTS indexes
      _logger.info('Setting up FTS indexes...', context: 'DatabaseHelperImpl');
      final ftsSetup = BibleFtsSetupWeb(db);
      await ftsSetup.setupFts(
        onProgress: (progress) {
          debugPrint(
              '🔍 FTS setup progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      // Step 4: Insert default data
      _logger.info('Inserting default data...', context: 'DatabaseHelperImpl');
      await _insertDefaultSettings(db);
      await _insertVersePreferences(db);
      await _insertDefaultPrayerCategories(db);

      // Mark as initialized
      await _markAsInitialized(db);

      _logger.info('Database initialization complete!',
          context: 'DatabaseHelperImpl');
    } catch (e, stackTrace) {
      _logger.fatal(
        'Database initialization failed',
        context: 'DatabaseHelperImpl',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if database is already initialized
  ///
  /// Returns true if bible_verses table exists and contains data.
  Future<bool> _checkIfInitialized(SqlJsDatabase db) async {
    try {
      // Check if bible_verses table exists
      final tables = await db.query(
        'sqlite_master',
        where: "type='table' AND name='bible_verses'",
      );

      if (tables.isEmpty) {
        return false;
      }

      // Check if table has data
      final result = await db.query('bible_verses', limit: 1);
      return result.isNotEmpty;
    } catch (e) {
      _logger.warning('Error checking initialization status: $e',
          context: 'DatabaseHelperImpl');
      return false;
    }
  }

  /// Mark database as initialized in metadata
  Future<void> _markAsInitialized(SqlJsDatabase db) async {
    try {
      await db.execute('''
        INSERT OR REPLACE INTO app_metadata (key, value, updated_at)
        VALUES ('database_initialized', 'true', ?)
      ''', [DateTime.now().millisecondsSinceEpoch]);
    } catch (e) {
      _logger.warning('Failed to mark as initialized: $e',
          context: 'DatabaseHelperImpl');
    }
  }

  /// Create all 23 database tables
  ///
  /// This creates the same schema as mobile, but without Platform.isIOS checks.
  /// Web always uses FTS5.
  Future<void> _createSchema(SqlJsDatabase db) async {
    try {
      // ==================== BIBLE VERSES TABLES ====================

      // Bible verses table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS bible_verses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          version TEXT NOT NULL,
          book TEXT NOT NULL,
          chapter INTEGER NOT NULL,
          verse INTEGER NOT NULL,
          text TEXT NOT NULL,
          language TEXT NOT NULL,
          themes TEXT,
          category TEXT,
          reference TEXT
        )
      ''');

      // Bible verses indexes
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_bible_version ON bible_verses(version)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_bible_book_chapter ON bible_verses(book, chapter)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_bible_search ON bible_verses(book, chapter, verse)');

      // Note: FTS table and triggers created by BibleFtsSetupWeb after data is loaded

      // Favorite verses
      await db.execute('''
        CREATE TABLE IF NOT EXISTS favorite_verses (
          id TEXT PRIMARY KEY,
          verse_id INTEGER,
          text TEXT NOT NULL,
          reference TEXT NOT NULL,
          category TEXT NOT NULL,
          note TEXT,
          tags TEXT,
          date_added INTEGER NOT NULL,
          FOREIGN KEY (verse_id) REFERENCES bible_verses (id) ON DELETE CASCADE
        )
      ''');

      // Daily verses
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_verses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          verse_id INTEGER NOT NULL,
          date_delivered INTEGER NOT NULL,
          user_opened INTEGER DEFAULT 0,
          notification_sent INTEGER DEFAULT 0,
          FOREIGN KEY (verse_id) REFERENCES verses (id) ON DELETE CASCADE,
          UNIQUE(verse_id, date_delivered)
        )
      ''');

      // Daily verse history
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_verse_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          verse_id INTEGER NOT NULL,
          shown_date INTEGER NOT NULL,
          theme TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (verse_id) REFERENCES bible_verses (id),
          UNIQUE(verse_id, shown_date)
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_daily_verse_date ON daily_verse_history(shown_date DESC)');

      // Daily verse schedule
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_verse_schedule (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          month INTEGER NOT NULL,
          day INTEGER NOT NULL,
          verse_id INTEGER NOT NULL,
          language TEXT DEFAULT 'en',
          FOREIGN KEY (verse_id) REFERENCES bible_verses (id),
          UNIQUE(month, day, language)
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_daily_verse_schedule_date_lang ON daily_verse_schedule(month, day, language)');

      // Verse bookmarks
      await db.execute('''
        CREATE TABLE IF NOT EXISTS verse_bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          verse_id INTEGER NOT NULL,
          note TEXT,
          tags TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER,
          FOREIGN KEY (verse_id) REFERENCES bible_verses (id),
          UNIQUE(verse_id)
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_bookmarks_created ON verse_bookmarks(created_at DESC)');

      // Verse preferences
      await db.execute('''
        CREATE TABLE IF NOT EXISTS verse_preferences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          preference_key TEXT NOT NULL UNIQUE,
          preference_value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');

      // ==================== CHAT TABLES ====================

      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_sessions (
          id TEXT PRIMARY KEY,
          title TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          is_archived INTEGER DEFAULT 0,
          message_count INTEGER DEFAULT 0,
          last_message_at INTEGER,
          last_message_preview TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_messages (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          content TEXT NOT NULL,
          type TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          status TEXT DEFAULT 'sent',
          verse_references TEXT,
          metadata TEXT,
          user_id TEXT,
          FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_chat_messages_session ON chat_messages(session_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp ON chat_messages(timestamp DESC)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS shared_chats (
          id TEXT PRIMARY KEY,
          session_id TEXT NOT NULL,
          shared_at INTEGER NOT NULL
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shared_chats_session ON shared_chats(session_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shared_chats_timestamp ON shared_chats(shared_at DESC)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS shared_verses (
          id TEXT PRIMARY KEY,
          verse_id INTEGER NOT NULL,
          book TEXT NOT NULL,
          chapter INTEGER NOT NULL,
          verse_number INTEGER NOT NULL,
          reference TEXT NOT NULL,
          translation TEXT NOT NULL,
          text TEXT NOT NULL,
          themes TEXT,
          channel TEXT NOT NULL,
          shared_at INTEGER NOT NULL
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shared_verses_verse ON shared_verses(verse_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shared_verses_timestamp ON shared_verses(shared_at DESC)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS shared_devotionals (
          id TEXT PRIMARY KEY,
          devotional_id TEXT NOT NULL,
          shared_at INTEGER NOT NULL
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shared_devotionals_devotional ON shared_devotionals(devotional_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shared_devotionals_timestamp ON shared_devotionals(shared_at DESC)');

      // ==================== PRAYER TABLES ====================

      await db.execute('''
        CREATE TABLE IF NOT EXISTS prayer_requests (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          category TEXT NOT NULL,
          status TEXT DEFAULT 'active',
          date_created INTEGER NOT NULL,
          date_answered INTEGER,
          is_answered INTEGER DEFAULT 0,
          answer_description TEXT,
          testimony TEXT,
          is_private INTEGER DEFAULT 1,
          reminder_frequency TEXT,
          grace TEXT,
          need_help TEXT,
          FOREIGN KEY (category) REFERENCES prayer_categories (id) ON DELETE RESTRICT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS shared_prayers (
          id TEXT PRIMARY KEY,
          prayer_id TEXT NOT NULL,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          is_answered INTEGER NOT NULL,
          shared_at INTEGER NOT NULL
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shared_prayers_prayer ON shared_prayers(prayer_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_shared_prayers_timestamp ON shared_prayers(shared_at DESC)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS prayer_categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          description TEXT,
          display_order INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1,
          is_default INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          date_created INTEGER NOT NULL,
          date_modified INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS prayer_streak_activity (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          activity_date INTEGER NOT NULL UNIQUE,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayer_activity_date ON prayer_streak_activity(activity_date)');

      // ==================== DEVOTIONAL TABLES ====================

      await db.execute('''
        CREATE TABLE IF NOT EXISTS devotionals (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL,
          title TEXT NOT NULL,
          opening_scripture_reference TEXT NOT NULL,
          opening_scripture_text TEXT NOT NULL,
          key_verse_reference TEXT NOT NULL,
          key_verse_text TEXT NOT NULL,
          reflection TEXT NOT NULL,
          life_application TEXT NOT NULL,
          prayer TEXT NOT NULL,
          action_step TEXT NOT NULL,
          going_deeper TEXT NOT NULL,
          reading_time TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_date INTEGER,
          action_step_completed INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // ==================== READING PLAN TABLES ====================

      await db.execute('''
        CREATE TABLE IF NOT EXISTS reading_plans (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          duration TEXT NOT NULL,
          category TEXT NOT NULL,
          difficulty TEXT NOT NULL,
          estimated_time_per_day TEXT NOT NULL,
          total_readings INTEGER NOT NULL,
          completed_readings INTEGER NOT NULL DEFAULT 0,
          is_completed INTEGER NOT NULL DEFAULT 0,
          is_started INTEGER NOT NULL DEFAULT 0,
          start_date INTEGER
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_readings (
          id TEXT PRIMARY KEY,
          plan_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          book TEXT NOT NULL,
          chapters TEXT NOT NULL,
          estimated_time TEXT NOT NULL,
          date INTEGER NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_date INTEGER,
          FOREIGN KEY (plan_id) REFERENCES reading_plans (id)
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_reading_plans_started ON reading_plans(is_started)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_daily_readings_plan ON daily_readings(plan_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_daily_readings_completion ON daily_readings(plan_id, is_completed, completed_date)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_daily_readings_date ON daily_readings(plan_id, date)');

      // ==================== USER SETTINGS ====================

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          type TEXT NOT NULL,
          created_at INTEGER,
          updated_at INTEGER
        )
      ''');

      // ==================== SEARCH HISTORY ====================

      await db.execute('''
        CREATE TABLE IF NOT EXISTS search_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT NOT NULL,
          search_type TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_search_history ON search_history(created_at DESC)');

      // ==================== ACHIEVEMENTS ====================

      await db.execute('''
        CREATE TABLE IF NOT EXISTS achievement_completions (
          id TEXT PRIMARY KEY,
          achievement_type TEXT NOT NULL,
          completed_at INTEGER NOT NULL,
          completion_count INTEGER NOT NULL,
          progress_at_completion INTEGER NOT NULL
        )
      ''');

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_achievement_completions_type ON achievement_completions(achievement_type)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_achievement_completions_timestamp ON achievement_completions(completed_at DESC)');

      // ==================== APP METADATA ====================

      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER
        )
      ''');

      // ==================== ADDITIONAL INDEXES ====================

      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorite_verses_verse_id ON favorite_verses(verse_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorite_verses_date_added ON favorite_verses(date_added DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_favorite_verses_category ON favorite_verses(category)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_daily_verses_verse_id ON daily_verses(verse_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_verse_bookmarks_verse_id ON verse_bookmarks(verse_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayer_requests_category ON prayer_requests(category)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayer_requests_status ON prayer_requests(status)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayer_requests_date_created ON prayer_requests(date_created DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_chat_sessions_created ON chat_sessions(created_at DESC)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_prayer_categories_display_order ON prayer_categories(display_order)');

      // ==================== TRIGGERS ====================

      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS update_verse_bookmarks_timestamp
        AFTER UPDATE ON verse_bookmarks
        FOR EACH ROW
        BEGIN
          UPDATE verse_bookmarks
          SET updated_at = strftime('%s', 'now')
          WHERE id = NEW.id;
        END
      ''');

      _logger.info('Database schema created successfully',
          context: 'DatabaseHelperImpl');
    } catch (e, stackTrace) {
      _logger.fatal(
        'Failed to create database schema',
        context: 'DatabaseHelperImpl',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _insertDefaultSettings(SqlJsDatabase db) async {
    final defaultSettings = [
      {'key': 'daily_verse_time', 'value': '09:30', 'type': 'String'},
      {'key': 'daily_verse_enabled', 'value': 'true', 'type': 'bool'},
      {'key': 'preferred_translation', 'value': 'ESV', 'type': 'String'},
      {'key': 'theme_mode', 'value': 'system', 'type': 'String'},
      {'key': 'notifications_enabled', 'value': 'true', 'type': 'bool'},
      {'key': 'biometric_enabled', 'value': 'false', 'type': 'bool'},
      {'key': 'onboarding_completed', 'value': 'false', 'type': 'bool'},
      {'key': 'first_launch', 'value': 'true', 'type': 'bool'},
      {'key': 'verse_streak_count', 'value': '0', 'type': 'int'},
      {'key': 'last_verse_date', 'value': '0', 'type': 'int'},
      {
        'key': 'preferred_verse_themes',
        'value': '["hope", "strength", "comfort"]',
        'type': 'String'
      },
      {'key': 'chat_history_days', 'value': '30', 'type': 'int'},
      {'key': 'prayer_reminder_enabled', 'value': 'true', 'type': 'bool'},
      {'key': 'font_size_scale', 'value': '1.0', 'type': 'double'},
    ];

    for (final setting in defaultSettings) {
      await db.insert('user_settings', setting);
    }
  }

  Future<void> _insertVersePreferences(SqlJsDatabase db) async {
    final versePreferences = [
      {
        'preference_key': 'preferred_themes',
        'preference_value': 'faith,hope,love,peace,strength',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'preference_key': 'avoid_recent_days',
        'preference_value': '30',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'preference_key': 'preferred_version',
        'preference_value': 'WEB',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    for (final pref in versePreferences) {
      await db.insert('verse_preferences', pref);
    }
  }

  Future<void> _insertDefaultPrayerCategories(SqlJsDatabase db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final categories = [
      {
        'id': 'cat_family',
        'name': 'Family',
        'icon': '58387',
        'color': '0xFF4CAF50',
        'description': 'Prayers for family members',
        'display_order': 1,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
        'date_created': now,
        'date_modified': null,
      },
      {
        'id': 'cat_health',
        'name': 'Health',
        'icon': '59408',
        'color': '0xFFF44336',
        'description': 'Prayers for health and healing',
        'display_order': 2,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
        'date_created': now,
        'date_modified': null,
      },
      {
        'id': 'cat_work',
        'name': 'Work',
        'icon': '59641',
        'color': '0xFF2196F3',
        'description': 'Prayers for work and career',
        'display_order': 3,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
        'date_created': now,
        'date_modified': null,
      },
      {
        'id': 'cat_faith',
        'name': 'Faith',
        'icon': '57452',
        'color': '0xFF9C27B0',
        'description': 'Prayers for spiritual growth and faith',
        'display_order': 4,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
        'date_created': now,
        'date_modified': null,
      },
      {
        'id': 'cat_relationships',
        'name': 'Relationships',
        'icon': '59409',
        'color': '0xFFE91E63',
        'description': 'Prayers for relationships and friendships',
        'display_order': 5,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
        'date_created': now,
        'date_modified': null,
      },
      {
        'id': 'cat_guidance',
        'name': 'Guidance',
        'icon': '58733',
        'color': '0xFF673AB7',
        'description': 'Prayers for direction and wisdom',
        'display_order': 6,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
        'date_created': now,
        'date_modified': null,
      },
      {
        'id': 'cat_gratitude',
        'name': 'Gratitude',
        'icon': '60106',
        'color': '0xFFFFC107',
        'description': 'Prayers of thanksgiving and gratitude',
        'display_order': 7,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
        'date_created': now,
        'date_modified': null,
      },
      {
        'id': 'cat_other',
        'name': 'Other',
        'icon': '58835',
        'color': '0xFF9E9E9E',
        'description': 'Other prayer requests',
        'display_order': 8,
        'is_active': 1,
        'is_default': 1,
        'created_at': now,
        'date_created': now,
        'date_modified': null,
      },
    ];

    for (final category in categories) {
      await db.insert('prayer_categories', category);
    }
  }

  /// Close database
  @override
  Future<void> close() async {
    await SqlJsHelper.close();
    _database = null;
  }

  /// Delete database (clears IndexedDB storage)
  @override
  Future<void> deleteDatabase() async {
    // On web, this would require clearing IndexedDB
    // For now, just close and reset
    await close();
    _isInitialized = false;
  }

  /// Initialize (for compatibility)
  @override
  Future<void> initialize() async {
    await database;
  }

  /// Reset database
  @override
  Future<void> resetDatabase() async {
    await close();
    await deleteDatabase();
    await database;
  }
}
