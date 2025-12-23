import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';
import '../database/sql_js_helper.dart'; // Import custom ConflictAlgorithm

/// Service for loading reading plans from language-specific JSON files
class CuratedReadingPlanLoader {
  final DatabaseService _database;
  final _uuid = const Uuid();

  CuratedReadingPlanLoader(this._database);

  /// Load all reading plans (curated + book-based + generator-based) from JSON and insert into database
  /// [language] should be 'en' or 'es' to match the app's current language
  Future<void> loadAllPlans(String language) async {
    await loadCuratedPlans(language);
    await loadBookBasedPlans(language);
    await loadGeneratorBasedPlans(language);
  }

  /// Load curated thematic plans from JSON
  Future<void> loadCuratedPlans(String language) async {
    try {
      // Load language-specific JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/reading_plans/$language/curated_thematic_plans.json',
      );
      final List<dynamic> plansJson = json.decode(jsonString);

      // Process each plan
      for (final planData in plansJson) {
        await _insertPlanWithReadings(planData);
      }
    } catch (e) {
      throw Exception('Failed to load curated reading plans for $language: $e');
    }
  }

  /// Load book-based plans from JSON
  Future<void> loadBookBasedPlans(String language) async {
    try {
      // Load language-specific JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/reading_plans/$language/book_based_plans.json',
      );
      final List<dynamic> plansJson = json.decode(jsonString);

      // Process each plan (without readings - these are generated dynamically)
      for (final planData in plansJson) {
        await _insertBookBasedPlan(planData);
      }
    } catch (e) {
      throw Exception('Failed to load book-based reading plans for $language: $e');
    }
  }

  /// Load generator-based plans from JSON
  Future<void> loadGeneratorBasedPlans(String language) async {
    try {
      // Load language-specific JSON file from assets
      final jsonString = await rootBundle.loadString(
        'assets/reading_plans/$language/generator_based_plans.json',
      );
      final List<dynamic> plansJson = json.decode(jsonString);

      // Process each plan (without readings - these are generated dynamically by ReadingPlanGenerator)
      for (final planData in plansJson) {
        await _insertBookBasedPlan(planData);
      }
    } catch (e) {
      throw Exception('Failed to load generator-based reading plans for $language: $e');
    }
  }

  /// Insert a single plan and its daily readings
  Future<void> _insertPlanWithReadings(Map<String, dynamic> planData) async {
    final db = await _database.database;

    // Check if plan already exists
    final existing = await db.query(
      'reading_plans',
      where: 'id = ?',
      whereArgs: [planData['id']],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Plan already exists, skip insertion
      return;
    }

    // Insert the plan
    await db.insert(
      'reading_plans',
      {
        'id': planData['id'],
        'title': planData['title'],
        'description': planData['description'],
        'duration': planData['duration'],
        'category': planData['category'],
        'difficulty': planData['difficulty'],
        'estimated_time_per_day': planData['estimatedTimePerDay'],
        'total_readings': planData['totalReadings'],
        'completed_readings': 0,
        'is_started': 0,
        'start_date': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Insert daily readings
    final List<dynamic> readings = planData['readings'];
    for (final reading in readings) {
      await db.insert(
        'daily_readings',
        {
          'id': _uuid.v4(),
          'plan_id': planData['id'],
          'title': reading['title'],
          'description': reading['description'],
          'book': reading['book'],
          'chapters': reading['chapters'],
          'estimated_time': reading['estimatedTime'],
          'date': DateTime.now()
              .add(Duration(days: reading['day'] - 1))
              .millisecondsSinceEpoch,
          'is_completed': 0,
          'completed_date': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Check if curated plans have been loaded
  Future<bool> areCuratedPlansLoaded() async {
    final db = await _database.database;

    // Check if any of the curated plan IDs exist
    final curatedPlanIds = [
      'plan_30_days_grace',
      'plan_peace_anxiety',
      'plan_advent_journey',
      'plan_identity_christ',
    ];

    for (final planId in curatedPlanIds) {
      final result = await db.query(
        'reading_plans',
        where: 'id = ?',
        whereArgs: [planId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  /// Insert a book-based plan (without daily readings - generated dynamically)
  Future<void> _insertBookBasedPlan(Map<String, dynamic> planData) async {
    final db = await _database.database;

    // Check if plan already exists
    final existing = await db.query(
      'reading_plans',
      where: 'id = ?',
      whereArgs: [planData['id']],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // Plan already exists, skip insertion
      return;
    }

    // Insert the plan (readings are generated by reading plan generator)
    await db.insert(
      'reading_plans',
      {
        'id': planData['id'],
        'title': planData['title'],
        'description': planData['description'],
        'duration': planData['duration'],
        'category': planData['category'],
        'difficulty': planData['difficulty'],
        'estimated_time_per_day': planData['estimatedTimePerDay'],
        'total_readings': planData['totalReadings'],
        'completed_readings': 0,
        'is_started': 0,
        'start_date': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Load all plans if not already loaded (idempotent)
  /// [language] should be 'en' or 'es' to match the app's current language
  /// Handles language changes by reloading plans when language switches
  Future<void> ensureAllPlansLoaded(String language) async {
    final db = await _database.database;

    // Check if language has changed
    final currentLangResult = await db.query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: ['reading_plan_language'],
      limit: 1,
    );

    final currentLang = currentLangResult.isNotEmpty
        ? currentLangResult.first['value'] as String?
        : null;

    // If language changed, clear existing plans and reload
    if (currentLang != null && currentLang != language) {
      debugPrint('Language changed from $currentLang to $language, reloading reading plans...');
      // Delete daily_readings FIRST to avoid foreign key constraint violations
      await db.delete('daily_readings');
      await db.delete('reading_plans');
      await db.delete('app_metadata', where: 'key = ?', whereArgs: ['reading_plan_language']);
    }

    // Check if plans already exist for current language
    final alreadyLoaded = await arePlansLoaded();
    if (alreadyLoaded && currentLang == language) {
      debugPrint('Reading plans already loaded for $language, skipping content load');
      return;
    }

    debugPrint('Loading 13 reading plans from JSON files ($language)...');
    await loadAllPlans(language);

    // Store the current language in app_metadata
    await db.insert(
      'app_metadata',
      {'key': 'reading_plan_language', 'value': language},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Check if any reading plans have been loaded
  Future<bool> arePlansLoaded() async {
    final db = await _database.database;

    // Check if any of the known plan IDs exist
    final knownPlanIds = [
      // Curated thematic plans
      'plan_30_days_grace',
      'plan_peace_anxiety',
      'plan_advent_journey',
      'plan_identity_christ',
      // Book-based plans
      'plan_gospel_john',
      'plan_proverbs_month',
      'plan_psalms_prayer',
      // Generator-based plans
      'plan_new_testament',
      'plan_psalms_proverbs',
      'plan_gospels',
      'plan_one_year_bible',
      'plan_paul_letters',
      'plan_pentateuch',
    ];

    for (final planId in knownPlanIds) {
      final result = await db.query(
        'reading_plans',
        where: 'id = ?',
        whereArgs: [planId],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return true;
      }
    }

    return false;
  }
}
