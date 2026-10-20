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

import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/services/session_handoff.dart';
import 'package:base_sdk/src/services/session_start_hooks.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import 'package:auth_sdk/src/common/domain/interface/auth_session_policy.dart';
import 'package:auth_sdk/src/common/services/platform_support.dart';
import 'package:auth_sdk/src/common/services/session_handoff_service.dart';

/// Boot-time driver for shared sign-in between the fleet's own apps
/// (Ray: "its one device and same account so i expect them to use same
/// token").
///
/// Installed into the composed app's `main()` by auth_sdk's manifest
/// `boot_hooks` entry (`SessionHandoffGate.install();`), like
/// [PendingOtpGate] and RestoreCredentialGate:
///
///   * SENDING: plugs [SessionHandoffService.buildPayload] into base_sdk's
///     SessionHandoff.payloadProvider, so the launcher's app opens carry a
///     sign-in (launch_sdk's LaunchNotifier.startApp).
///   * RECEIVING: on the first frame, on every resume, and whenever the
///     native side reports a new hand-off, it takes the pending hand-off
///     and lets [SessionHandoffService.accept] sign the app in. Then it
///     lands the account where [AuthSessionPolicy] says, or presents the
///     policy's rejection (the manager still admits sellers only).
///
/// Nothing here fails loudly: a hand-off that does not work leaves the app
/// exactly where an ordinary open would.
class SessionHandoffGate with WidgetsBindingObserver {
  SessionHandoffGate._();

  static final SessionHandoffGate instance = SessionHandoffGate._();

  @visibleForTesting
  static SessionHandoffService service = SessionHandoffService(
    repository: _authRepository,
  );

  /// Routes a landing must not happen over (the splash decides its own
  /// next route; the other two are dead ends).
  static const Set<String> _blockedTopRoutes = {
    'SplashRoute',
    'NoConnectionRoute',
    'MaintenanceRoute',
  };

  bool _installed = false;
  bool _busy = false;
  HandoffOutcome? _pendingLanding;
  bool _landingScheduled = false;

  /// Boot hook entry point. Safe to call more than once.
  static void install() {
    SessionHandoff.payloadProvider = service.buildPayload;
    if (instance._installed) return;
    instance._installed = true;
    WidgetsBinding.instance.addObserver(instance);
    SessionHandoff.addListener(instance.recheck);
    // After the first frame: boot hooks run before LocalStorage.init(),
    // and the token read in accept() must be the real one.
    WidgetsBinding.instance.addPostFrameCallback((_) => instance.recheck());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) recheck();
  }

  /// Takes the pending hand-off, if any, and acts on it.
  Future<void> recheck() async {
    if (_busy) return;
    _busy = true;
    try {
      final SessionHandoffPayload? payload = await SessionHandoff.takePending();
      if (payload == null) return;
      final HandoffOutcome outcome = await service.accept(payload);
      if (outcome.kind == HandoffOutcomeKind.ignored) return;
      if (outcome.kind == HandoffOutcomeKind.online) {
        final UserRepositoryFacade? users = _userRepository();
        if (users != null) {
          unawaited(completeSessionStart(users));
        } else {
          unawaited(SessionStartHooks.run());
        }
      } else if (outcome.kind == HandoffOutcomeKind.offline) {
        unawaited(SessionStartHooks.run());
      }
      _pendingLanding = outcome;
      _scheduleLanding();
    } catch (e) {
      debugPrint('==> session handoff gate skipped: ${e.runtimeType}');
    } finally {
      _busy = false;
    }
  }

  void _scheduleLanding() {
    if (_landingScheduled) return;
    _landingScheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback(_onFrame);
    binding.scheduleFrame();
  }

  void _onFrame(Duration _) {
    _landingScheduled = false;
    final HandoffOutcome? outcome = _pendingLanding;
    if (outcome == null) return;
    final NavigatorState? navigator = _rootNavigator();
    if (navigator == null || !_topRouteAllowsLanding(navigator)) {
      // Still on the splash, or the tree is not up yet: look again on the
      // next frame.
      _scheduleLanding();
      return;
    }
    _pendingLanding = null;
    final BuildContext context = navigator.context;
    try {
      switch (outcome.kind) {
        case HandoffOutcomeKind.online:
          AuthSessionPolicy.I.onAuthenticated(context, role: outcome.role);
        case HandoffOutcomeKind.offline:
          if (outcome.role != null) {
            AuthSessionPolicy.I.onAuthenticated(context, role: outcome.role);
          } else {
            AuthSessionPolicy.I.onOfflineAuthenticated(context);
          }
        case HandoffOutcomeKind.rejected:
          AuthSessionPolicy.I.onRejected(context, role: outcome.role);
        case HandoffOutcomeKind.ignored:
          break;
      }
    } catch (e) {
      debugPrint('==> session handoff landing skipped: ${e.runtimeType}');
    }
  }

  /// The app's root navigator (same lookup as PendingOtpGate: SDK code
  /// cannot reach the host's router instance, but the widget tree is
  /// public).
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

  bool _topRouteAllowsLanding(NavigatorState navigator) {
    if (navigator.overlay == null) return false;
    final pages = navigator.widget.pages;
    if (pages.isEmpty) return true;
    return !_blockedTopRoutes.contains(pages.last.name ?? '');
  }

  static AuthRepositoryFacade? _authRepository() {
    try {
      if (GetIt.instance.isRegistered<AuthRepositoryFacade>()) {
        return GetIt.instance<AuthRepositoryFacade>();
      }
    } catch (_) {}
    return null;
  }

  static UserRepositoryFacade? _userRepository() {
    try {
      if (GetIt.instance.isRegistered<UserRepositoryFacade>()) {
        return GetIt.instance<UserRepositoryFacade>();
      }
    } catch (_) {}
    return null;
  }
}
