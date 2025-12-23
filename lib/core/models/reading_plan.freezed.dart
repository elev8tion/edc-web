// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReadingPlan _$ReadingPlanFromJson(Map<String, dynamic> json) {
  return _ReadingPlan.fromJson(json);
}

/// @nodoc
mixin _$ReadingPlan {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get duration => throw _privateConstructorUsedError;
  PlanCategory get category => throw _privateConstructorUsedError;
  PlanDifficulty get difficulty => throw _privateConstructorUsedError;
  String get estimatedTimePerDay => throw _privateConstructorUsedError;
  int get totalReadings => throw _privateConstructorUsedError;
  int get completedReadings => throw _privateConstructorUsedError;
  bool get isStarted => throw _privateConstructorUsedError;
  DateTime? get startDate => throw _privateConstructorUsedError;

  /// Serializes this ReadingPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReadingPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReadingPlanCopyWith<ReadingPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadingPlanCopyWith<$Res> {
  factory $ReadingPlanCopyWith(
          ReadingPlan value, $Res Function(ReadingPlan) then) =
      _$ReadingPlanCopyWithImpl<$Res, ReadingPlan>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String duration,
      PlanCategory category,
      PlanDifficulty difficulty,
      String estimatedTimePerDay,
      int totalReadings,
      int completedReadings,
      bool isStarted,
      DateTime? startDate});
}

/// @nodoc
class _$ReadingPlanCopyWithImpl<$Res, $Val extends ReadingPlan>
    implements $ReadingPlanCopyWith<$Res> {
  _$ReadingPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReadingPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? duration = null,
    Object? category = null,
    Object? difficulty = null,
    Object? estimatedTimePerDay = null,
    Object? totalReadings = null,
    Object? completedReadings = null,
    Object? isStarted = null,
    Object? startDate = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PlanCategory,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as PlanDifficulty,
      estimatedTimePerDay: null == estimatedTimePerDay
          ? _value.estimatedTimePerDay
          : estimatedTimePerDay // ignore: cast_nullable_to_non_nullable
              as String,
      totalReadings: null == totalReadings
          ? _value.totalReadings
          : totalReadings // ignore: cast_nullable_to_non_nullable
              as int,
      completedReadings: null == completedReadings
          ? _value.completedReadings
          : completedReadings // ignore: cast_nullable_to_non_nullable
              as int,
      isStarted: null == isStarted
          ? _value.isStarted
          : isStarted // ignore: cast_nullable_to_non_nullable
              as bool,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReadingPlanImplCopyWith<$Res>
    implements $ReadingPlanCopyWith<$Res> {
  factory _$$ReadingPlanImplCopyWith(
          _$ReadingPlanImpl value, $Res Function(_$ReadingPlanImpl) then) =
      __$$ReadingPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String duration,
      PlanCategory category,
      PlanDifficulty difficulty,
      String estimatedTimePerDay,
      int totalReadings,
      int completedReadings,
      bool isStarted,
      DateTime? startDate});
}

/// @nodoc
class __$$ReadingPlanImplCopyWithImpl<$Res>
    extends _$ReadingPlanCopyWithImpl<$Res, _$ReadingPlanImpl>
    implements _$$ReadingPlanImplCopyWith<$Res> {
  __$$ReadingPlanImplCopyWithImpl(
      _$ReadingPlanImpl _value, $Res Function(_$ReadingPlanImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReadingPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? duration = null,
    Object? category = null,
    Object? difficulty = null,
    Object? estimatedTimePerDay = null,
    Object? totalReadings = null,
    Object? completedReadings = null,
    Object? isStarted = null,
    Object? startDate = freezed,
  }) {
    return _then(_$ReadingPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as PlanCategory,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as PlanDifficulty,
      estimatedTimePerDay: null == estimatedTimePerDay
          ? _value.estimatedTimePerDay
          : estimatedTimePerDay // ignore: cast_nullable_to_non_nullable
              as String,
      totalReadings: null == totalReadings
          ? _value.totalReadings
          : totalReadings // ignore: cast_nullable_to_non_nullable
              as int,
      completedReadings: null == completedReadings
          ? _value.completedReadings
          : completedReadings // ignore: cast_nullable_to_non_nullable
              as int,
      isStarted: null == isStarted
          ? _value.isStarted
          : isStarted // ignore: cast_nullable_to_non_nullable
              as bool,
      startDate: freezed == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReadingPlanImpl implements _ReadingPlan {
  const _$ReadingPlanImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.duration,
      required this.category,
      required this.difficulty,
      required this.estimatedTimePerDay,
      required this.totalReadings,
      this.completedReadings = 0,
      this.isStarted = false,
      this.startDate});

  factory _$ReadingPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReadingPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String duration;
  @override
  final PlanCategory category;
  @override
  final PlanDifficulty difficulty;
  @override
  final String estimatedTimePerDay;
  @override
  final int totalReadings;
  @override
  @JsonKey()
  final int completedReadings;
  @override
  @JsonKey()
  final bool isStarted;
  @override
  final DateTime? startDate;

  @override
  String toString() {
    return 'ReadingPlan(id: $id, title: $title, description: $description, duration: $duration, category: $category, difficulty: $difficulty, estimatedTimePerDay: $estimatedTimePerDay, totalReadings: $totalReadings, completedReadings: $completedReadings, isStarted: $isStarted, startDate: $startDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadingPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.estimatedTimePerDay, estimatedTimePerDay) ||
                other.estimatedTimePerDay == estimatedTimePerDay) &&
            (identical(other.totalReadings, totalReadings) ||
                other.totalReadings == totalReadings) &&
            (identical(other.completedReadings, completedReadings) ||
                other.completedReadings == completedReadings) &&
            (identical(other.isStarted, isStarted) ||
                other.isStarted == isStarted) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      duration,
      category,
      difficulty,
      estimatedTimePerDay,
      totalReadings,
      completedReadings,
      isStarted,
      startDate);

  /// Create a copy of ReadingPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadingPlanImplCopyWith<_$ReadingPlanImpl> get copyWith =>
      __$$ReadingPlanImplCopyWithImpl<_$ReadingPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReadingPlanImplToJson(
      this,
    );
  }
}

abstract class _ReadingPlan implements ReadingPlan {
  const factory _ReadingPlan(
      {required final String id,
      required final String title,
      required final String description,
      required final String duration,
      required final PlanCategory category,
      required final PlanDifficulty difficulty,
      required final String estimatedTimePerDay,
      required final int totalReadings,
      final int completedReadings,
      final bool isStarted,
      final DateTime? startDate}) = _$ReadingPlanImpl;

  factory _ReadingPlan.fromJson(Map<String, dynamic> json) =
      _$ReadingPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get duration;
  @override
  PlanCategory get category;
  @override
  PlanDifficulty get difficulty;
  @override
  String get estimatedTimePerDay;
  @override
  int get totalReadings;
  @override
  int get completedReadings;
  @override
  bool get isStarted;
  @override
  DateTime? get startDate;

  /// Create a copy of ReadingPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadingPlanImplCopyWith<_$ReadingPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DailyReading _$DailyReadingFromJson(Map<String, dynamic> json) {
  return _DailyReading.fromJson(json);
}

/// @nodoc
mixin _$DailyReading {
  String get id => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get book => throw _privateConstructorUsedError;
  String get chapters => throw _privateConstructorUsedError;
  String get estimatedTime => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime? get completedDate => throw _privateConstructorUsedError;

  /// Serializes this DailyReading to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DailyReading
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DailyReadingCopyWith<DailyReading> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyReadingCopyWith<$Res> {
  factory $DailyReadingCopyWith(
          DailyReading value, $Res Function(DailyReading) then) =
      _$DailyReadingCopyWithImpl<$Res, DailyReading>;
  @useResult
  $Res call(
      {String id,
      String planId,
      String title,
      String description,
      String book,
      String chapters,
      String estimatedTime,
      DateTime date,
      bool isCompleted,
      DateTime? completedDate});
}

/// @nodoc
class _$DailyReadingCopyWithImpl<$Res, $Val extends DailyReading>
    implements $DailyReadingCopyWith<$Res> {
  _$DailyReadingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DailyReading
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? title = null,
    Object? description = null,
    Object? book = null,
    Object? chapters = null,
    Object? estimatedTime = null,
    Object? date = null,
    Object? isCompleted = null,
    Object? completedDate = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      book: null == book
          ? _value.book
          : book // ignore: cast_nullable_to_non_nullable
              as String,
      chapters: null == chapters
          ? _value.chapters
          : chapters // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedTime: null == estimatedTime
          ? _value.estimatedTime
          : estimatedTime // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      completedDate: freezed == completedDate
          ? _value.completedDate
          : completedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyReadingImplCopyWith<$Res>
    implements $DailyReadingCopyWith<$Res> {
  factory _$$DailyReadingImplCopyWith(
          _$DailyReadingImpl value, $Res Function(_$DailyReadingImpl) then) =
      __$$DailyReadingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String planId,
      String title,
      String description,
      String book,
      String chapters,
      String estimatedTime,
      DateTime date,
      bool isCompleted,
      DateTime? completedDate});
}

/// @nodoc
class __$$DailyReadingImplCopyWithImpl<$Res>
    extends _$DailyReadingCopyWithImpl<$Res, _$DailyReadingImpl>
    implements _$$DailyReadingImplCopyWith<$Res> {
  __$$DailyReadingImplCopyWithImpl(
      _$DailyReadingImpl _value, $Res Function(_$DailyReadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of DailyReading
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? title = null,
    Object? description = null,
    Object? book = null,
    Object? chapters = null,
    Object? estimatedTime = null,
    Object? date = null,
    Object? isCompleted = null,
    Object? completedDate = freezed,
  }) {
    return _then(_$DailyReadingImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      planId: null == planId
          ? _value.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      book: null == book
          ? _value.book
          : book // ignore: cast_nullable_to_non_nullable
              as String,
      chapters: null == chapters
          ? _value.chapters
          : chapters // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedTime: null == estimatedTime
          ? _value.estimatedTime
          : estimatedTime // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      completedDate: freezed == completedDate
          ? _value.completedDate
          : completedDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DailyReadingImpl implements _DailyReading {
  const _$DailyReadingImpl(
      {required this.id,
      required this.planId,
      required this.title,
      required this.description,
      required this.book,
      required this.chapters,
      required this.estimatedTime,
      required this.date,
      this.isCompleted = false,
      this.completedDate});

  factory _$DailyReadingImpl.fromJson(Map<String, dynamic> json) =>
      _$$DailyReadingImplFromJson(json);

  @override
  final String id;
  @override
  final String planId;
  @override
  final String title;
  @override
  final String description;
  @override
  final String book;
  @override
  final String chapters;
  @override
  final String estimatedTime;
  @override
  final DateTime date;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final DateTime? completedDate;

  @override
  String toString() {
    return 'DailyReading(id: $id, planId: $planId, title: $title, description: $description, book: $book, chapters: $chapters, estimatedTime: $estimatedTime, date: $date, isCompleted: $isCompleted, completedDate: $completedDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyReadingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.book, book) || other.book == book) &&
            (identical(other.chapters, chapters) ||
                other.chapters == chapters) &&
            (identical(other.estimatedTime, estimatedTime) ||
                other.estimatedTime == estimatedTime) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.completedDate, completedDate) ||
                other.completedDate == completedDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, planId, title, description,
      book, chapters, estimatedTime, date, isCompleted, completedDate);

  /// Create a copy of DailyReading
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyReadingImplCopyWith<_$DailyReadingImpl> get copyWith =>
      __$$DailyReadingImplCopyWithImpl<_$DailyReadingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DailyReadingImplToJson(
      this,
    );
  }
}

abstract class _DailyReading implements DailyReading {
  const factory _DailyReading(
      {required final String id,
      required final String planId,
      required final String title,
      required final String description,
      required final String book,
      required final String chapters,
      required final String estimatedTime,
      required final DateTime date,
      final bool isCompleted,
      final DateTime? completedDate}) = _$DailyReadingImpl;

  factory _DailyReading.fromJson(Map<String, dynamic> json) =
      _$DailyReadingImpl.fromJson;

  @override
  String get id;
  @override
  String get planId;
  @override
  String get title;
  @override
  String get description;
  @override
  String get book;
  @override
  String get chapters;
  @override
  String get estimatedTime;
  @override
  DateTime get date;
  @override
  bool get isCompleted;
  @override
  DateTime? get completedDate;

  /// Create a copy of DailyReading
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DailyReadingImplCopyWith<_$DailyReadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
