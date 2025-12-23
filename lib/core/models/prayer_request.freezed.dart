// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prayer_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PrayerRequest _$PrayerRequestFromJson(Map<String, dynamic> json) {
  return _PrayerRequest.fromJson(json);
}

/// @nodoc
mixin _$PrayerRequest {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get categoryId =>
      throw _privateConstructorUsedError; // Changed from PrayerCategory to String categoryId
  DateTime get dateCreated => throw _privateConstructorUsedError;
  bool get isAnswered => throw _privateConstructorUsedError;
  DateTime? get dateAnswered => throw _privateConstructorUsedError;
  String? get answerDescription => throw _privateConstructorUsedError;

  /// Serializes this PrayerRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrayerRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrayerRequestCopyWith<PrayerRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrayerRequestCopyWith<$Res> {
  factory $PrayerRequestCopyWith(
          PrayerRequest value, $Res Function(PrayerRequest) then) =
      _$PrayerRequestCopyWithImpl<$Res, PrayerRequest>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String categoryId,
      DateTime dateCreated,
      bool isAnswered,
      DateTime? dateAnswered,
      String? answerDescription});
}

/// @nodoc
class _$PrayerRequestCopyWithImpl<$Res, $Val extends PrayerRequest>
    implements $PrayerRequestCopyWith<$Res> {
  _$PrayerRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrayerRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? categoryId = null,
    Object? dateCreated = null,
    Object? isAnswered = null,
    Object? dateAnswered = freezed,
    Object? answerDescription = freezed,
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
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      dateCreated: null == dateCreated
          ? _value.dateCreated
          : dateCreated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAnswered: null == isAnswered
          ? _value.isAnswered
          : isAnswered // ignore: cast_nullable_to_non_nullable
              as bool,
      dateAnswered: freezed == dateAnswered
          ? _value.dateAnswered
          : dateAnswered // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      answerDescription: freezed == answerDescription
          ? _value.answerDescription
          : answerDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrayerRequestImplCopyWith<$Res>
    implements $PrayerRequestCopyWith<$Res> {
  factory _$$PrayerRequestImplCopyWith(
          _$PrayerRequestImpl value, $Res Function(_$PrayerRequestImpl) then) =
      __$$PrayerRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      String categoryId,
      DateTime dateCreated,
      bool isAnswered,
      DateTime? dateAnswered,
      String? answerDescription});
}

/// @nodoc
class __$$PrayerRequestImplCopyWithImpl<$Res>
    extends _$PrayerRequestCopyWithImpl<$Res, _$PrayerRequestImpl>
    implements _$$PrayerRequestImplCopyWith<$Res> {
  __$$PrayerRequestImplCopyWithImpl(
      _$PrayerRequestImpl _value, $Res Function(_$PrayerRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of PrayerRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? categoryId = null,
    Object? dateCreated = null,
    Object? isAnswered = null,
    Object? dateAnswered = freezed,
    Object? answerDescription = freezed,
  }) {
    return _then(_$PrayerRequestImpl(
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
      categoryId: null == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String,
      dateCreated: null == dateCreated
          ? _value.dateCreated
          : dateCreated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isAnswered: null == isAnswered
          ? _value.isAnswered
          : isAnswered // ignore: cast_nullable_to_non_nullable
              as bool,
      dateAnswered: freezed == dateAnswered
          ? _value.dateAnswered
          : dateAnswered // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      answerDescription: freezed == answerDescription
          ? _value.answerDescription
          : answerDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PrayerRequestImpl implements _PrayerRequest {
  const _$PrayerRequestImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.categoryId,
      required this.dateCreated,
      this.isAnswered = false,
      this.dateAnswered,
      this.answerDescription});

  factory _$PrayerRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrayerRequestImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final String categoryId;
// Changed from PrayerCategory to String categoryId
  @override
  final DateTime dateCreated;
  @override
  @JsonKey()
  final bool isAnswered;
  @override
  final DateTime? dateAnswered;
  @override
  final String? answerDescription;

  @override
  String toString() {
    return 'PrayerRequest(id: $id, title: $title, description: $description, categoryId: $categoryId, dateCreated: $dateCreated, isAnswered: $isAnswered, dateAnswered: $dateAnswered, answerDescription: $answerDescription)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrayerRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.dateCreated, dateCreated) ||
                other.dateCreated == dateCreated) &&
            (identical(other.isAnswered, isAnswered) ||
                other.isAnswered == isAnswered) &&
            (identical(other.dateAnswered, dateAnswered) ||
                other.dateAnswered == dateAnswered) &&
            (identical(other.answerDescription, answerDescription) ||
                other.answerDescription == answerDescription));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, description,
      categoryId, dateCreated, isAnswered, dateAnswered, answerDescription);

  /// Create a copy of PrayerRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrayerRequestImplCopyWith<_$PrayerRequestImpl> get copyWith =>
      __$$PrayerRequestImplCopyWithImpl<_$PrayerRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrayerRequestImplToJson(
      this,
    );
  }
}

abstract class _PrayerRequest implements PrayerRequest {
  const factory _PrayerRequest(
      {required final String id,
      required final String title,
      required final String description,
      required final String categoryId,
      required final DateTime dateCreated,
      final bool isAnswered,
      final DateTime? dateAnswered,
      final String? answerDescription}) = _$PrayerRequestImpl;

  factory _PrayerRequest.fromJson(Map<String, dynamic> json) =
      _$PrayerRequestImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  String get categoryId; // Changed from PrayerCategory to String categoryId
  @override
  DateTime get dateCreated;
  @override
  bool get isAnswered;
  @override
  DateTime? get dateAnswered;
  @override
  String? get answerDescription;

  /// Create a copy of PrayerRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrayerRequestImplCopyWith<_$PrayerRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
