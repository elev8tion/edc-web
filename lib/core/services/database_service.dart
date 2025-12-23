import 'dart:async';
import '../database/database_helper.dart';

/// DatabaseService wrapper for backward compatibility
/// All functionality is now handled by DatabaseHelper
class DatabaseService {
  static final DatabaseHelper _helper = DatabaseHelper.instance;

  /// Get database instance
  /// Returns dynamic to support both mobile (Database) and web (SqlJsDatabase)
  Future<dynamic> get database async => await _helper.database;

  /// Initialize database
  Future<void> initialize() async {
    await _helper.initialize();
  }

  /// Close database
  Future<void> close() async {
    await _helper.close();
  }

  /// Reset database
  Future<void> resetDatabase() async {
    await _helper.resetDatabase();
  }
}
