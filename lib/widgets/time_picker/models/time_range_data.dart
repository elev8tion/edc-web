import 'package:flutter/material.dart';

/// Data class representing a time range with start and end times
class TimeRangeData {
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const TimeRangeData({
    required this.startTime,
    required this.endTime,
  });

  /// Creates a copy of this TimeRangeData with the given fields replaced
  TimeRangeData copyWith({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return TimeRangeData(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  /// Validates that start time is before end time
  bool get isValid {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return startMinutes < endMinutes;
  }

  /// Returns the duration between start and end times
  Duration get duration {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return Duration(minutes: endMinutes - startMinutes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeRangeData && other.startTime == startTime && other.endTime == endTime;
  }

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;

  @override
  String toString() {
    return 'TimeRangeData(startTime: $startTime, endTime: $endTime)';
  }
}
