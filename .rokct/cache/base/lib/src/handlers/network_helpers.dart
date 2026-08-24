// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// compliance-ignore-file: flutter-http-timeout
// The package:dio import below is only for the DioException type used in
// error-message parsing. The actual client comes from base_sdk's HttpService
// (dioHttp), which sets connectTimeout and receiveTimeout (30s) centrally on
// its BaseOptions; no HTTP client is created in this file.

import 'package:dio/dio.dart';

import 'package:base_sdk/src/services/error_presenter.dart';

abstract class NetworkHelpers {
  NetworkHelpers._();

  /// Friendly-by-default counterpart of [errorHandler] for STUDENT-FACING
  /// surfaces (standing rule, decision-log entry 56: a student sees one
  /// friendly line; admin detail goes to telemetry).
  ///
  /// Extracts the raw detail with the unchanged [errorHandler] chain, then
  /// hands it to [ErrorPresenter.resolve]: a definitive 4xx whose message
  /// is server-authored user copy comes back verbatim; every other failure
  /// fires fire-and-forget telemetry (`TelemetryClient` →
  /// `log_frontend_error`) carrying the verbatim detail plus status code,
  /// and returns only [friendly] (defaulting to the translated "something
  /// went wrong" line). Strictly additive: admin surfaces keep calling
  /// [errorHandler] and see the raw string exactly as before.
  ///
  /// [type] is a stable snake_case event class for telemetry, e.g.
  /// 'subscription_fetch_failed'.
  static String friendlyErrorHandler(
    dynamic e, {
    required String type,
    String? friendly,
    Map<String, String> extra = const {},
  }) {
    final int? statusCode = e is DioException ? e.response?.statusCode : null;
    return ErrorPresenter.resolve(
      type: type,
      detail: errorHandler(e),
      statusCode: statusCode,
      friendly: friendly,
      extra: extra,
    );
  }

  /// Raw (admin-grade) extraction chain: the server's `message` field,
  /// then HTML `<title>` scraping, then `error.message`, then
  /// `e.toString()`. Unchanged behavior, kept for admin surfaces and
  /// existing consumers; student-facing surfaces should prefer
  /// [friendlyErrorHandler].
  static String errorHandler(dynamic e) {
    try {
      return (e.runtimeType == DioException)
          ? ((e as DioException).response?.data["message"] == "Bad request."
                ? (e.response?.data["params"] as Map).values.first[0]
                : e.response?.data["message"])
          : e.toString();
    } catch (s) {
      try {
        return (e.runtimeType == DioException)
            ? ((e as DioException).response?.data.toString().substring(
                (e.response?.data.toString().indexOf("<title>") ?? 0) + 7,
                e.response?.data.toString().indexOf("</title") ?? 0,
              )).toString()
            : e.toString();
      } catch (r) {
        try {
          return (e.runtimeType == DioException)
              ? ((e as DioException).response?.data["error"]["message"])
                    .toString()
              : e.toString();
        } catch (f) {
          return e.toString();
        }
      }
    }
  }
}
