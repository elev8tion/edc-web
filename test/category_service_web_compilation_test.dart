import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/core/services/category_service.dart';
import 'package:everyday_christian/core/services/database_service.dart';
import 'package:everyday_christian/core/models/prayer_category.dart';

void main() {
  group('CategoryService Web Compilation Tests', () {
    test('Service instantiates with DatabaseService dependency', () {
      final dbService = DatabaseService();
      expect(() => CategoryService(dbService), returnsNormally);
    });

    test('All public methods compile', () {
      final dbService = DatabaseService();
      final service = CategoryService(dbService);

      // Category retrieval
      expect(service.getActiveCategories, isA<Function>());
      expect(service.getAllCategories, isA<Function>());
      expect(service.getCategoryById, isA<Function>());
      expect(service.getCategoryByName, isA<Function>());

      // Category CRUD
      expect(service.createCategory, isA<Function>());
      expect(service.updateCategory, isA<Function>());
      expect(service.deleteCategory, isA<Function>());
      expect(service.toggleCategoryActive, isA<Function>());

      // Category organization
      expect(service.reorderCategories, isA<Function>());

      // Statistics
      expect(service.getCategoryStatistics, isA<Function>());
      expect(service.getAllCategoryStatistics, isA<Function>());
      expect(service.getCategoryUsageCount, isA<Function>());

      // Utility
      expect(service.resetToDefaults, isA<Function>());
      expect(service.getCustomCategoryCount, isA<Function>());
      expect(service.isCategoryNameAvailable, isA<Function>());
    });

    test('PrayerCategory model compilation', () {
      final category = PrayerCategory(
        id: 'cat1',
        name: 'Test Category',
        iconCodePoint: Icons.favorite.codePoint,
        colorValue: Colors.blue.value,
        isDefault: false,
        isActive: true,
        displayOrder: 1,
        dateCreated: DateTime.now(),
      );

      expect(category.id, 'cat1');
      expect(category.name, 'Test Category');
      expect(category.isDefault, false);
      expect(category.isActive, true);
    });

    test('PrayerCategory icon extension', () {
      final category = PrayerCategory(
        id: 'cat1',
        name: 'Test',
        iconCodePoint: Icons.favorite.codePoint,
        colorValue: Colors.red.value,
        dateCreated: DateTime.now(),
      );

      // Test icon getter
      final icon = category.icon;
      expect(icon, isA<IconData>());
      expect(icon.codePoint, Icons.favorite.codePoint);
    });

    test('PrayerCategory color extension', () {
      final category = PrayerCategory(
        id: 'cat1',
        name: 'Test',
        iconCodePoint: Icons.favorite.codePoint,
        colorValue: Colors.blue.value,
        dateCreated: DateTime.now(),
      );

      // Test color getter
      final color = category.color;
      expect(color, isA<Color>());
      expect(color.value, Colors.blue.value);
    });

    test('PrayerCategory toMap serialization', () {
      final category = PrayerCategory(
        id: 'cat1',
        name: 'Test',
        iconCodePoint: Icons.star.codePoint,
        colorValue: Colors.purple.value,
        isDefault: true,
        isActive: true,
        displayOrder: 5,
        dateCreated: DateTime.now(),
      );

      final map = category.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map['id'], 'cat1');
      expect(map['name'], 'Test');
      expect(map['is_default'], 1);
      expect(map['is_active'], 1);
      expect(map['display_order'], 5);
    });

    test('PrayerCategory fromMap deserialization', () {
      final now = DateTime.now();
      final map = {
        'id': 'cat1',
        'name': 'Test Category',
        'icon': Icons.favorite.codePoint.toString(),
        'color': '0x${Colors.red.value.toRadixString(16).toUpperCase()}',
        'is_default': 1,
        'is_active': 0,
        'display_order': 3,
        'created_at': now.millisecondsSinceEpoch,
        'date_modified': null,
      };

      final category = PrayerCategoryExtension.fromMap(map);
      expect(category.id, 'cat1');
      expect(category.name, 'Test Category');
      expect(category.isDefault, true);
      expect(category.isActive, false);
      expect(category.displayOrder, 3);
    });

    test('PrayerCategory copyWithMap', () {
      final original = PrayerCategory(
        id: 'cat1',
        name: 'Original',
        iconCodePoint: Icons.star.codePoint,
        colorValue: Colors.blue.value,
        dateCreated: DateTime.now(),
      );

      final modified = original.copyWithMap(
        name: 'Modified',
        isActive: false,
      );

      expect(modified.name, 'Modified');
      expect(modified.isActive, false);
      expect(modified.id, original.id);
      expect(modified.iconCodePoint, original.iconCodePoint);
    });

    test('DefaultCategoryIds constants', () {
      expect(DefaultCategoryIds.family, 'cat_family');
      expect(DefaultCategoryIds.health, 'cat_health');
      expect(DefaultCategoryIds.work, 'cat_work');
      expect(DefaultCategoryIds.ministry, 'cat_ministry');
      expect(DefaultCategoryIds.thanksgiving, 'cat_thanksgiving');
      expect(DefaultCategoryIds.intercession, 'cat_intercession');
      expect(DefaultCategoryIds.finances, 'cat_finances');
      expect(DefaultCategoryIds.relationships, 'cat_relationships');
      expect(DefaultCategoryIds.guidance, 'cat_guidance');
      expect(DefaultCategoryIds.protection, 'cat_protection');
      expect(DefaultCategoryIds.general, 'cat_general');
    });

    test('CategoryPresets defaults list', () {
      final defaults = CategoryPresets.defaults;
      expect(defaults, isA<List<Map<String, dynamic>>>());
      expect(defaults.length, 11); // 11 default categories

      final firstCategory = defaults.first;
      expect(firstCategory['id'], isA<String>());
      expect(firstCategory['name'], isA<String>());
      expect(firstCategory['icon'], isA<int>());
      expect(firstCategory['color'], isA<int>());
    });

    test('CategoryPresets availableIcons', () {
      final icons = CategoryPresets.availableIcons;
      expect(icons, isA<List<IconData>>());
      expect(icons.length, greaterThan(0));
      expect(icons.first, isA<IconData>());
    });

    test('CategoryPresets availableColors', () {
      final colors = CategoryPresets.availableColors;
      expect(colors, isA<List<Color>>());
      expect(colors.length, greaterThan(0));
      expect(colors.first, isA<Color>());
    });

    test('CategoryStatistics model compilation', () {
      final stats = CategoryStatistics(
        categoryId: 'cat1',
        categoryName: 'Test',
        totalPrayers: 100,
        activePrayers: 50,
        answeredPrayers: 30,
        archivedPrayers: 20,
        answerRate: 30.0,
        categoryColor: Colors.blue,
        categoryIcon: Icons.star,
      );

      expect(stats.categoryId, 'cat1');
      expect(stats.totalPrayers, 100);
      expect(stats.answerRate, 30.0);
    });

    test('CategoryStatistics fromCategory factory', () {
      final category = PrayerCategory(
        id: 'cat1',
        name: 'Test',
        iconCodePoint: Icons.favorite.codePoint,
        colorValue: Colors.red.value,
        dateCreated: DateTime.now(),
      );

      final stats = CategoryStatistics.fromCategory(
        category,
        total: 50,
        active: 30,
        answered: 15,
        archived: 5,
      );

      expect(stats.categoryId, category.id);
      expect(stats.categoryName, category.name);
      expect(stats.totalPrayers, 50);
      expect(stats.activePrayers, 30);
      expect(stats.answeredPrayers, 15);
      expect(stats.answerRate, 30.0); // 15/50 * 100
    });

    test('PrayerCategory JSON serialization', () {
      final category = PrayerCategory(
        id: 'cat1',
        name: 'Test',
        iconCodePoint: Icons.star.codePoint,
        colorValue: Colors.blue.value,
        dateCreated: DateTime.now(),
      );

      // toJson
      final json = category.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], 'cat1');

      // fromJson
      final reconstructed = PrayerCategory.fromJson(json);
      expect(reconstructed.id, category.id);
      expect(reconstructed.name, category.name);
    });
  });
}
