// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_error.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppError {
  String get message => throw _privateConstructorUsedError;
  ErrorSeverity get severity => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppErrorCopyWith<AppError> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppErrorCopyWith<$Res> {
  factory $AppErrorCopyWith(AppError value, $Res Function(AppError) then) =
      _$AppErrorCopyWithImpl<$Res, AppError>;
  @useResult
  $Res call({String message, ErrorSeverity severity});
}

/// @nodoc
class _$AppErrorCopyWithImpl<$Res, $Val extends AppError>
    implements $AppErrorCopyWith<$Res> {
  _$AppErrorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? severity = null,
  }) {
    return _then(_value.copyWith(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NetworkErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$NetworkErrorImplCopyWith(
          _$NetworkErrorImpl value, $Res Function(_$NetworkErrorImpl) then) =
      __$$NetworkErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, String? details, ErrorSeverity severity});
}

/// @nodoc
class __$$NetworkErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$NetworkErrorImpl>
    implements _$$NetworkErrorImplCopyWith<$Res> {
  __$$NetworkErrorImplCopyWithImpl(
      _$NetworkErrorImpl _value, $Res Function(_$NetworkErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? details = freezed,
    Object? severity = null,
  }) {
    return _then(_$NetworkErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
    ));
  }
}

/// @nodoc

class _$NetworkErrorImpl implements NetworkError {
  const _$NetworkErrorImpl(
      {required this.message,
      this.details,
      this.severity = ErrorSeverity.error});

  @override
  final String message;
  @override
  final String? details;
  @override
  @JsonKey()
  final ErrorSeverity severity;

  @override
  String toString() {
    return 'AppError.network(message: $message, details: $details, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.severity, severity) ||
                other.severity == severity));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, details, severity);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkErrorImplCopyWith<_$NetworkErrorImpl> get copyWith =>
      __$$NetworkErrorImplCopyWithImpl<_$NetworkErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return network(message, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return network?.call(message, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(message, details, severity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return network(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return network?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(this);
    }
    return orElse();
  }
}

abstract class NetworkError implements AppError {
  const factory NetworkError(
      {required final String message,
      final String? details,
      final ErrorSeverity severity}) = _$NetworkErrorImpl;

  @override
  String get message;
  String? get details;
  @override
  ErrorSeverity get severity;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NetworkErrorImplCopyWith<_$NetworkErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DatabaseErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$DatabaseErrorImplCopyWith(
          _$DatabaseErrorImpl value, $Res Function(_$DatabaseErrorImpl) then) =
      __$$DatabaseErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String message,
      String? details,
      ErrorSeverity severity,
      String? query,
      String? table});
}

/// @nodoc
class __$$DatabaseErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$DatabaseErrorImpl>
    implements _$$DatabaseErrorImplCopyWith<$Res> {
  __$$DatabaseErrorImplCopyWithImpl(
      _$DatabaseErrorImpl _value, $Res Function(_$DatabaseErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? details = freezed,
    Object? severity = null,
    Object? query = freezed,
    Object? table = freezed,
  }) {
    return _then(_$DatabaseErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
      query: freezed == query
          ? _value.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      table: freezed == table
          ? _value.table
          : table // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$DatabaseErrorImpl implements DatabaseError {
  const _$DatabaseErrorImpl(
      {required this.message,
      this.details,
      this.severity = ErrorSeverity.error,
      this.query,
      this.table});

  @override
  final String message;
  @override
  final String? details;
  @override
  @JsonKey()
  final ErrorSeverity severity;
  @override
  final String? query;
  @override
  final String? table;

  @override
  String toString() {
    return 'AppError.database(message: $message, details: $details, severity: $severity, query: $query, table: $table)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DatabaseErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.table, table) || other.table == table));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, message, details, severity, query, table);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DatabaseErrorImplCopyWith<_$DatabaseErrorImpl> get copyWith =>
      __$$DatabaseErrorImplCopyWithImpl<_$DatabaseErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return database(message, details, severity, query, table);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return database?.call(message, details, severity, query, table);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (database != null) {
      return database(message, details, severity, query, table);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return database(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return database?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (database != null) {
      return database(this);
    }
    return orElse();
  }
}

abstract class DatabaseError implements AppError {
  const factory DatabaseError(
      {required final String message,
      final String? details,
      final ErrorSeverity severity,
      final String? query,
      final String? table}) = _$DatabaseErrorImpl;

  @override
  String get message;
  String? get details;
  @override
  ErrorSeverity get severity;
  String? get query;
  String? get table;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DatabaseErrorImplCopyWith<_$DatabaseErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ValidationErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$ValidationErrorImplCopyWith(_$ValidationErrorImpl value,
          $Res Function(_$ValidationErrorImpl) then) =
      __$$ValidationErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, String? field, ErrorSeverity severity});
}

/// @nodoc
class __$$ValidationErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$ValidationErrorImpl>
    implements _$$ValidationErrorImplCopyWith<$Res> {
  __$$ValidationErrorImplCopyWithImpl(
      _$ValidationErrorImpl _value, $Res Function(_$ValidationErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? field = freezed,
    Object? severity = null,
  }) {
    return _then(_$ValidationErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      field: freezed == field
          ? _value.field
          : field // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
    ));
  }
}

/// @nodoc

class _$ValidationErrorImpl implements ValidationError {
  const _$ValidationErrorImpl(
      {required this.message,
      this.field,
      this.severity = ErrorSeverity.warning});

  @override
  final String message;
  @override
  final String? field;
  @override
  @JsonKey()
  final ErrorSeverity severity;

  @override
  String toString() {
    return 'AppError.validation(message: $message, field: $field, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidationErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.severity, severity) ||
                other.severity == severity));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, field, severity);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidationErrorImplCopyWith<_$ValidationErrorImpl> get copyWith =>
      __$$ValidationErrorImplCopyWithImpl<_$ValidationErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return validation(message, field, severity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return validation?.call(message, field, severity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(message, field, severity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return validation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return validation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(this);
    }
    return orElse();
  }
}

abstract class ValidationError implements AppError {
  const factory ValidationError(
      {required final String message,
      final String? field,
      final ErrorSeverity severity}) = _$ValidationErrorImpl;

  @override
  String get message;
  String? get field;
  @override
  ErrorSeverity get severity;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ValidationErrorImplCopyWith<_$ValidationErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PermissionErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$PermissionErrorImplCopyWith(_$PermissionErrorImpl value,
          $Res Function(_$PermissionErrorImpl) then) =
      __$$PermissionErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, String? permission, ErrorSeverity severity});
}

/// @nodoc
class __$$PermissionErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$PermissionErrorImpl>
    implements _$$PermissionErrorImplCopyWith<$Res> {
  __$$PermissionErrorImplCopyWithImpl(
      _$PermissionErrorImpl _value, $Res Function(_$PermissionErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? permission = freezed,
    Object? severity = null,
  }) {
    return _then(_$PermissionErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      permission: freezed == permission
          ? _value.permission
          : permission // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
    ));
  }
}

/// @nodoc

class _$PermissionErrorImpl implements PermissionError {
  const _$PermissionErrorImpl(
      {required this.message,
      this.permission,
      this.severity = ErrorSeverity.warning});

  @override
  final String message;
  @override
  final String? permission;
  @override
  @JsonKey()
  final ErrorSeverity severity;

  @override
  String toString() {
    return 'AppError.permission(message: $message, permission: $permission, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PermissionErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.permission, permission) ||
                other.permission == permission) &&
            (identical(other.severity, severity) ||
                other.severity == severity));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, permission, severity);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PermissionErrorImplCopyWith<_$PermissionErrorImpl> get copyWith =>
      __$$PermissionErrorImplCopyWithImpl<_$PermissionErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return permission(message, this.permission, severity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return permission?.call(message, this.permission, severity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (permission != null) {
      return permission(message, this.permission, severity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return permission(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return permission?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (permission != null) {
      return permission(this);
    }
    return orElse();
  }
}

abstract class PermissionError implements AppError {
  const factory PermissionError(
      {required final String message,
      final String? permission,
      final ErrorSeverity severity}) = _$PermissionErrorImpl;

  @override
  String get message;
  String? get permission;
  @override
  ErrorSeverity get severity;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PermissionErrorImplCopyWith<_$PermissionErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnknownErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$UnknownErrorImplCopyWith(
          _$UnknownErrorImpl value, $Res Function(_$UnknownErrorImpl) then) =
      __$$UnknownErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String message, String? details, ErrorSeverity severity});
}

/// @nodoc
class __$$UnknownErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$UnknownErrorImpl>
    implements _$$UnknownErrorImplCopyWith<$Res> {
  __$$UnknownErrorImplCopyWithImpl(
      _$UnknownErrorImpl _value, $Res Function(_$UnknownErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? details = freezed,
    Object? severity = null,
  }) {
    return _then(_$UnknownErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
    ));
  }
}

/// @nodoc

class _$UnknownErrorImpl implements UnknownError {
  const _$UnknownErrorImpl(
      {required this.message,
      this.details,
      this.severity = ErrorSeverity.error});

  @override
  final String message;
  @override
  final String? details;
  @override
  @JsonKey()
  final ErrorSeverity severity;

  @override
  String toString() {
    return 'AppError.unknown(message: $message, details: $details, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnknownErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.severity, severity) ||
                other.severity == severity));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message, details, severity);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnknownErrorImplCopyWith<_$UnknownErrorImpl> get copyWith =>
      __$$UnknownErrorImplCopyWithImpl<_$UnknownErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return unknown(message, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return unknown?.call(message, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(message, details, severity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class UnknownError implements AppError {
  const factory UnknownError(
      {required final String message,
      final String? details,
      final ErrorSeverity severity}) = _$UnknownErrorImpl;

  @override
  String get message;
  String? get details;
  @override
  ErrorSeverity get severity;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnknownErrorImplCopyWith<_$UnknownErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ApiErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$ApiErrorImplCopyWith(
          _$ApiErrorImpl value, $Res Function(_$ApiErrorImpl) then) =
      __$$ApiErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String message,
      int? statusCode,
      String? details,
      ErrorSeverity severity});
}

/// @nodoc
class __$$ApiErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$ApiErrorImpl>
    implements _$$ApiErrorImplCopyWith<$Res> {
  __$$ApiErrorImplCopyWithImpl(
      _$ApiErrorImpl _value, $Res Function(_$ApiErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? statusCode = freezed,
    Object? details = freezed,
    Object? severity = null,
  }) {
    return _then(_$ApiErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      statusCode: freezed == statusCode
          ? _value.statusCode
          : statusCode // ignore: cast_nullable_to_non_nullable
              as int?,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
    ));
  }
}

/// @nodoc

class _$ApiErrorImpl implements ApiError {
  const _$ApiErrorImpl(
      {required this.message,
      this.statusCode,
      this.details,
      this.severity = ErrorSeverity.error});

  @override
  final String message;
  @override
  final int? statusCode;
  @override
  final String? details;
  @override
  @JsonKey()
  final ErrorSeverity severity;

  @override
  String toString() {
    return 'AppError.api(message: $message, statusCode: $statusCode, details: $details, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ApiErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.severity, severity) ||
                other.severity == severity));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, message, statusCode, details, severity);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ApiErrorImplCopyWith<_$ApiErrorImpl> get copyWith =>
      __$$ApiErrorImplCopyWithImpl<_$ApiErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return api(message, statusCode, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return api?.call(message, statusCode, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (api != null) {
      return api(message, statusCode, details, severity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return api(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return api?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (api != null) {
      return api(this);
    }
    return orElse();
  }
}

abstract class ApiError implements AppError {
  const factory ApiError(
      {required final String message,
      final int? statusCode,
      final String? details,
      final ErrorSeverity severity}) = _$ApiErrorImpl;

  @override
  String get message;
  int? get statusCode;
  String? get details;
  @override
  ErrorSeverity get severity;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ApiErrorImplCopyWith<_$ApiErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AIErrorImplCopyWith<$Res> implements $AppErrorCopyWith<$Res> {
  factory _$$AIErrorImplCopyWith(
          _$AIErrorImpl value, $Res Function(_$AIErrorImpl) then) =
      __$$AIErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String message,
      String? details,
      ErrorSeverity severity,
      String? modelPath,
      bool isOutOfMemory});
}

/// @nodoc
class __$$AIErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$AIErrorImpl>
    implements _$$AIErrorImplCopyWith<$Res> {
  __$$AIErrorImplCopyWithImpl(
      _$AIErrorImpl _value, $Res Function(_$AIErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? details = freezed,
    Object? severity = null,
    Object? modelPath = freezed,
    Object? isOutOfMemory = null,
  }) {
    return _then(_$AIErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
      modelPath: freezed == modelPath
          ? _value.modelPath
          : modelPath // ignore: cast_nullable_to_non_nullable
              as String?,
      isOutOfMemory: null == isOutOfMemory
          ? _value.isOutOfMemory
          : isOutOfMemory // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$AIErrorImpl implements AIError {
  const _$AIErrorImpl(
      {required this.message,
      this.details,
      this.severity = ErrorSeverity.error,
      this.modelPath,
      this.isOutOfMemory = false});

  @override
  final String message;
  @override
  final String? details;
  @override
  @JsonKey()
  final ErrorSeverity severity;
  @override
  final String? modelPath;
  @override
  @JsonKey()
  final bool isOutOfMemory;

  @override
  String toString() {
    return 'AppError.ai(message: $message, details: $details, severity: $severity, modelPath: $modelPath, isOutOfMemory: $isOutOfMemory)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.modelPath, modelPath) ||
                other.modelPath == modelPath) &&
            (identical(other.isOutOfMemory, isOutOfMemory) ||
                other.isOutOfMemory == isOutOfMemory));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, message, details, severity, modelPath, isOutOfMemory);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIErrorImplCopyWith<_$AIErrorImpl> get copyWith =>
      __$$AIErrorImplCopyWithImpl<_$AIErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return ai(message, details, severity, modelPath, isOutOfMemory);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return ai?.call(message, details, severity, modelPath, isOutOfMemory);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (ai != null) {
      return ai(message, details, severity, modelPath, isOutOfMemory);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return ai(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return ai?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (ai != null) {
      return ai(this);
    }
    return orElse();
  }
}

abstract class AIError implements AppError {
  const factory AIError(
      {required final String message,
      final String? details,
      final ErrorSeverity severity,
      final String? modelPath,
      final bool isOutOfMemory}) = _$AIErrorImpl;

  @override
  String get message;
  String? get details;
  @override
  ErrorSeverity get severity;
  String? get modelPath;
  bool get isOutOfMemory;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIErrorImplCopyWith<_$AIErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotificationErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$NotificationErrorImplCopyWith(_$NotificationErrorImpl value,
          $Res Function(_$NotificationErrorImpl) then) =
      __$$NotificationErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String message,
      String? details,
      ErrorSeverity severity,
      bool isPermissionDenied});
}

/// @nodoc
class __$$NotificationErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$NotificationErrorImpl>
    implements _$$NotificationErrorImplCopyWith<$Res> {
  __$$NotificationErrorImplCopyWithImpl(_$NotificationErrorImpl _value,
      $Res Function(_$NotificationErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? details = freezed,
    Object? severity = null,
    Object? isPermissionDenied = null,
  }) {
    return _then(_$NotificationErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
      isPermissionDenied: null == isPermissionDenied
          ? _value.isPermissionDenied
          : isPermissionDenied // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$NotificationErrorImpl implements NotificationError {
  const _$NotificationErrorImpl(
      {required this.message,
      this.details,
      this.severity = ErrorSeverity.warning,
      this.isPermissionDenied = false});

  @override
  final String message;
  @override
  final String? details;
  @override
  @JsonKey()
  final ErrorSeverity severity;
  @override
  @JsonKey()
  final bool isPermissionDenied;

  @override
  String toString() {
    return 'AppError.notification(message: $message, details: $details, severity: $severity, isPermissionDenied: $isPermissionDenied)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.isPermissionDenied, isPermissionDenied) ||
                other.isPermissionDenied == isPermissionDenied));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, message, details, severity, isPermissionDenied);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationErrorImplCopyWith<_$NotificationErrorImpl> get copyWith =>
      __$$NotificationErrorImplCopyWithImpl<_$NotificationErrorImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return notification(message, details, severity, isPermissionDenied);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return notification?.call(message, details, severity, isPermissionDenied);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (notification != null) {
      return notification(message, details, severity, isPermissionDenied);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return notification(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return notification?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (notification != null) {
      return notification(this);
    }
    return orElse();
  }
}

abstract class NotificationError implements AppError {
  const factory NotificationError(
      {required final String message,
      final String? details,
      final ErrorSeverity severity,
      final bool isPermissionDenied}) = _$NotificationErrorImpl;

  @override
  String get message;
  String? get details;
  @override
  ErrorSeverity get severity;
  bool get isPermissionDenied;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationErrorImplCopyWith<_$NotificationErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$StorageErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$StorageErrorImplCopyWith(
          _$StorageErrorImpl value, $Res Function(_$StorageErrorImpl) then) =
      __$$StorageErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String message, String? path, String? details, ErrorSeverity severity});
}

/// @nodoc
class __$$StorageErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$StorageErrorImpl>
    implements _$$StorageErrorImplCopyWith<$Res> {
  __$$StorageErrorImplCopyWithImpl(
      _$StorageErrorImpl _value, $Res Function(_$StorageErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? path = freezed,
    Object? details = freezed,
    Object? severity = null,
  }) {
    return _then(_$StorageErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      path: freezed == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String?,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
    ));
  }
}

/// @nodoc

class _$StorageErrorImpl implements StorageError {
  const _$StorageErrorImpl(
      {required this.message,
      this.path,
      this.details,
      this.severity = ErrorSeverity.error});

  @override
  final String message;
  @override
  final String? path;
  @override
  final String? details;
  @override
  @JsonKey()
  final ErrorSeverity severity;

  @override
  String toString() {
    return 'AppError.storage(message: $message, path: $path, details: $details, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageErrorImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.severity, severity) ||
                other.severity == severity));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, message, path, details, severity);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StorageErrorImplCopyWith<_$StorageErrorImpl> get copyWith =>
      __$$StorageErrorImplCopyWithImpl<_$StorageErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return storage(message, path, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return storage?.call(message, path, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (storage != null) {
      return storage(message, path, details, severity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return storage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return storage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (storage != null) {
      return storage(this);
    }
    return orElse();
  }
}

abstract class StorageError implements AppError {
  const factory StorageError(
      {required final String message,
      final String? path,
      final String? details,
      final ErrorSeverity severity}) = _$StorageErrorImpl;

  @override
  String get message;
  String? get path;
  String? get details;
  @override
  ErrorSeverity get severity;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StorageErrorImplCopyWith<_$StorageErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ServiceErrorImplCopyWith<$Res>
    implements $AppErrorCopyWith<$Res> {
  factory _$$ServiceErrorImplCopyWith(
          _$ServiceErrorImpl value, $Res Function(_$ServiceErrorImpl) then) =
      __$$ServiceErrorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String serviceName,
      String operation,
      String message,
      String? details,
      ErrorSeverity severity});
}

/// @nodoc
class __$$ServiceErrorImplCopyWithImpl<$Res>
    extends _$AppErrorCopyWithImpl<$Res, _$ServiceErrorImpl>
    implements _$$ServiceErrorImplCopyWith<$Res> {
  __$$ServiceErrorImplCopyWithImpl(
      _$ServiceErrorImpl _value, $Res Function(_$ServiceErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serviceName = null,
    Object? operation = null,
    Object? message = null,
    Object? details = freezed,
    Object? severity = null,
  }) {
    return _then(_$ServiceErrorImpl(
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      operation: null == operation
          ? _value.operation
          : operation // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      details: freezed == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String?,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as ErrorSeverity,
    ));
  }
}

/// @nodoc

class _$ServiceErrorImpl implements ServiceError {
  const _$ServiceErrorImpl(
      {required this.serviceName,
      required this.operation,
      required this.message,
      this.details,
      this.severity = ErrorSeverity.error});

  @override
  final String serviceName;
  @override
  final String operation;
  @override
  final String message;
  @override
  final String? details;
  @override
  @JsonKey()
  final ErrorSeverity severity;

  @override
  String toString() {
    return 'AppError.service(serviceName: $serviceName, operation: $operation, message: $message, details: $details, severity: $severity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServiceErrorImpl &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.severity, severity) ||
                other.severity == severity));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, serviceName, operation, message, details, severity);

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ServiceErrorImplCopyWith<_$ServiceErrorImpl> get copyWith =>
      __$$ServiceErrorImplCopyWithImpl<_$ServiceErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        network,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? query, String? table)
        database,
    required TResult Function(
            String message, String? field, ErrorSeverity severity)
        validation,
    required TResult Function(
            String message, String? permission, ErrorSeverity severity)
        permission,
    required TResult Function(
            String message, String? details, ErrorSeverity severity)
        unknown,
    required TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)
        api,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, String? modelPath, bool isOutOfMemory)
        ai,
    required TResult Function(String message, String? details,
            ErrorSeverity severity, bool isPermissionDenied)
        notification,
    required TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)
        storage,
    required TResult Function(String serviceName, String operation,
            String message, String? details, ErrorSeverity severity)
        service,
  }) {
    return service(serviceName, operation, message, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult? Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult? Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult? Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult? Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult? Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult? Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult? Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
  }) {
    return service?.call(serviceName, operation, message, details, severity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String message, String? details, ErrorSeverity severity)?
        network,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? query, String? table)?
        database,
    TResult Function(String message, String? field, ErrorSeverity severity)?
        validation,
    TResult Function(
            String message, String? permission, ErrorSeverity severity)?
        permission,
    TResult Function(String message, String? details, ErrorSeverity severity)?
        unknown,
    TResult Function(String message, int? statusCode, String? details,
            ErrorSeverity severity)?
        api,
    TResult Function(String message, String? details, ErrorSeverity severity,
            String? modelPath, bool isOutOfMemory)?
        ai,
    TResult Function(String message, String? details, ErrorSeverity severity,
            bool isPermissionDenied)?
        notification,
    TResult Function(String message, String? path, String? details,
            ErrorSeverity severity)?
        storage,
    TResult Function(String serviceName, String operation, String message,
            String? details, ErrorSeverity severity)?
        service,
    required TResult orElse(),
  }) {
    if (service != null) {
      return service(serviceName, operation, message, details, severity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkError value) network,
    required TResult Function(DatabaseError value) database,
    required TResult Function(ValidationError value) validation,
    required TResult Function(PermissionError value) permission,
    required TResult Function(UnknownError value) unknown,
    required TResult Function(ApiError value) api,
    required TResult Function(AIError value) ai,
    required TResult Function(NotificationError value) notification,
    required TResult Function(StorageError value) storage,
    required TResult Function(ServiceError value) service,
  }) {
    return service(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkError value)? network,
    TResult? Function(DatabaseError value)? database,
    TResult? Function(ValidationError value)? validation,
    TResult? Function(PermissionError value)? permission,
    TResult? Function(UnknownError value)? unknown,
    TResult? Function(ApiError value)? api,
    TResult? Function(AIError value)? ai,
    TResult? Function(NotificationError value)? notification,
    TResult? Function(StorageError value)? storage,
    TResult? Function(ServiceError value)? service,
  }) {
    return service?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkError value)? network,
    TResult Function(DatabaseError value)? database,
    TResult Function(ValidationError value)? validation,
    TResult Function(PermissionError value)? permission,
    TResult Function(UnknownError value)? unknown,
    TResult Function(ApiError value)? api,
    TResult Function(AIError value)? ai,
    TResult Function(NotificationError value)? notification,
    TResult Function(StorageError value)? storage,
    TResult Function(ServiceError value)? service,
    required TResult orElse(),
  }) {
    if (service != null) {
      return service(this);
    }
    return orElse();
  }
}

abstract class ServiceError implements AppError {
  const factory ServiceError(
      {required final String serviceName,
      required final String operation,
      required final String message,
      final String? details,
      final ErrorSeverity severity}) = _$ServiceErrorImpl;

  String get serviceName;
  String get operation;
  @override
  String get message;
  String? get details;
  @override
  ErrorSeverity get severity;

  /// Create a copy of AppError
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ServiceErrorImplCopyWith<_$ServiceErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
