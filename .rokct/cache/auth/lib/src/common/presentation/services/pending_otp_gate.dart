// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:auth_sdk/src/common/domain/interface/deferred_otp_email_resend.dart';
import 'package:auth_sdk/src/common/infrastructure/services/offline_auth_service.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/confirmation/register_confirmation_page.dart';

/// Routes a synced-but-unverified deferred registration into the existing
/// OTP confirmation sheet — the UX hook for the flag
/// [OfflineAuthService.pendingOtpKey] that a background sync records.
///
/// The sync itself runs with no BuildContext, so this gate is installed
/// into the composed app's `main()` by auth_sdk's manifest `boot_hooks`
/// entry (`PendingOtpGate.install();`) and does its work from frame and
/// lifecycle callbacks:
///
///   * boot: `install()` checks the flag and arms a post-frame watch, which
///     fires once the router has settled past the splash — the next open of
///     an app whose account synced in a previous session prompts right on
///     top of wherever the session restore landed;
///   * mid-session sync: [OfflineAuthService.onPendingOtpFlagged] (assigned
///     in `install()`) re-arms the watch the moment `syncOne` records the
///     flag, so a sync completing while the user is in the app prompts
///     promptly, without waiting for the next boot;
///   * app resume: the [WidgetsBindingObserver] hook re-checks whenever the
///     app returns to the foreground (covers "sheet dismissed last time"
///     and "was offline when we tried to send the code").
///
/// The gate only ever prompts the flagged account's OWN session: a deferred
/// account's backend password is unknown to the user (sync sends a random
/// one), so its session token can only be the `backendToken` the sync
/// recorded (activated by `syncOne` or restored by `loginOffline`) — or,
/// against a backend whose register endpoint mints no token until OTP
/// completes, the row's own `offline:<id>` token. Both forms are exact
/// per-account matches (see [_PendingOtpTarget.matchesSession]), so a
/// *different* logged-in account is never asked to verify someone else's
/// phone/email.
///
/// It cannot loop: the confirmation notifier clears the flag on verify
/// success (verifyPhone / verifyEmail — the two exits the deferred sheet
/// can take), and a dismissal leaves the flag set but disarms the watch
/// until the next boot / resume / sync — one prompt per trigger, never a
/// re-prompt storm. The existing UX has no explicit skip affordance, so
/// nothing else clears the flag.
class PendingOtpGate with WidgetsBindingObserver {
  PendingOtpGate._();

  static final PendingOtpGate instance = PendingOtpGate._();

  /// Route names the prompt must not appear over: the splash replaces
  /// itself (a `replace` would target our sheet, not the splash), and the
  /// other two are dead ends where an OTP sheet is useless noise.
  static const Set<String> _blockedTopRoutes = {
    'SplashRoute',
    'NoConnectionRoute',
    'MaintenanceRoute',
  };

  _PendingOtpTarget? _pendingRow;
  bool _armed = false;
  bool _frameCallbackScheduled = false;
  bool _prompting = false;
  bool _installed = false;
  bool _rotationFrameScheduled = false;
  bool _rotationInFlight = false;

  /// Boot-hook entry point (see auth_sdk's manifest `boot_hooks`). Runs in
  /// `main()` right after `WidgetsFlutterBinding.ensureInitialized()`, so
  /// it must not touch LocalStorage (not yet initialized there) — the
  /// token checks all happen inside frame callbacks, which only fire after
  /// `runApp`. Idempotent (hot-restart safe).
  static void install() {
    OfflineAuthService.onPendingOtpFlagged = instance.recheck;
    if (!instance._installed) {
      instance._installed = true;
      WidgetsBinding.instance.addObserver(instance);
    }
    instance.recheck();
    // Retry any pending forced password rotation (deferred accounts whose
    // rotation call failed at verify time). Post-frame like everything
    // else here: LocalStorage isn't initialized yet at install() time.
    instance._scheduleRotationRetry();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      recheck();
      _scheduleRotationRetry();
    }
  }

  /// Arms a one-shot post-frame retry of any pending forced password
  /// rotation (see OfflineAuthService.retryPendingPasswordRotations).
  /// Strictly best-effort: it only acts when a real (non-`offline:`)
  /// session token is active, swallows every failure, and leaves the
  /// persisted pending flag in place for the next boot/resume trigger —
  /// it can never block or break startup, login, or verification.
  void _scheduleRotationRetry() {
    if (_rotationFrameScheduled) return;
    _rotationFrameScheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback(_onRotationFrame);
    binding.scheduleFrame();
  }

  Future<void> _onRotationFrame(Duration _) async {
    _rotationFrameScheduled = false;
    if (_rotationInFlight) return;
    _rotationInFlight = true;
    try {
      final token = LocalStorage.getToken();
      if (token.isEmpty || OfflineAuthService.isOfflineToken(token)) return;
      final repo = GetIt.instance<AuthRepositoryFacade>();
      await OfflineAuthService().retryPendingPasswordRotations(repo);
    } catch (_) {
      // Non-fatal by contract; retried on the next boot/resume.
    } finally {
      _rotationInFlight = false;
    }
  }

  /// Re-reads the flag and (re-)arms the frame watch when a deferred
  /// account is waiting on OTP. Safe to call from anywhere, any time.
  Future<void> recheck() async {
    if (_prompting) return;
    final offlineAuth = OfflineAuthService();
    final pending = await offlineAuth.pendingOtpVerification();
    if (pending == null) {
      _armed = false;
      _pendingRow = null;
      return;
    }
    final localUserId = (pending['localUserId'] ?? '') as String;
    final row =
        localUserId.isEmpty ? null : await offlineAuth.findById(localUserId);
    if (row == null) {
      // The local row is gone (e.g. discarded); the flag can never be
      // actioned, so drop it instead of re-checking it forever.
      await offlineAuth.clearPendingOtpVerification();
      _armed = false;
      _pendingRow = null;
      return;
    }
    if (!row.synced) return;
    final String backendToken = row.backendToken ?? '';
    _pendingRow = _PendingOtpTarget(
      localUserId: localUserId,
      phone: row.phone ?? '',
      email: row.email ?? '',
      firstName: row.firstName,
      lastName: row.lastName,
      backendToken: backendToken,
    );
    _armed = true;
    _scheduleFrameCheck();
  }

  void _scheduleFrameCheck() {
    if (_frameCallbackScheduled) return;
    _frameCallbackScheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback(_onFrame);
    // Post-frame callbacks only run when a frame renders; make sure at
    // least one comes even if the app is idle right now.
    binding.scheduleFrame();
  }

  void _onFrame(Duration _) {
    _frameCallbackScheduled = false;
    if (!_armed || _prompting) return;
    final row = _pendingRow;
    if (row == null) {
      _armed = false;
      return;
    }
    final token = LocalStorage.getToken();
    final bool sessionReady = token.isNotEmpty && row.matchesSession(token);
    final navigator = sessionReady ? _rootNavigator() : null;
    if (navigator == null || !_topRouteAllowsPrompt(navigator)) {
      // Not this frame (still on splash, still logged out, tree not up
      // yet). Stay armed and look again on the next rendered frame — route
      // changes and user interaction all render frames, so the watch wakes
      // exactly when something happens, at zero cost while idle.
      _scheduleFrameCheck();
      return;
    }
    _armed = false;
    _prompt(navigator);
  }

  /// The app's ROOT navigator (the one `MaterialApp.router` builds from the
  /// host's generated router). SDK code can't reach the host's router
  /// instance (ADR-005 — it's private to the composed app_widget), but the
  /// widget tree is public Flutter surface: the first NavigatorState below
  /// the root element IS that router's navigator.
  NavigatorState? _rootNavigator() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;
    NavigatorState? navigator;
    void visit(Element element) {
      if (navigator != null) return;
      if (element is StatefulElement && element.state is NavigatorState) {
        navigator = element.state as NavigatorState;
        return;
      }
      element.visitChildren(visit);
    }

    visit(root);
    return navigator;
  }

  bool _topRouteAllowsPrompt(NavigatorState navigator) {
    if (navigator.overlay == null) return false;
    final pages = navigator.widget.pages;
    if (pages.isEmpty) return true;
    return !_blockedTopRoutes.contains(pages.last.name ?? '');
  }

  Future<void> _prompt(NavigatorState navigator) async {
    _prompting = true;
    try {
      final offlineAuth = OfflineAuthService();
      // Re-verify the flag right before prompting — it may have been
      // cleared (e.g. verification completed from another path) between
      // arming and this frame.
      if (await offlineAuth.pendingOtpVerification() == null) return;
      final row = _pendingRow;
      if (row == null) return;
      if (!await AppConnectivity.connectivity()) {
        // Can't send a code; the flag stays set and the next
        // boot/resume/sync trigger tries again.
        return;
      }

      final repo = GetIt.instance<AuthRepositoryFacade>();
      final String phone = row.phone;
      final String email = row.email;
      final bool phoneFlow = phone.isNotEmpty;
      String verificationId = '';
      bool sent = false;
      if (phoneFlow) {
        // Backend OTP pair (sendOtp/verifyPhone) even under
        // AppConstants.isPhoneFirebase — see RegisterConfirmationPage
        // .isDeferredOtp: only verifyPhone lifts the backend's
        // unverified-account limit for an account that already exists.
        final response = await repo.sendOtp(phone: phone);
        response.when(
          success: (data) {
            final verifyId = data.data?.verifyId ?? '';
            // verifyPhone treats the verifyId as the phone identity; fall
            // back to the number itself if the backend echoes none.
            verificationId = verifyId.isNotEmpty ? verifyId : phone;
            sent = true;
          },
          failure: (failure, status) {
            debugPrint('==> deferred OTP send (phone) failure: $failure');
          },
        );
      } else if (email.isNotEmpty && repo is DeferredOtpEmailResend) {
        // Explicit cast: DeferredOtpEmailResend is unrelated to the facade
        // type, so the `is` check can't promote `repo`.
        final response = await (repo as DeferredOtpEmailResend)
            .resendVerificationEmail(email: email);
        response.when(
          success: (_) => sent = true,
          failure: (failure, status) {
            debugPrint('==> deferred OTP send (email) failure: $failure');
          },
        );
      }
      if (!sent) return;

      final context = navigator.overlay?.context;
      if (context == null || !context.mounted) return;
      // Same presentation as every other entry into the confirmation sheet
      // (AppHelpers.showCustomModalBottomSheet), inlined so the sheet's
      // dismissal can be awaited and the gate released exactly when it
      // closes.
      await showModalBottomSheet(
        context: context,
        isDismissible: true,
        enableDrag: true,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height - 200.r,
        ),
        backgroundColor: AppStyle.transparent,
        builder: (context) => RegisterConfirmationPage(
          isDeferredOtp: true,
          verificationId: phoneFlow ? verificationId : '',
          // Same shape the online flow passes: the sheet displays and
          // resends to `email`, which carries the flow's identifier
          // (phone-or-email, matching SignUpType conventions).
          userModel: UserModel(
            firstname: row.firstName,
            lastname: row.lastName,
            phone: phoneFlow ? phone : null,
            email: phoneFlow ? phone : email,
          ),
        ),
      );
    } finally {
      _prompting = false;
    }
  }
}

/// The slice of the deferred account's local row the gate needs, captured
/// at recheck time. Deliberately NOT the drift row type: `OfflineUserEntity`
/// only exists after the host app's build_runner pass, and naming it here
/// would break auth_sdk's standalone analysis.
class _PendingOtpTarget {
  final String localUserId;
  final String phone;
  final String email;
  final String? firstName;
  final String? lastName;

  /// May be EMPTY: a backend whose register endpoint never mints a token
  /// (OTP completion mints the first one — the limited-until-OTP login
  /// gate) syncs the row with no token, and the session then continues
  /// under the row's own `offline:<id>` token.
  final String backendToken;

  const _PendingOtpTarget({
    required this.localUserId,
    required this.phone,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.backendToken,
  });

  /// True when [token] is THIS row's session — either the backend token
  /// the sync recorded, or (when none was minted, see [backendToken]) the
  /// row's own offline token. Both forms are exact per-account matches, so
  /// a different logged-in account is never prompted to verify someone
  /// else's phone/email.
  bool matchesSession(String token) =>
      (backendToken.isNotEmpty && token == backendToken) ||
      token == 'offline:$localUserId';
}
