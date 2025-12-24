/// Performance benchmarks for Bible FTS5 search
///
/// This file contains benchmarks to measure and validate FTS search performance.
/// Use these benchmarks to ensure FTS meets performance requirements.
library bible_fts_benchmark;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/sql_js_helper.dart';

/// Benchmark results for a single test
class BenchmarkResult {
  final String name;
  final int resultCount;
  final int durationMs;
  final bool passedThreshold;
  final int thresholdMs;

  BenchmarkResult({
    required this.name,
    required this.resultCount,
    required this.durationMs,
    required this.thresholdMs,
  }) : passedThreshold = durationMs <= thresholdMs;

  @override
  String toString() {
    final status = passedThreshold ? '✅ PASS' : '❌ FAIL';
    return '$status $name: ${durationMs}ms ($resultCount results, threshold: ${thresholdMs}ms)';
  }
}

/// FTS performance benchmarks
class BibleFtsBenchmark {
  final SqlJsDatabase _db;

  BibleFtsBenchmark(this._db);

  /// Run all benchmarks and return results
  ///
  /// Returns a list of benchmark results with timing and pass/fail status.
  ///
  /// Example:
  /// ```dart
  /// final benchmark = BibleFtsBenchmark(db);
  /// final results = await benchmark.runAll();
  /// for (final result in results) {
  ///   print(result);
  /// }
  /// ```
  Future<List<BenchmarkResult>> runAll() async {
    debugPrint(
        '🔍 [BibleFtsBenchmark] Running FTS performance benchmarks...\n');

    final results = <BenchmarkResult>[];

    // Benchmark 1: Simple word search
    results.add(await _benchmarkSimpleSearch());

    // Benchmark 2: Book-specific search
    results.add(await _benchmarkBookSearch());

    // Benchmark 3: Language-specific search
    results.add(await _benchmarkLanguageSearch());

    // Benchmark 4: Complex multi-filter search
    results.add(await _benchmarkComplexSearch());

    // Benchmark 5: Phrase search
    results.add(await _benchmarkPhraseSearch());

    // Benchmark 6: Boolean OR search
    results.add(await _benchmarkBooleanOrSearch());

    // Benchmark 7: Boolean AND search
    results.add(await _benchmarkBooleanAndSearch());

    // Benchmark 8: Large result set (no LIMIT)
    results.add(await _benchmarkLargeResultSet());

    // Print summary
    _printSummary(results);

    return results;
  }

  /// Benchmark: Simple word search
  Future<BenchmarkResult> _benchmarkSimpleSearch() async {
    final stopwatch = Stopwatch()..start();

    final results = await _db.query(
      'bible_verses_fts',
      where: "bible_verses_fts MATCH 'love'",
      limit: 100,
    );

    stopwatch.stop();

    return BenchmarkResult(
      name: 'Simple Search ("love")',
      resultCount: results.length,
      durationMs: stopwatch.elapsedMilliseconds,
      thresholdMs: 100, // Should complete in < 100ms
    );
  }

  /// Benchmark: Book-specific search
  Future<BenchmarkResult> _benchmarkBookSearch() async {
    final stopwatch = Stopwatch()..start();

    final results = await _db.query(
      'bible_verses_fts',
      where: "bible_verses_fts MATCH 'book:John AND God'",
      limit: 100,
    );

    stopwatch.stop();

    return BenchmarkResult(
      name: 'Book Search (John + God)',
      resultCount: results.length,
      durationMs: stopwatch.elapsedMilliseconds,
      thresholdMs: 150, // Should complete in < 150ms
    );
  }

  /// Benchmark: Language-specific search
  Future<BenchmarkResult> _benchmarkLanguageSearch() async {
    final stopwatch = Stopwatch()..start();

    final results = await _db.query(
      'bible_verses_fts',
      where: "bible_verses_fts MATCH 'language:es AND Dios'",
      limit: 100,
    );

    stopwatch.stop();

    return BenchmarkResult(
      name: 'Language Search (Spanish "Dios")',
      resultCount: results.length,
      durationMs: stopwatch.elapsedMilliseconds,
      thresholdMs: 150, // Should complete in < 150ms
    );
  }

  /// Benchmark: Complex multi-filter search
  Future<BenchmarkResult> _benchmarkComplexSearch() async {
    final stopwatch = Stopwatch()..start();

    final results = await _db.query(
      'bible_verses_fts',
      where:
          "bible_verses_fts MATCH 'book:John AND language:en AND love AND God'",
      limit: 100,
    );

    stopwatch.stop();

    return BenchmarkResult(
      name: 'Complex Search (John + English + love + God)',
      resultCount: results.length,
      durationMs: stopwatch.elapsedMilliseconds,
      thresholdMs: 200, // Should complete in < 200ms
    );
  }

  /// Benchmark: Phrase search
  Future<BenchmarkResult> _benchmarkPhraseSearch() async {
    final stopwatch = Stopwatch()..start();

    final results = await _db.query(
      'bible_verses_fts',
      where: 'bible_verses_fts MATCH \'"in the beginning"\'',
      limit: 100,
    );

    stopwatch.stop();

    return BenchmarkResult(
      name: 'Phrase Search ("in the beginning")',
      resultCount: results.length,
      durationMs: stopwatch.elapsedMilliseconds,
      thresholdMs: 150, // Should complete in < 150ms
    );
  }

  /// Benchmark: Boolean OR search
  Future<BenchmarkResult> _benchmarkBooleanOrSearch() async {
    final stopwatch = Stopwatch()..start();

    final results = await _db.query(
      'bible_verses_fts',
      where: "bible_verses_fts MATCH 'faith OR hope OR love'",
      limit: 100,
    );

    stopwatch.stop();

    return BenchmarkResult(
      name: 'Boolean OR Search (faith OR hope OR love)',
      resultCount: results.length,
      durationMs: stopwatch.elapsedMilliseconds,
      thresholdMs: 200, // Should complete in < 200ms
    );
  }

  /// Benchmark: Boolean AND search
  Future<BenchmarkResult> _benchmarkBooleanAndSearch() async {
    final stopwatch = Stopwatch()..start();

    final results = await _db.query(
      'bible_verses_fts',
      where: "bible_verses_fts MATCH 'faith AND hope AND love'",
      limit: 100,
    );

    stopwatch.stop();

    return BenchmarkResult(
      name: 'Boolean AND Search (faith AND hope AND love)',
      resultCount: results.length,
      durationMs: stopwatch.elapsedMilliseconds,
      thresholdMs: 200, // Should complete in < 200ms
    );
  }

  /// Benchmark: Large result set (no LIMIT)
  Future<BenchmarkResult> _benchmarkLargeResultSet() async {
    final stopwatch = Stopwatch()..start();

    final results = await _db.query(
      'bible_verses_fts',
      where: "bible_verses_fts MATCH 'God'",
      // No LIMIT - get all results
    );

    stopwatch.stop();

    return BenchmarkResult(
      name: 'Large Result Set (all "God" verses)',
      resultCount: results.length,
      durationMs: stopwatch.elapsedMilliseconds,
      thresholdMs: 500, // Should complete in < 500ms even with 1000+ results
    );
  }

  /// Print benchmark summary
  void _printSummary(List<BenchmarkResult> results) {
    debugPrint('\n📊 BENCHMARK SUMMARY\n');
    debugPrint('=' * 70);

    for (final result in results) {
      debugPrint(result.toString());
    }

    debugPrint('=' * 70);

    final passed = results.where((r) => r.passedThreshold).length;
    final failed = results.where((r) => !r.passedThreshold).length;
    final totalTime = results.fold<int>(0, (sum, r) => sum + r.durationMs);

    debugPrint('\nResults: $passed passed, $failed failed');
    debugPrint('Total time: ${totalTime}ms');

    if (failed == 0) {
      debugPrint('\n✅ ALL BENCHMARKS PASSED\n');
    } else {
      debugPrint('\n❌ SOME BENCHMARKS FAILED\n');
    }
  }
}

/// Comprehensive FTS benchmark report
class FtsBenchmarkReport {
  final List<BenchmarkResult> results;
  final DateTime timestamp;
  final int totalDurationMs;
  final int passedCount;
  final int failedCount;
  final double passRate;

  FtsBenchmarkReport({
    required this.results,
    required this.timestamp,
  })  : totalDurationMs = results.fold<int>(0, (sum, r) => sum + r.durationMs),
        passedCount = results.where((r) => r.passedThreshold).length,
        failedCount = results.where((r) => !r.passedThreshold).length,
        passRate = results.isEmpty
            ? 0.0
            : results.where((r) => r.passedThreshold).length / results.length;

  /// Generate markdown report
  String toMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('# FTS Benchmark Report');
    buffer.writeln();
    buffer.writeln('**Date:** ${timestamp.toIso8601String()}');
    buffer.writeln('**Total Duration:** ${totalDurationMs}ms');
    buffer.writeln(
        '**Pass Rate:** ${(passRate * 100).toStringAsFixed(1)}% ($passedCount/$failedCount)');
    buffer.writeln();

    buffer.writeln('## Results');
    buffer.writeln();
    buffer.writeln('| Benchmark | Duration | Results | Threshold | Status |');
    buffer.writeln('|-----------|----------|---------|-----------|--------|');

    for (final result in results) {
      final status = result.passedThreshold ? '✅ PASS' : '❌ FAIL';
      buffer.writeln(
        '| ${result.name} | ${result.durationMs}ms | ${result.resultCount} | ${result.thresholdMs}ms | $status |',
      );
    }

    buffer.writeln();

    if (failedCount > 0) {
      buffer.writeln('## Failed Benchmarks');
      buffer.writeln();
      for (final result in results.where((r) => !r.passedThreshold)) {
        buffer.writeln(
            '- **${result.name}**: ${result.durationMs}ms (threshold: ${result.thresholdMs}ms)');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Generate JSON report
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'total_duration_ms': totalDurationMs,
      'passed_count': passedCount,
      'failed_count': failedCount,
      'pass_rate': passRate,
      'results': results
          .map((r) => {
                'name': r.name,
                'duration_ms': r.durationMs,
                'result_count': r.resultCount,
                'threshold_ms': r.thresholdMs,
                'passed': r.passedThreshold,
              })
          .toList(),
    };
  }
}

/// Run benchmarks and generate report
Future<FtsBenchmarkReport> runBenchmarkReport(SqlJsDatabase db) async {
  final benchmark = BibleFtsBenchmark(db);
  final results = await benchmark.runAll();

  return FtsBenchmarkReport(
    results: results,
    timestamp: DateTime.now(),
  );
}

/// Example usage
void main() async {
  // Initialize database
  final db = await SqlJsHelper.database;

  // Run benchmarks
  final report = await runBenchmarkReport(db);

  // Print markdown report
  debugPrint(report.toMarkdown());

  // Print JSON report
  debugPrint('\nJSON Report:');
  debugPrint(report.toJson().toString());
}
