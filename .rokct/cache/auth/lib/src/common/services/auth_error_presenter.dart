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

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// TrKeys-style key (same convention as [trOfflineSignUpDeferred] in
/// register_notifier.dart): backend translations can override it;
/// AppHelpers.getTranslation's fallback renders it as "We could not verify
/// that code please try again".
const String trCouldNotVerifyCode =
    'we_could_not_verify_that_code_please_try_again';

/// Standing rule (Ray): a student sees only a friendly line; the real
/// cause — the verbatim server/exception detail plus status code — goes
/// to admins through the one telemetry door (base_sdk [TelemetryClient],
/// backend `log_frontend_error` pipeline).
///
/// This is deliberately NOT an error-mapping framework. It is the two
/// existing compliant patterns from the agent repo, shared by the auth
/// notifiers so each snackbar site doesn't hand-roll the same lines:
///
///  * the assistant-chat pattern (assistant_service.dart):
///    `TelemetryClient.I.logError(type: ..., context: {status_code,
///    server_message, ...})`, then only a friendly line on screen;
///  * the homework refusal split (http_homework_repository.dart):
///    a server reply whose copy is authored for the student is shown
///    verbatim; every other failure is technical detail for telemetry.
abstract class AuthErrorPresenter {
  AuthErrorPresenter._();

  /// Mirrors NetworkExceptions.getDioStatus semantics (see
  /// RegisterNotifier._isDefinitiveRejection): connection failures and
  /// timeouts surface as 500/408, so only a concrete 4xx is a definitive
  /// backend rejection — the statuses on which this backend's `message`
  /// field carries copy written for the person at the screen (wrong
  /// password, email already registered, code not accepted).
  static bool _isDefinitiveRejection(int status) =>
      status >= 400 && status < 500 && status != 408;

  /// AppHelpers.errorHandler degrades to `e.toString()` / HTML `<title>`
  /// scraping when the reply carries no server-authored `message`; those
  /// strings are technical detail, never student copy.
  static bool _looksTechnical(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return true;
    final lower = trimmed.toLowerCase();
    return lower == 'null' ||
        lower.contains('exception') ||
        lower.contains('stack trace') ||
        lower.contains('<html') ||
        lower.contains('<!doctype') ||
        lower.contains('xmlhttprequest');
  }

  /// Failure branch of an ApiResult: a definitive 4xx whose message reads
  /// as server-authored user copy is shown verbatim (an expected user
  /// outcome — no telemetry, same as a homework refusal); everything else
  /// shows only [friendly] while the raw detail goes to telemetry.
  static void show(
    BuildContext context, {
    required String type,
    required String failure,
    required int statusCode,
    String? friendly,
    Map<String, String> extra = const {},
  }) {
    if (_isDefinitiveRejection(statusCode) && !_looksTechnical(failure)) {
      AppHelpers.showCheckTopSnackBar(context, failure);
      return;
    }
    showTechnical(
      context,
      type: type,
      detail: failure,
      statusCode: statusCode,
      friendly: friendly,
      extra: extra,
    );
  }

  /// Unconditional technical branch, for failures that are never student
  /// copy (thrown exceptions, third-party SDK error text): fire-and-forget
  /// telemetry carrying the verbatim [detail] (+ status code), then only a
  /// friendly translated line on screen.
  static void showTechnical(
    BuildContext context, {
    required String type,
    required String detail,
    int? statusCode,
    String? friendly,
    Map<String, String> extra = const {},
  }) {
    unawaited(
      TelemetryClient.I.logError(
        type: type,
        context: {
          'status_code': '${statusCode ?? ''}',
          'server_message': detail,
          ...extra,
        },
      ),
    );
    AppHelpers.showCheckTopSnackBar(
      context,
      friendly ??
          AppHelpers.getTranslation(TrKeys.somethingWentWrongWithTheServer),
    );
  }
}
