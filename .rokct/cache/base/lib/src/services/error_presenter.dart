// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Standing rule (decision-log entry 56): a student sees only a friendly
/// line; the real cause — the verbatim server/exception detail plus status
/// code — goes to admins through the one telemetry door ([TelemetryClient],
/// backend `log_frontend_error` pipeline).
///
/// This is the fleet-general promotion of auth_sdk's `AuthErrorPresenter`
/// (users repo, PR #36), which itself generalised two compliant patterns
/// from the agent repo:
///
///  * the assistant-chat pattern (assistant_service.dart):
///    `TelemetryClient.I.logError(type: ..., context: {status_code,
///    server_message, ...})`, then only a friendly line on screen;
///  * the homework refusal split (http_homework_repository.dart):
///    a server reply whose copy is authored for the student is shown
///    verbatim; every other failure is technical detail for telemetry.
///
/// It is the documented partner of `NetworkHelpers.errorHandler`: that
/// helper extracts the raw (admin-grade) detail string, and this class
/// decides what the person at the screen is allowed to see — either a
/// server-authored 4xx line meant for them, or a friendly translated
/// fallback while the detail rides to telemetry. Student-facing surfaces
/// should reach it through `NetworkHelpers.friendlyErrorHandler` (string
/// producing) or [show]/[showTechnical] (snackbar producing); admin
/// surfaces may keep consuming the raw `errorHandler` string directly.
abstract class ErrorPresenter {
  ErrorPresenter._();

  /// Mirrors NetworkExceptions.getDioStatus semantics: connection failures
  /// and timeouts surface as 500/408, so only a concrete 4xx is a
  /// definitive backend rejection — the statuses on which this backend's
  /// `message` field carries copy written for the person at the screen
  /// (wrong password, email already registered, code not accepted).
  static bool isDefinitiveRejection(int? status) =>
      status != null && status >= 400 && status < 500 && status != 408;

  /// The raw extraction chains (NetworkHelpers.errorHandler,
  /// AppHelpers.errorHandler) degrade to `e.toString()` / HTML `<title>`
  /// scraping when the reply carries no server-authored `message`; those
  /// strings are technical detail, never student copy.
  static bool looksTechnical(String message) {
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

  /// Pure string form of [show], for surfaces that render an error string
  /// themselves (state fields, inline text) rather than a snackbar.
  ///
  /// A definitive 4xx whose [detail] reads as server-authored user copy is
  /// returned verbatim (an expected user outcome — no telemetry); every
  /// other failure fires fire-and-forget telemetry carrying the verbatim
  /// [detail] (+ status code) and returns only [friendly] (defaulting to
  /// the translated "something went wrong" line).
  static String resolve({
    required String type,
    required String detail,
    int? statusCode,
    String? friendly,
    Map<String, String> extra = const {},
  }) {
    if (isDefinitiveRejection(statusCode) && !looksTechnical(detail)) {
      return detail;
    }
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
    return friendly ?? _defaultFriendly();
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
    if (isDefinitiveRejection(statusCode) && !looksTechnical(failure)) {
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
    AppHelpers.showCheckTopSnackBar(context, friendly ?? _defaultFriendly());
  }

  /// Translated friendly line, with a hard fallback for callers that run
  /// before LocalStorage is initialized (same guard as
  /// AppHelpers._presentable).
  static String _defaultFriendly() {
    try {
      final line = AppHelpers.getTranslation(
        TrKeys.somethingWentWrongWithTheServer,
      ).trim();
      if (line.isNotEmpty && line != 'null') return line;
    } catch (_) {
      // Fall through to the literal below.
    }
    return 'Something went wrong. Please try again.';
  }
}
