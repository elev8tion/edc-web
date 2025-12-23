import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/bible_book.dart';

/// Service for loading and querying Bible book metadata from JSON
class BibleBookService {
  static BibleBookService? _instance;
  static BibleBookService get instance => _instance ??= BibleBookService._();
  BibleBookService._();

  List<BibleBook>? _cachedBooks;

  /// Load all Bible books from JSON asset
  Future<List<BibleBook>> getAllBooks() async {
    // Return cached if already loaded
    if (_cachedBooks != null) return _cachedBooks!;

    try {
      // Load JSON from assets
      final jsonString = await rootBundle.loadString('assets/data/bible_books.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final booksList = jsonData['books'] as List;

      // Parse into BibleBook objects
      _cachedBooks = booksList
          .map((bookJson) => BibleBook.fromJson(bookJson as Map<String, dynamic>))
          .toList();

      return _cachedBooks!;
    } catch (e) {
      // Error loading Bible books - rethrow for caller to handle
      rethrow;
    }
  }

  /// Get a specific book by English name
  Future<BibleBook?> getBookByEnglishName(String name) async {
    final books = await getAllBooks();
    try {
      return books.firstWhere(
        (book) => book.englishName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get a specific book by Spanish name
  Future<BibleBook?> getBookBySpanishName(String name) async {
    final books = await getAllBooks();
    try {
      return books.firstWhere(
        (book) => book.spanishName.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get a book by name in any language
  Future<BibleBook?> getBookByName(String name) async {
    final books = await getAllBooks();
    try {
      return books.firstWhere(
        (book) => book.matchesName(name),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get Old Testament books (first 39 books)
  Future<List<BibleBook>> getOldTestamentBooks() async {
    final books = await getAllBooks();
    return books.where((book) => book.testament == 'Old Testament').toList();
  }

  /// Get New Testament books (last 27 books)
  Future<List<BibleBook>> getNewTestamentBooks() async {
    final books = await getAllBooks();
    return books.where((book) => book.testament == 'New Testament').toList();
  }

  /// Get books by language (returns localized names)
  Future<List<String>> getBookNames(String languageCode) async {
    final books = await getAllBooks();
    return books.map((book) => book.getName(languageCode)).toList();
  }

  /// Clear cache (useful for testing)
  void clearCache() {
    _cachedBooks = null;
  }
}
