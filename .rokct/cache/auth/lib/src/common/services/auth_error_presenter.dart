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
