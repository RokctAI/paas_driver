import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_result.freezed.dart';

@freezed
sealed class ApiResult<T> with _$ApiResult<T> {
  const ApiResult._();

  const factory ApiResult.success({required T data}) = Success<T>;

  const factory ApiResult.failure({required String error, int? statusCode}) =
      Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String error, int? statusCode) failure,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Failure<T>(error: final error, statusCode: final statusCode) => failure(
        error,
        statusCode,
      ),
    };
  }

  R maybeWhen<R>({
    R Function(T data)? success,
    R Function(String error, int? statusCode)? failure,
    required R Function() orElse,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success?.call(data) ?? orElse(),
      Failure<T>(error: final error, statusCode: final statusCode) =>
        failure?.call(error, statusCode) ?? orElse(),
    };
  }
}
