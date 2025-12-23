/// Platform-agnostic database interface
///
/// This interface is implemented by both mobile and web database helpers.
/// It defines the contract that both platforms must fulfill.
///
/// Mobile implementation: Uses sqflite's Database type
/// Web implementation: Uses SqlJsDatabase type
library database_interface;

/// Common database interface for both mobile and web platforms
abstract class DatabaseInterface {
  /// Get the database instance
  ///
  /// Returns:
  /// - Mobile: sqflite's Database
  /// - Web: SqlJsDatabase
  ///
  /// Services should cast to the appropriate type:
  /// ```dart
  /// // Mobile
  /// final db = await DatabaseHelper().database as Database;
  ///
  /// // Web (happens automatically via conditional imports)
  /// final db = await DatabaseHelper().database as SqlJsDatabase;
  /// ```
  Future<dynamic> get database;

  /// Close the database connection
  Future<void> close();

  /// Delete the database file/data
  Future<void> deleteDatabase();

  /// Initialize the database (for compatibility)
  Future<void> initialize();

  /// Reset the database (close, delete, reinitialize)
  Future<void> resetDatabase();
}
