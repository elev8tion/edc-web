import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' hide ConflictAlgorithm;
import 'package:uuid/uuid.dart';
import '../core/database/database_helper.dart';
import '../models/bible_verse.dart';
import '../models/shared_verse_entry.dart';
import '../core/services/achievement_service.dart';

/// Unified service for managing Bible verses with FTS5 search, bookmarks, and themes
class UnifiedVerseService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();
  final AchievementService? _achievementService;

  UnifiedVerseService({AchievementService? achievementService})
      : _achievementService = achievementService;

  // ============================================================================
  // SEARCH METHODS
  // ============================================================================

  /// Search verses by text content using FTS5 full-text search
  Future<List<BibleVerse>> searchVerses(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];

    try {
      final database = await _db.database;

      // Use FTS5 for full-text search with ranking + randomization (with timeout)
      final results = await database.rawQuery('''
        SELECT v.id, v.book, v.chapter, v.verse as verse_number, v.text,
               v.version as translation, v.language, v.themes, v.category, v.reference,
               snippet(bible_verses_fts, 0, '<mark>', '</mark>', '...', 32) as snippet,
               rank
        FROM bible_verses_fts
        JOIN bible_verses v ON bible_verses_fts.rowid = v.id
        WHERE bible_verses_fts MATCH ?
        ORDER BY rank, RANDOM()
        LIMIT ?
      ''', [query, limit]).timeout(
        const Duration(seconds: 10),
        onTimeout: () => [],
      );

      // Get favorite verse IDs to mark them
      final favoriteIds = await _getFavoriteVerseIds();

      return List<BibleVerse>.from(results.map((map) {
        final isFavorite = favoriteIds.contains(map['id']);
        return BibleVerse.fromMap(map, isFavorite: isFavorite);
      }));
    } catch (e) {
      // Fallback to LIKE search if FTS fails
      return _fallbackSearch(query, limit);
    }
  }

  /// Fallback search using LIKE operator
  Future<List<BibleVerse>> _fallbackSearch(String query, int limit) async {
    final database = await _db.database;

    final results = await database.rawQuery('''
      SELECT id, book, chapter, verse as verse_number, text,
             version as translation, language, themes, category, reference
      FROM bible_verses
      WHERE text LIKE ? OR book LIKE ? OR language LIKE ?
      ORDER BY
        CASE
          WHEN text LIKE ? THEN 1
          WHEN book LIKE ? THEN 2
          ELSE 3
        END
      LIMIT ?
    ''', [
      '%$query%', '%$query%', '%$query%',
      '%$query%', '%$query%',
      limit
    ]);

    final favoriteIds = await _getFavoriteVerseIds();

    return List<BibleVerse>.from(results.map((map) {
      final isFavorite = favoriteIds.contains(map['id']);
      return BibleVerse.fromMap(map, isFavorite: isFavorite);
    }));
  }

  /// Search verses by theme
  Future<List<BibleVerse>> searchByTheme(String theme, {int limit = 20}) async {
    debugPrint('🔍 [searchByTheme] Called with theme: "$theme", limit: $limit');
    final database = await _db.database;

    // Search in themes JSON array or category field
    final results = await database.rawQuery('''
      SELECT id, book, chapter, verse as verse_number, text,
             version as translation, language, themes, category, reference
      FROM bible_verses
      WHERE themes LIKE ? OR category LIKE ? OR text LIKE ?
      ORDER BY RANDOM()
      LIMIT ?
    ''', ['%"${theme.toLowerCase()}"%', '%${theme.toLowerCase()}%', '%$theme%', limit]);

    debugPrint('🔍 [searchByTheme] Found ${results.length} verses for theme "$theme"');
    if (results.isNotEmpty) {
      // Log first 2 verses for verification
      for (int i = 0; i < results.length && i < 2; i++) {
        debugPrint('  📖 Verse ${i + 1}: ${results[i]['reference']} - ${results[i]['text']?.toString().substring(0, 50)}...');
      }
    }

    final favoriteIds = await _getFavoriteVerseIds();

    return List<BibleVerse>.from(results.map((map) {
      final isFavorite = favoriteIds.contains(map['id']);
      return BibleVerse.fromMap(map, isFavorite: isFavorite);
    }));
  }

  /// Get all verses (with pagination)
  Future<List<BibleVerse>> getAllVerses({int? limit, int? offset}) async {
    final database = await _db.database;

    String query = 'SELECT id, book, chapter, verse as verse_number, text, version as translation, language, themes, category, reference FROM bible_verses ORDER BY book, chapter, verse';
    if (limit != null) {
      query += ' LIMIT $limit';
      if (offset != null) {
        query += ' OFFSET $offset';
      }
    }

    final results = await database.rawQuery(query);
    final favoriteIds = await _getFavoriteVerseIds();

    return List<BibleVerse>.from(results.map((map) {
      final isFavorite = favoriteIds.contains(map['id']);
      return BibleVerse.fromMap(map, isFavorite: isFavorite);
    }));
  }

  /// Get verse by exact reference (e.g., "John 3:16")
  Future<BibleVerse?> getVerseByReference(String reference) async {
    final database = await _db.database;

    // Parse reference
    final parts = reference.split(' ');
    if (parts.length < 2) return null;

    final book = parts.sublist(0, parts.length - 1).join(' ');
    final chapterVerse = parts.last.split(':');
    if (chapterVerse.length != 2) return null;

    final chapter = int.tryParse(chapterVerse[0]);
    final verse = int.tryParse(chapterVerse[1]);

    if (chapter == null || verse == null) return null;

    final results = await database.query(
      'bible_verses',
      where: 'book = ? AND chapter = ? AND verse = ?',
      whereArgs: [book, chapter, verse],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final favoriteIds = await _getFavoriteVerseIds();
    final isFavorite = favoriteIds.contains(results.first['id']);

    return BibleVerse.fromMap(results.first, isFavorite: isFavorite);
  }

  /// Get shared verse history
  Future<List<SharedVerseEntry>> getSharedVerses({int limit = 100}) async {
    final database = await _db.database;

    final results = await database.query(
      'shared_verses',
      orderBy: 'shared_at DESC',
      limit: limit,
    );

    return List<SharedVerseEntry>.from(results.map(SharedVerseEntry.fromMap));
  }

  /// Count of shared verses
  Future<int> getSharedVerseCount() async {
    final database = await _db.database;
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM shared_verses'),
    );
    return count ?? 0;
  }

  /// Record that a verse has been shared
  Future<void> recordSharedVerse(
    BibleVerse verse, {
    String channel = 'share_sheet',
  }) async {
    final database = await _db.database;

    await database.insert(
      'shared_verses',
      {
        'id': _uuid.v4(),
        'verse_id': verse.id,
        'book': verse.book,
        'chapter': verse.chapter,
        'verse_number': verse.verseNumber,
        'reference': verse.reference,
        'translation': verse.translation,
        'text': verse.text,
        'themes': jsonEncode(verse.themes),
        'channel': channel,
        'shared_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Check for sharing achievements (counts ALL share types)
    if (_achievementService != null) {
      await _achievementService.checkAllSharesAchievement();
    }
  }

  /// Remove a single shared verse entry
  Future<void> deleteSharedVerse(String id) async {
    final database = await _db.database;
    await database.delete(
      'shared_verses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all shared verse history
  Future<void> clearSharedVerses() async {
    final database = await _db.database;
    await database.delete('shared_verses');
  }

  // ============================================================================
  // FAVORITE/BOOKMARK METHODS
  // ============================================================================

  /// Get all favorite verses
  Future<List<BibleVerse>> getFavoriteVerses() async {
    final database = await _db.database;

    final results = await database.rawQuery('''
      SELECT v.id, v.book, v.chapter, v.verse as verse_number, v.text,
             v.version as translation, v.language, v.themes, v.category, v.reference,
             fv.date_added, fv.note, fv.tags
      FROM bible_verses v
      JOIN favorite_verses fv ON v.id = fv.verse_id
      ORDER BY fv.date_added DESC
    ''');

    return List<BibleVerse>.from(results.map((map) => BibleVerse.fromMap(map, isFavorite: true)));
  }

  /// Count of favorite verses
  Future<int> getFavoriteVerseCount() async {
    final database = await _db.database;
    final count = Sqflite.firstIntValue(
      await database.rawQuery('SELECT COUNT(*) FROM favorite_verses'),
    );
    return count ?? 0;
  }

  /// Add verse to favorites
  Future<void> addToFavorites(int verseId, {String? note, String? text, String? reference, String? category}) async {
    final database = await _db.database;

    // Get verse details if not provided
    String verseText = text ?? '';
    String verseReference = reference ?? '';
    String verseCategory = category ?? 'general';

    if (text == null || reference == null) {
      final verseResults = await database.query(
        'bible_verses',
        where: 'id = ?',
        whereArgs: [verseId],
        limit: 1,
      );

      if (verseResults.isNotEmpty) {
        final verseData = verseResults.first;
        verseText = verseData['text'] as String? ?? '';
        verseReference = verseData['reference'] as String? ??
            '${verseData['book']} ${verseData['chapter']}:${verseData['verse']}';
        verseCategory = verseData['category'] as String? ?? 'general';
      }
    }

    await database.insert(
      'favorite_verses',
      {
        'id': '${verseId}_${DateTime.now().millisecondsSinceEpoch}',
        'verse_id': verseId,
        'text': verseText,
        'reference': verseReference,
        'category': verseCategory,
        'note': note,
        'tags': null, // Keep field in database but always set to null
        'date_added': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Check for Curator achievement (100 saved verses)
    await _checkVerseAchievements();
  }

  /// Check verse-based achievements after saving a verse
  Future<void> _checkVerseAchievements() async {
    if (_achievementService == null) return;

    try {
      // Check Curator (100 saved verses)
      final totalSaved = await getFavoriteVerseCount();
      if (totalSaved >= 100) {
        final completionCount = await _achievementService.getCompletionCount(AchievementType.curator);
        // Only record if not already completed at this verse count level
        if (completionCount == 0 || totalSaved >= (completionCount + 1) * 100) {
          await _achievementService.recordCompletion(
            type: AchievementType.curator,
            progressValue: totalSaved,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to check verse achievements: $e');
    }
  }

  /// Remove verse from favorites
  Future<void> removeFromFavorites(int verseId) async {
    final database = await _db.database;

    await database.delete(
      'favorite_verses',
      where: 'verse_id = ?',
      whereArgs: [verseId],
    );
  }

  /// Remove all favorite verses.
  Future<void> clearFavoriteVerses() async {
    final database = await _db.database;
    await database.delete('favorite_verses');
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(int verseId) async {
    final isFavorite = await isVerseFavorite(verseId);

    if (isFavorite) {
      await removeFromFavorites(verseId);
      return false;
    } else {
      await addToFavorites(verseId);
      return true;
    }
  }

  /// Check if verse is in favorites
  Future<bool> isVerseFavorite(int verseId) async {
    final database = await _db.database;

    final results = await database.query(
      'favorite_verses',
      where: 'verse_id = ?',
      whereArgs: [verseId],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  /// Get favorite verse IDs (for efficient lookup)
  Future<Set<int>> _getFavoriteVerseIds() async {
    final database = await _db.database;

    final results = await database.query(
      'favorite_verses',
      columns: ['verse_id'],
    );

    return results
        .map((row) {
          final id = row['verse_id'];
          if (id == null) return null;
          // Handle SQLite returning num type
          return id is int ? id : (id as num).toInt();
        })
        .whereType<int>()
        .toSet();
  }

  /// Update favorite note or tags
  Future<void> updateFavorite(int verseId, {String? note, List<String>? tags}) async {
    final database = await _db.database;

    final Map<String, dynamic> updates = {};
    if (note != null) updates['note'] = note;
    if (tags != null) updates['tags'] = jsonEncode(tags);

    if (updates.isNotEmpty) {
      await database.update(
        'favorite_verses',
        updates,
        where: 'verse_id = ?',
        whereArgs: [verseId],
      );
    }
  }

  // ============================================================================
  // THEME AND CATEGORY METHODS
  // ============================================================================

  /// Get all available themes from verses
  Future<List<String>> getAllThemes() async {
    // Return curated list of biblical themes for verse filtering
    // These align with common Christian spiritual needs and situations
    return [
      'Faith',
      'Hope',
      'Love',
      'Peace',
      'Strength',
      'Comfort',
      'Courage',
      'Wisdom',
      'Forgiveness',
      'Grace',
      'Joy',
      'Trust',
      'Healing',
      'Protection',
      'Guidance',
      'Patience',
      'Perseverance',
      'Salvation',
      'Prayer',
      'Praise',
      'Thanksgiving',
      'Redemption',
      'Victory',
      'Rest',
      'Blessing',
    ];
  }

  /// Get verses for specific situation/emotion
  Future<List<BibleVerse>> getVersesForSituation(String situation, {int limit = 10}) async {
    // Map common situations to themes
    final situationThemes = {
      'anxiety': ['peace', 'comfort', 'trust'],
      'depression': ['hope', 'comfort', 'strength'],
      'fear': ['courage', 'strength', 'protection'],
      'loneliness': ['comfort', 'presence', 'love'],
      'doubt': ['faith', 'trust', 'assurance'],
      'anger': ['peace', 'forgiveness', 'patience'],
      'grief': ['comfort', 'hope', 'healing'],
      'stress': ['peace', 'rest', 'trust'],
      'guilt': ['forgiveness', 'grace', 'redemption'],
      'purpose': ['purpose', 'identity', 'calling'],
      'relationships': ['love', 'forgiveness', 'unity'],
      'finances': ['provision', 'trust', 'contentment'],
      'health': ['healing', 'strength', 'peace'],
      'work': ['purpose', 'diligence', 'integrity'],
      'decisions': ['wisdom', 'guidance', 'discernment'],
    };

    final themes = situationThemes[situation.toLowerCase()] ?? [situation];
    final database = await _db.database;

    final results = await database.rawQuery('''
      SELECT id, book, chapter, verse as verse_number, text,
             version as translation, language, themes, category, reference
      FROM bible_verses
      WHERE text LIKE ?
      ORDER BY RANDOM()
      LIMIT ?
    ''', ['%${themes.first}%', limit]);

    final favoriteIds = await _getFavoriteVerseIds();

    return List<BibleVerse>.from(results.map((map) {
      final isFavorite = favoriteIds.contains(map['id']);
      return BibleVerse.fromMap(map, isFavorite: isFavorite);
    }));
  }

  /// Get random daily verse
  Future<BibleVerse?> getDailyVerse({String? preferredTheme}) async {
    final database = await _db.database;

    String query = 'SELECT id, book, chapter, verse as verse_number, text, version as translation, language, themes, category, reference FROM bible_verses';
    List<dynamic> args = [];

    if (preferredTheme != null && preferredTheme.isNotEmpty) {
      query += ' WHERE text LIKE ?';
      args.add('%$preferredTheme%');
    }

    query += ' ORDER BY RANDOM() LIMIT 1';

    final results = await database.rawQuery(query, args);
    if (results.isEmpty) return null;

    final favoriteIds = await _getFavoriteVerseIds();
    final isFavorite = favoriteIds.contains(results.first['id']);

    return BibleVerse.fromMap(results.first, isFavorite: isFavorite);
  }

  // ============================================================================
  // STATISTICS METHODS
  // ============================================================================

  /// Get verse statistics
  Future<Map<String, dynamic>> getVerseStats() async {
    final database = await _db.database;

    final totalCount = await database.rawQuery('SELECT COUNT(*) as count FROM bible_verses');
    final favoriteCount = await database.rawQuery('SELECT COUNT(*) as count FROM favorite_verses');

    return {
      'total_verses': totalCount.first['count'],
      'favorite_verses': favoriteCount.first['count'],
      'popular_themes': [],
    };
  }

  // ============================================================================
  // PREFERENCES METHODS
  // ============================================================================

  /// Update preferred themes for verse selection
  Future<void> updatePreferredThemes(List<String> themes) async {
    final database = await _db.database;
    final themesValue = themes.join(',');

    await database.insert(
      'verse_preferences',
      {
        'preference_key': 'preferred_themes',
        'preference_value': themesValue,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update number of days to avoid recently shown verses
  Future<void> updateAvoidRecentDays(int days) async {
    final database = await _db.database;

    await database.insert(
      'verse_preferences',
      {
        'preference_key': 'avoid_recent_days',
        'preference_value': days.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update preferred Bible version
  Future<void> updatePreferredVersion(String version) async {
    final database = await _db.database;

    await database.insert(
      'verse_preferences',
      {
        'preference_key': 'preferred_version',
        'preference_value': version,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
