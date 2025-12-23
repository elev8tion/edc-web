import 'package:uuid/uuid.dart';
import '../models/prayer_category.dart';
import 'database_service.dart';

class CategoryService {
  final DatabaseService _database;
  final Uuid _uuid = const Uuid();

  CategoryService(this._database);

  /// Get all active categories ordered by display_order
  Future<List<PrayerCategory>> getActiveCategories() async {
    final db = await _database.database;
    final maps = await db.query(
      'prayer_categories',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'display_order ASC, name ASC',
    );

    return maps.map((map) => PrayerCategoryExtension.fromMap(map)).toList();
  }

  /// Get all categories (including inactive)
  Future<List<PrayerCategory>> getAllCategories() async {
    final db = await _database.database;
    final maps = await db.query(
      'prayer_categories',
      orderBy: 'display_order ASC, name ASC',
    );

    return maps.map((map) => PrayerCategoryExtension.fromMap(map)).toList();
  }

  /// Get category by ID
  Future<PrayerCategory?> getCategoryById(String id) async {
    final db = await _database.database;
    final maps = await db.query(
      'prayer_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PrayerCategoryExtension.fromMap(maps.first);
  }

  /// Get category by name
  Future<PrayerCategory?> getCategoryByName(String name) async {
    final db = await _database.database;
    final maps = await db.query(
      'prayer_categories',
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [name],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return PrayerCategoryExtension.fromMap(maps.first);
  }

  /// Create new custom category
  Future<PrayerCategory> createCategory({
    required String name,
    required int iconCodePoint,
    required int colorValue,
  }) async {
    // Check if category with same name already exists
    final existing = await getCategoryByName(name);
    if (existing != null) {
      throw Exception('Category with name "$name" already exists');
    }

    final db = await _database.database;

    // Get the next display order
    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(display_order) as max_order FROM prayer_categories',
    );
    final nextOrder = ((maxOrderResult.first['max_order'] as int?) ?? 0) + 1;

    final category = PrayerCategory(
      id: 'cat_${_uuid.v4()}',
      name: name,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      isDefault: false,
      isActive: true,
      displayOrder: nextOrder,
      dateCreated: DateTime.now(),
    );

    await db.insert('prayer_categories', category.toMap());

    return category;
  }

  /// Update existing category
  Future<void> updateCategory(PrayerCategory category) async {
    final db = await _database.database;

    // Check if we're trying to rename to an existing category name
    if (category.dateModified != null) {
      final existing = await getCategoryByName(category.name);
      if (existing != null && existing.id != category.id) {
        throw Exception('Category with name "${category.name}" already exists');
      }
    }

    final updatedCategory = category.copyWithMap(
      dateModified: DateTime.now(),
    );

    await db.update(
      'prayer_categories',
      updatedCategory.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Delete custom category (default categories cannot be deleted)
  Future<void> deleteCategory(String id) async {
    final category = await getCategoryById(id);
    if (category == null) {
      throw Exception('Category not found');
    }

    if (category.isDefault) {
      throw Exception('Cannot delete default categories');
    }

    final db = await _database.database;

    // Check if category is in use
    final prayersUsingCategory = await db.query(
      'prayer_requests',
      where: 'category = ?',
      whereArgs: [category.id],
      limit: 1,
    );

    if (prayersUsingCategory.isNotEmpty) {
      throw Exception(
        'Cannot delete category "${category.name}" because it is being used by prayer requests. '
        'Please reassign or delete those prayers first.',
      );
    }

    await db.delete(
      'prayer_categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deactivate/activate category
  Future<void> toggleCategoryActive(String id) async {
    final category = await getCategoryById(id);
    if (category == null) {
      throw Exception('Category not found');
    }

    final db = await _database.database;
    await db.update(
      'prayer_categories',
      {
        'is_active': category.isActive ? 0 : 1,
        'date_modified': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reorder categories
  Future<void> reorderCategories(List<String> categoryIds) async {
    final db = await _database.database;

    await db.transaction((txn) async {
      for (var i = 0; i < categoryIds.length; i++) {
        await txn.update(
          'prayer_categories',
          {
            'display_order': i,
            'date_modified': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [categoryIds[i]],
        );
      }
    });
  }

  /// Get category statistics
  Future<CategoryStatistics> getCategoryStatistics(String categoryId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) {
      throw Exception('Category not found');
    }

    final db = await _database.database;

    // Get total prayers for this category
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_requests WHERE category = ?',
      [category.id],
    );
    final total = (totalResult.first['count'] as int?) ?? 0;

    // Get active prayers
    final activeResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_requests WHERE category = ? AND is_answered = 0',
      [category.id],
    );
    final active = (activeResult.first['count'] as int?) ?? 0;

    // Get answered prayers
    final answeredResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_requests WHERE category = ? AND is_answered = 1',
      [category.id],
    );
    final answered = (answeredResult.first['count'] as int?) ?? 0;

    // For archived, we'll use 0 for now (as the current schema doesn't have archived status)
    const archived = 0;

    return CategoryStatistics.fromCategory(
      category,
      total: total,
      active: active,
      answered: answered,
      archived: archived,
    );
  }

  /// Get all category statistics
  Future<List<CategoryStatistics>> getAllCategoryStatistics() async {
    final categories = await getActiveCategories();
    final List<CategoryStatistics> stats = [];

    for (final category in categories) {
      try {
        final stat = await getCategoryStatistics(category.id);
        stats.add(stat);
      } catch (e) {
        // Skip categories that cause errors
        continue;
      }
    }

    return stats;
  }

  /// Get category usage count (number of prayers using this category)
  Future<int> getCategoryUsageCount(String categoryId) async {
    final category = await getCategoryById(categoryId);
    if (category == null) return 0;

    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_requests WHERE category = ?',
      [category.id],
    );

    return (result.first['count'] as int?) ?? 0;
  }

  /// Reset to default categories (delete all custom categories)
  Future<void> resetToDefaults() async {
    final db = await _database.database;

    await db.delete(
      'prayer_categories',
      where: 'is_default = ?',
      whereArgs: [0],
    );

    // Reset display order for default categories
    final categories = await getActiveCategories();
    await reorderCategories(categories.map((c) => c.id).toList());
  }

  /// Get count of custom categories
  Future<int> getCustomCategoryCount() async {
    final db = await _database.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM prayer_categories WHERE is_default = 0',
    );

    return (result.first['count'] as int?) ?? 0;
  }

  /// Check if category name is available
  Future<bool> isCategoryNameAvailable(String name, {String? excludeId}) async {
    final existing = await getCategoryByName(name);
    if (existing == null) return true;
    if (excludeId != null && existing.id == excludeId) return true;
    return false;
  }
}
