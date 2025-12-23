import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

/// Log levels for the application
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  fatal(4);

  final int value;
  const LogLevel(this.value);

  bool operator >=(LogLevel other) => value >= other.value;
  bool operator <(LogLevel other) => value < other.value;
}

/// Log entry model
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? context;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.context,
    this.stackTrace,
    this.metadata,
  });

  String toFormattedString() {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
    final buffer = StringBuffer();
    
    buffer.write('[${dateFormat.format(timestamp)}] ');
    buffer.write('[${level.name.toUpperCase().padRight(7)}] ');
    
    if (context != null) {
      buffer.write('[$context] ');
    }
    
    buffer.write(message);
    
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write(' | metadata: $metadata');
    }
    
    if (stackTrace != null) {
      buffer.write('\nStack trace:\n$stackTrace');
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      if (context != null) 'context': context,
      if (metadata != null) 'metadata': metadata,
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
  }
}

/// Comprehensive application logger with persistence
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  static AppLogger get instance => _instance;

  AppLogger._internal();

  // Configuration
  LogLevel _minimumLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  bool _enableFileLogging = true;
  bool _enableConsoleLogging = true;
  int _maxLogFileSize = 5 * 1024 * 1024; // 5 MB
  int _maxLogFiles = 3; // Keep last 3 log files

  // Internal state
  final List<LogEntry> _inMemoryLogs = [];
  static const int _maxInMemoryLogs = 1000;
  File? _currentLogFile;
  final _logController = StreamController<LogEntry>.broadcast();

  /// Stream of log entries
  Stream<LogEntry> get logStream => _logController.stream;

  /// Initialize the logger
  Future<void> initialize({
    LogLevel? minimumLevel,
    bool? enableFileLogging,
    bool? enableConsoleLogging,
    int? maxLogFileSize,
    int? maxLogFiles,
  }) async {
    if (minimumLevel != null) _minimumLevel = minimumLevel;
    if (enableFileLogging != null) _enableFileLogging = enableFileLogging;
    if (enableConsoleLogging != null) _enableConsoleLogging = enableConsoleLogging;
    if (maxLogFileSize != null) _maxLogFileSize = maxLogFileSize;
    if (maxLogFiles != null) _maxLogFiles = maxLogFiles;

    if (_enableFileLogging) {
      await _initializeLogFile();
    }

    info('Logger initialized', context: 'AppLogger');
  }

  /// Debug level logging
  void debug(
    String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.debug,
      message,
      context: context,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Info level logging
  void info(
    String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.info,
      message,
      context: context,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Warning level logging
  void warning(
    String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.warning,
      message,
      context: context,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Error level logging
  void error(
    String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.error,
      message,
      context: context,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Fatal level logging
  void fatal(
    String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log(
      LogLevel.fatal,
      message,
      context: context,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Core logging method
  void _log(
    LogLevel level,
    String message, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    // Check if log level meets minimum threshold
    if (level < _minimumLevel) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      context: context,
      stackTrace: stackTrace,
      metadata: metadata,
    );

    // Add to in-memory log
    _addToMemoryLog(entry);

    // Emit to stream
    _logController.add(entry);

    // Console logging
    if (_enableConsoleLogging) {
      _logToConsole(entry);
    }

    // File logging
    if (_enableFileLogging) {
      _logToFile(entry);
    }
  }

  /// Add log entry to in-memory storage
  void _addToMemoryLog(LogEntry entry) {
    _inMemoryLogs.add(entry);
    
    // Limit in-memory logs
    if (_inMemoryLogs.length > _maxInMemoryLogs) {
      _inMemoryLogs.removeAt(0);
    }
  }

  /// Log to console with color coding
  void _logToConsole(LogEntry entry) {
    final formatted = entry.toFormattedString();
    
    switch (entry.level) {
      case LogLevel.debug:
        debugPrint('🔍 $formatted');
        break;
      case LogLevel.info:
        debugPrint('ℹ️ $formatted');
        break;
      case LogLevel.warning:
        debugPrint('⚠️ $formatted');
        break;
      case LogLevel.error:
        debugPrint('❌ $formatted');
        break;
      case LogLevel.fatal:
        debugPrint('💀 $formatted');
        break;
    }
  }

  /// Initialize log file
  Future<void> _initializeLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(directory.path, 'logs'));
      
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final fileName = 'app_log_${dateFormat.format(now)}.txt';
      
      _currentLogFile = File(path.join(logsDir.path, fileName));
      
      // Rotate old log files
      await _rotateLogFiles(logsDir);
      
    } catch (e) {
      debugPrint('Failed to initialize log file: $e');
    }
  }

  /// Write log entry to file
  Future<void> _logToFile(LogEntry entry) async {
    if (_currentLogFile == null) return;

    try {
      // Check if file size exceeds limit
      if (await _currentLogFile!.exists()) {
        final fileSize = await _currentLogFile!.length();
        if (fileSize >= _maxLogFileSize) {
          await _initializeLogFile(); // Create new log file
        }
      }

      // Write log entry
      await _currentLogFile!.writeAsString(
        '${entry.toFormattedString()}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Failed to write log to file: $e');
    }
  }

  /// Rotate log files (keep only max number of files)
  Future<void> _rotateLogFiles(Directory logsDir) async {
    try {
      final files = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.txt'))
          .map((entity) => entity as File)
          .toList();

      // Sort by modification time (oldest first)
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return aStat.modified.compareTo(bStat.modified);
      });

      // Delete oldest files if we exceed the limit
      while (files.length >= _maxLogFiles) {
        await files.first.delete();
        files.removeAt(0);
      }
    } catch (e) {
      debugPrint('Failed to rotate log files: $e');
    }
  }

  /// Get recent logs from memory
  List<LogEntry> getRecentLogs({int? limit, LogLevel? minimumLevel}) {
    var logs = _inMemoryLogs;
    
    if (minimumLevel != null) {
      logs = logs.where((log) => log.level >= minimumLevel).toList();
    }
    
    if (limit != null && limit < logs.length) {
      return logs.sublist(logs.length - limit);
    }
    
    return logs;
  }

  /// Get logs from file
  Future<String?> getLogsFromFile({File? logFile}) async {
    try {
      final file = logFile ?? _currentLogFile;
      if (file == null || !await file.exists()) {
        return null;
      }
      return await file.readAsString();
    } catch (e) {
      error('Failed to read logs from file', context: 'AppLogger', metadata: {'error': e.toString()});
      return null;
    }
  }

  /// Get all log files
  Future<List<File>> getAllLogFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(directory.path, 'logs'));
      
      if (!await logsDir.exists()) {
        return [];
      }

      final files = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.txt'))
          .map((entity) => entity as File)
          .toList();

      // Sort by modification time (newest first)
      files.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return files;
    } catch (e) {
      error('Failed to get log files', context: 'AppLogger', metadata: {'error': e.toString()});
      return [];
    }
  }

  /// Export logs as a combined string
  Future<String> exportLogs() async {
    final buffer = StringBuffer();
    
    // Add in-memory logs
    buffer.writeln('=== Recent Logs (In-Memory) ===');
    for (final entry in _inMemoryLogs) {
      buffer.writeln(entry.toFormattedString());
    }
    
    // Add current log file content
    final fileContent = await getLogsFromFile();
    if (fileContent != null) {
      buffer.writeln('\n=== Current Log File ===');
      buffer.writeln(fileContent);
    }
    
    return buffer.toString();
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _inMemoryLogs.clear();
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory(path.join(directory.path, 'logs'));
      
      if (await logsDir.exists()) {
        await logsDir.delete(recursive: true);
      }
      
      await _initializeLogFile();
      info('Logs cleared', context: 'AppLogger');
    } catch (e) {
      error('Failed to clear logs', context: 'AppLogger', metadata: {'error': e.toString()});
    }
  }

  /// Dispose logger resources
  Future<void> dispose() async {
    await _logController.close();
  }
}
