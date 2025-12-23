// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bible_verse.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BibleVerse _$BibleVerseFromJson(Map<String, dynamic> json) {
  return _BibleVerse.fromJson(json);
}

/// @nodoc
mixin _$BibleVerse {
  String get id => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  String get reference => throw _privateConstructorUsedError;
  VerseCategory get category => throw _privateConstructorUsedError;
  bool get isFavorite => throw _privateConstructorUsedError;
  DateTime? get dateAdded => throw _privateConstructorUsedError;

  /// Serializes this BibleVerse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BibleVerse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BibleVerseCopyWith<BibleVerse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BibleVerseCopyWith<$Res> {
  factory $BibleVerseCopyWith(
          BibleVerse value, $Res Function(BibleVerse) then) =
      _$BibleVerseCopyWithImpl<$Res, BibleVerse>;
  @useResult
  $Res call(
      {String id,
      String text,
      String reference,
      VerseCategory category,
      bool isFavorite,
      DateTime? dateAdded});
}

/// @nodoc
class _$BibleVerseCopyWithImpl<$Res, $Val extends BibleVerse>
    implements $BibleVerseCopyWith<$Res> {
  _$BibleVerseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BibleVerse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? reference = null,
    Object? category = null,
    Object? isFavorite = null,
    Object? dateAdded = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as VerseCategory,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      dateAdded: freezed == dateAdded
          ? _value.dateAdded
          : dateAdded // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BibleVerseImplCopyWith<$Res>
    implements $BibleVerseCopyWith<$Res> {
  factory _$$BibleVerseImplCopyWith(
          _$BibleVerseImpl value, $Res Function(_$BibleVerseImpl) then) =
      __$$BibleVerseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String text,
      String reference,
      VerseCategory category,
      bool isFavorite,
      DateTime? dateAdded});
}

/// @nodoc
class __$$BibleVerseImplCopyWithImpl<$Res>
    extends _$BibleVerseCopyWithImpl<$Res, _$BibleVerseImpl>
    implements _$$BibleVerseImplCopyWith<$Res> {
  __$$BibleVerseImplCopyWithImpl(
      _$BibleVerseImpl _value, $Res Function(_$BibleVerseImpl) _then)
      : super(_value, _then);

  /// Create a copy of BibleVerse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? reference = null,
    Object? category = null,
    Object? isFavorite = null,
    Object? dateAdded = freezed,
  }) {
    return _then(_$BibleVerseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      reference: null == reference
          ? _value.reference
          : reference // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as VerseCategory,
      isFavorite: null == isFavorite
          ? _value.isFavorite
          : isFavorite // ignore: cast_nullable_to_non_nullable
              as bool,
      dateAdded: freezed == dateAdded
          ? _value.dateAdded
          : dateAdded // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BibleVerseImpl implements _BibleVerse {
  const _$BibleVerseImpl(
      {required this.id,
      required this.text,
      required this.reference,
      required this.category,
      this.isFavorite = false,
      this.dateAdded});

  factory _$BibleVerseImpl.fromJson(Map<String, dynamic> json) =>
      _$$BibleVerseImplFromJson(json);

  @override
  final String id;
  @override
  final String text;
  @override
  final String reference;
  @override
  final VerseCategory category;
  @override
  @JsonKey()
  final bool isFavorite;
  @override
  final DateTime? dateAdded;

  @override
  String toString() {
    return 'BibleVerse(id: $id, text: $text, reference: $reference, category: $category, isFavorite: $isFavorite, dateAdded: $dateAdded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BibleVerseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isFavorite, isFavorite) ||
                other.isFavorite == isFavorite) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, text, reference, category, isFavorite, dateAdded);

  /// Create a copy of BibleVerse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BibleVerseImplCopyWith<_$BibleVerseImpl> get copyWith =>
      __$$BibleVerseImplCopyWithImpl<_$BibleVerseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BibleVerseImplToJson(
      this,
    );
  }
}

abstract class _BibleVerse implements BibleVerse {
  const factory _BibleVerse(
      {required final String id,
      required final String text,
      required final String reference,
      required final VerseCategory category,
      final bool isFavorite,
      final DateTime? dateAdded}) = _$BibleVerseImpl;

  factory _BibleVerse.fromJson(Map<String, dynamic> json) =
      _$BibleVerseImpl.fromJson;

  @override
  String get id;
  @override
  String get text;
  @override
  String get reference;
  @override
  VerseCategory get category;
  @override
  bool get isFavorite;
  @override
  DateTime? get dateAdded;

  /// Create a copy of BibleVerse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BibleVerseImplCopyWith<_$BibleVerseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
