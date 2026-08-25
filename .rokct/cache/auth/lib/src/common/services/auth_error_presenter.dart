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

import 'package:flutter/widgets.dart';
import 'package:base_sdk/src/services/error_presenter.dart';

/// TrKeys-style key (same convention as [trOfflineSignUpDeferred] in
/// register_notifier.dart): backend translations can override it;
/// AppHelpers.getTranslation's fallback renders it as "We could not verify
/// that code please try again".
const String trCouldNotVerifyCode =
    'we_could_not_verify_that_code_please_try_again';

/// Standing rule (Ray): a student sees only a friendly line; the real
/// cause — the verbatim server/exception detail plus status code — goes
/// to admins through the one telemetry door (base_sdk TelemetryClient,
/// backend `log_frontend_error` pipeline).
///
/// This presenter has been promoted into base_sdk as the fleet-general
/// [ErrorPresenter] (core repo, `lib/src/services/error_presenter.dart`),
/// the documented partner of `NetworkHelpers.errorHandler`. This class
/// remains as a thin delegating alias so the auth notifiers' 33 existing
/// call sites (and any external importers) keep working unchanged; new
/// code should call [ErrorPresenter] directly.
abstract class AuthErrorPresenter {
  AuthErrorPresenter._();

  /// Failure branch of an ApiResult: a definitive 4xx whose message reads
  /// as server-authored user copy is shown verbatim (an expected user
  /// outcome — no telemetry, same as a homework refusal); everything else
  /// shows only [friendly] while the raw detail goes to telemetry.
  ///
  /// Delegates to [ErrorPresenter.show].
  static void show(
    BuildContext context, {
    required String type,
    required String failure,
    required int statusCode,
    String? friendly,
    Map<String, String> extra = const {},
  }) => ErrorPresenter.show(
    context,
    type: type,
    failure: failure,
    statusCode: statusCode,
    friendly: friendly,
    extra: extra,
  );

  /// Unconditional technical branch, for failures that are never student
  /// copy (thrown exceptions, third-party SDK error text): fire-and-forget
  /// telemetry carrying the verbatim [detail] (+ status code), then only a
  /// friendly translated line on screen.
  ///
  /// Delegates to [ErrorPresenter.showTechnical].
  static void showTechnical(
    BuildContext context, {
    required String type,
    required String detail,
    int? statusCode,
    String? friendly,
    Map<String, String> extra = const {},
  }) => ErrorPresenter.showTechnical(
    context,
    type: type,
    detail: detail,
    statusCode: statusCode,
    friendly: friendly,
    extra: extra,
  );
}
