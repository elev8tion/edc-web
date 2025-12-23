import 'package:freezed_annotation/freezed_annotation.dart';
import '../error/app_error.dart';

part 'app_state.freezed.dart';

@freezed
class AppState<T> with _$AppState<T> {
  const factory AppState.loading() = Loading<T>;
  const factory AppState.data(T data) = Data<T>;
  const factory AppState.error(AppError error) = Error<T>;
  const factory AppState.empty() = Empty<T>;
}

extension AppStateExtension<T> on AppState<T> {
  bool get isLoading => this is Loading<T>;
  bool get hasData => this is Data<T>;
  bool get hasError => this is Error<T>;
  bool get isEmpty => this is Empty<T>;

  T? get dataOrNull => maybeWhen(
        data: (data) => data,
        orElse: () => null,
      );

  AppError? get errorOrNull => maybeWhen(
        error: (error) => error,
        orElse: () => null,
      );
}