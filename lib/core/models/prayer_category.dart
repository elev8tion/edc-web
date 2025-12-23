import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'prayer_category.freezed.dart';
part 'prayer_category.g.dart';

@freezed
class PrayerCategory with _$PrayerCategory {
  const factory PrayerCategory({
    required String id,
    required String name,
    required int iconCodePoint,
    required int colorValue,
    @Default(false) bool isDefault,
    @Default(true) bool isActive,
    @Default(0) int displayOrder,
    required DateTime dateCreated,
    DateTime? dateModified,
  }) = _PrayerCategory;

  factory PrayerCategory.fromJson(Map<String, dynamic> json) =>
      _$PrayerCategoryFromJson(json);
}

extension PrayerCategoryExtension on PrayerCategory {
  /// Get icon as IconData
  IconData get icon {
    // Create IconData directly from code point with explicit font family
    // This ensures icons render correctly on both iOS and Android
    return IconData(
      iconCodePoint,
      fontFamily: 'MaterialIcons',
      matchTextDirection: false,
    );
  }

  /// Get color as Color object
  Color get color => Color(colorValue);

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': iconCodePoint.toString(),
      'color': '0x${colorValue.toRadixString(16).toUpperCase()}',
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'display_order': displayOrder,
      'created_at': dateCreated.millisecondsSinceEpoch,
      'date_modified': dateModified?.millisecondsSinceEpoch,
    };
  }

  /// Create from database map
  static PrayerCategory fromMap(Map<String, dynamic> map) {
    return PrayerCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCodePoint: int.parse(map['icon'] as String),
      colorValue: int.parse((map['color'] as String).replaceFirst('0x', ''), radix: 16),
      isDefault: (map['is_default'] as int) == 1,
      isActive: (map['is_active'] as int) == 1,
      displayOrder: map['display_order'] as int,
      dateCreated: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      dateModified: map['date_modified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date_modified'] as int)
          : null,
    );
  }

  /// Copy with updated fields
  PrayerCategory copyWithMap({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isDefault,
    bool? isActive,
    int? displayOrder,
    DateTime? dateCreated,
    DateTime? dateModified,
  }) {
    return PrayerCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
    );
  }
}

/// Default category IDs
class DefaultCategoryIds {
  static const String family = 'cat_family';
  static const String health = 'cat_health';
  static const String work = 'cat_work';
  static const String ministry = 'cat_ministry';
  static const String thanksgiving = 'cat_thanksgiving';
  static const String intercession = 'cat_intercession';
  static const String finances = 'cat_finances';
  static const String relationships = 'cat_relationships';
  static const String guidance = 'cat_guidance';
  static const String protection = 'cat_protection';
  static const String general = 'cat_general';
}

/// Pre-defined category configurations
class CategoryPresets {
  static final List<Map<String, dynamic>> defaults = [
    {
      'id': DefaultCategoryIds.family,
      'name': 'Family',
      'icon': Icons.family_restroom.codePoint,
      'color': Colors.pink.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.health,
      'name': 'Health',
      'icon': Icons.favorite.codePoint,
      'color': Colors.red.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.work,
      'name': 'Work',
      'icon': Icons.work.codePoint,
      'color': Colors.blue.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.ministry,
      'name': 'Ministry',
      'icon': Icons.church.codePoint,
      'color': Colors.purple.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.thanksgiving,
      'name': 'Thanksgiving',
      'icon': Icons.celebration.codePoint,
      'color': Colors.amber.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.intercession,
      'name': 'Intercession',
      'icon': Icons.people.codePoint,
      'color': Colors.teal.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.finances,
      'name': 'Finances',
      'icon': Icons.attach_money.codePoint,
      'color': Colors.green.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.relationships,
      'name': 'Relationships',
      'icon': Icons.favorite_border.codePoint,
      'color': Colors.pinkAccent.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.guidance,
      'name': 'Guidance',
      'icon': Icons.explore.codePoint,
      'color': Colors.deepPurple.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.protection,
      'name': 'Protection',
      'icon': Icons.shield.codePoint,
      'color': Colors.brown.toARGB32(),
    },
    {
      'id': DefaultCategoryIds.general,
      'name': 'General',
      'icon': Icons.more_horiz.codePoint,
      'color': Colors.grey.toARGB32(),
    },
  ];

  /// Available icons for category customization
  static final List<IconData> availableIcons = [
    Icons.family_restroom,
    Icons.favorite,
    Icons.work,
    Icons.church,
    Icons.celebration,
    Icons.people,
    Icons.attach_money,
    Icons.favorite_border,
    Icons.explore,
    Icons.shield,
    Icons.more_horiz,
    Icons.school,
    Icons.home,
    Icons.business,
    Icons.local_hospital,
    Icons.flight,
    Icons.directions_car,
    Icons.pets,
    Icons.sports_basketball,
    Icons.music_note,
    Icons.star,
    Icons.light_mode,
    Icons.nightlight,
    Icons.spa,
    Icons.self_improvement,
  ];

  /// Available colors for category customization
  static final List<Color> availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
}

/// Category statistics model
class CategoryStatistics {
  final String categoryId;
  final String categoryName;
  final int totalPrayers;
  final int activePrayers;
  final int answeredPrayers;
  final int archivedPrayers;
  final double answerRate;
  final Color categoryColor;
  final IconData categoryIcon;

  const CategoryStatistics({
    required this.categoryId,
    required this.categoryName,
    required this.totalPrayers,
    required this.activePrayers,
    required this.answeredPrayers,
    required this.archivedPrayers,
    required this.answerRate,
    required this.categoryColor,
    required this.categoryIcon,
  });

  factory CategoryStatistics.fromCategory(
    PrayerCategory category, {
    required int total,
    required int active,
    required int answered,
    required int archived,
  }) {
    final rate = total > 0 ? (answered / total) * 100 : 0.0;
    return CategoryStatistics(
      categoryId: category.id,
      categoryName: category.name,
      totalPrayers: total,
      activePrayers: active,
      answeredPrayers: answered,
      archivedPrayers: archived,
      answerRate: rate,
      categoryColor: category.color,
      categoryIcon: category.icon,
    );
  }
}
