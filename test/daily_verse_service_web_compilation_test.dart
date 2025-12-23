import 'package:flutter_test/flutter_test.dart';
import 'package:everyday_christian/services/daily_verse_service.dart';
import 'package:everyday_christian/models/bible_verse.dart';

void main() {
  group('DailyVerseService Web Compilation Tests', () {
    test('Service instantiates as singleton', () {
      final instance1 = DailyVerseService();
      final instance2 = DailyVerseService();

      // Should return same instance (singleton pattern)
      expect(identical(instance1, instance2), true);
    });

    test('All public methods compile', () {
      final service = DailyVerseService();

      // Core functionality
      expect(service.initialize, isA<Function>());
      expect(service.getDailyVerse, isA<Function>());
      expect(service.refreshDailyVerse, isA<Function>());
      expect(service.checkAndUpdateVerse, isA<Function>());
      expect(service.clearCache, isA<Function>());
    });

    test('Service methods accept translation parameter', () {
      final service = DailyVerseService();

      // Test that methods accept optional translation parameter
      expect(
        () => service.getDailyVerse(forceRefresh: false, translation: 'WEB'),
        returnsNormally,
      );

      expect(
        () => service.refreshDailyVerse(translation: 'RVR1909'),
        returnsNormally,
      );

      expect(
        () => service.checkAndUpdateVerse(translation: 'WEB'),
        returnsNormally,
      );
    });

    test('Service methods accept forceRefresh parameter', () {
      final service = DailyVerseService();

      expect(
        () => service.getDailyVerse(forceRefresh: true),
        returnsNormally,
      );

      expect(
        () => service.getDailyVerse(forceRefresh: false),
        returnsNormally,
      );
    });

    test('BibleVerse model serialization', () {
      final verse = BibleVerse(
        text: 'For God so loved the world...',
        reference: 'John 3:16',
        book: 'John',
        chapter: 3,
        verseNumber: 16,
        translation: 'WEB',
        themes: ['love', 'salvation'],
        category: 'gospel',
      );

      expect(verse.text, 'For God so loved the world...');
      expect(verse.reference, 'John 3:16');
      expect(verse.book, 'John');
      expect(verse.chapter, 3);
      expect(verse.verseNumber, 16);
      expect(verse.translation, 'WEB');
    });

    test('BibleVerse fromMap factory', () {
      final map = {
        'id': 1,
        'text': 'Test verse text',
        'reference': 'Genesis 1:1',
        'book': 'Genesis',
        'chapter': 1,
        'verse_number': 1,
        'translation': 'WEB',
        'themes': '["creation","beginning"]',
        'category': 'law',
      };

      final verse = BibleVerse.fromMap(map);
      expect(verse.text, 'Test verse text');
      expect(verse.reference, 'Genesis 1:1');
      expect(verse.book, 'Genesis');
      expect(verse.chapter, 1);
      expect(verse.verseNumber, 1);
      expect(verse.translation, 'WEB');
      expect(verse.id, 1);
    });

    test('BibleVerse minimal fromMap for cached verses', () {
      // Test minimal map creation (as used in DailyVerseService cache)
      final minimalMap = {
        'id': null,
        'text': 'Cached verse',
        'reference': 'Psalm 23:1',
        'book': '',
        'chapter': 0,
        'verse_number': 0,
        'translation': 'WEB',
        'themes': '[]',
        'category': 'general',
      };

      final verse = BibleVerse.fromMap(minimalMap);
      expect(verse.text, 'Cached verse');
      expect(verse.reference, 'Psalm 23:1');
      expect(verse.translation, 'WEB');
    });

    test('Service singleton pattern verification', () {
      // Create multiple references
      final service1 = DailyVerseService();
      final service2 = DailyVerseService();
      final service3 = DailyVerseService();

      // All should be the same instance
      expect(identical(service1, service2), true);
      expect(identical(service2, service3), true);
      expect(identical(service1, service3), true);
    });

    test('SharedPreferences key constants exist', () {
      // These are private constants, but we verify the class compiles
      // with them by instantiating the service
      expect(() => DailyVerseService(), returnsNormally);
    });

    test('BibleVerse themes field handles JSON array', () {
      final map = {
        'id': 1,
        'text': 'Test',
        'reference': 'Test 1:1',
        'book': 'Test',
        'chapter': 1,
        'verse_number': 1,
        'translation': 'WEB',
        'themes': '["faith","hope","love"]',
        'category': 'general',
      };

      final verse = BibleVerse.fromMap(map);
      expect(verse.themes, isA<List>());
      expect(verse.themes.length, 3);
      expect(verse.themes.contains('faith'), true);
    });

    test('BibleVerse handles empty themes array', () {
      final map = {
        'id': 1,
        'text': 'Test',
        'reference': 'Test 1:1',
        'book': 'Test',
        'chapter': 1,
        'verse_number': 1,
        'translation': 'WEB',
        'themes': '[]',
        'category': 'general',
      };

      final verse = BibleVerse.fromMap(map);
      expect(verse.themes, isA<List>());
      expect(verse.themes.isEmpty, true);
    });

    test('Service method signatures are correct', () {
      final service = DailyVerseService();

      // Verify methods exist and have correct signatures (compilation check only)
      expect(service.initialize, isA<Function>());
      expect(service.getDailyVerse, isA<Function>());
      expect(service.refreshDailyVerse, isA<Function>());
      expect(service.checkAndUpdateVerse, isA<Function>());
      expect(service.clearCache, isA<Function>());
    });
  });
}
