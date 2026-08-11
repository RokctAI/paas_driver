import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/material.dart';

/// Who may sign in to THIS composed app, and where each allowed role lands.
///
/// auth_sdk is the source of truth for auth flows across every composed app
/// (customer, manager, driver, ...), but the apps disagree about what a
/// successful credential exchange MEANS: the customer apps accept any
/// account and land it on the marketplace, while manager only admits
/// sellers (and drops everyone else back at login), and driver will only
/// admit drivers. That app-specific answer is composition DATA, not code:
/// an SDK's manifest declares a "session_policy" (normally the home SDK,
/// gated under "app_type" so e.g. merchants_sdk can scope it to manager
/// builds), the installer injects it into the installed
/// auth_session_policy.dart shell, and the login flow consults [I] at the
/// points where it used to hard-code the landing.
///
/// The base class IS the default policy — allow every account and land it
/// exactly where auth_sdk always did (`isDemo ? replaceUiTypeRoute :
/// goHome`). Apps whose composition declares no "session_policy" never
/// reassign [I], so they keep today's behavior to the letter.
class AuthSessionPolicy {
  const AuthSessionPolicy();

  /// The policy the login flow consults. Reassigned (before LoginPage is
  /// built) by the installed auth_session_policy.dart shell when the app's
  /// composition declares one; untouched otherwise.
  static AuthSessionPolicy I = const AuthSessionPolicy();

  /// Whether an account with [role] may hold a session in this app.
  /// [role] is null when the backend sent no role — and for OFFLINE logins,
  /// where the role cannot be verified at all, so a role-gated policy
  /// deliberately rejects offline sessions.
  bool allows(String? role) => true;

  /// Where an allowed account lands right after sign-in. Only called when
  /// [allows] returned true for [role].
  void onAuthenticated(BuildContext context, {String? role}) {
    if (AppConstants.isDemo) {
      AppRoutes.I.replaceUiTypeRoute(context);
    } else {
      AppHelpers.goHome(context);
    }
  }

  /// What happens to an account [allows] turned away. The login flow has
  /// NOT persisted a token when this runs (or has already removed the
  /// offline one), so the rejected account holds no session. The default
  /// policy never rejects, so this base implementation is a no-op.
  void onRejected(BuildContext context, {String? role}) {}
}

/// The policy shape the installer builds from a manifest "session_policy"
/// declaration — pure data: allowed role -> landing route path, plus how a
/// rejection is presented.
///
/// Landing/rejection targets are route PATHS (navigated via
/// `context.router.replaceNamed`), not generated route classes or AppRoutes
/// methods: route classes exist only in the host app, and base_sdk's
/// AppRoutes interface is fixed — path navigation is the same sanctioned
/// bridge RegistrationFlow.completeRegistration() already uses to reach
/// '/registration-steps' (ADR-005).
class DeclaredSessionPolicy extends AuthSessionPolicy {
  /// role -> landing route path (e.g. {'seller': '/main'}). An account
  /// whose role is not a key here is rejected.
  final Map<String, String> roleLandings;

  /// Translation key (a TrKeys VALUE, e.g. 'access.denied') of the message
  /// shown via a top snackbar when an account is rejected. Resolved through
  /// AppHelpers.getTranslation, which humanizes the key itself when no
  /// translation exists. Null shows nothing.
  final String? rejectionMessageTrKey;

  /// Route path a rejected account is sent to. Null stays on the current
  /// page (the login screen the attempt was made from).
  final String? rejectionRoute;

  const DeclaredSessionPolicy({
    required this.roleLandings,
    this.rejectionMessageTrKey,
    this.rejectionRoute,
  });

  @override
  bool allows(String? role) => role != null && roleLandings.containsKey(role);

  @override
  void onAuthenticated(BuildContext context, {String? role}) {
    final landing = roleLandings[role];
    if (landing == null) {
      // Unreachable when the login flow gates on allows(); kept safe anyway.
      super.onAuthenticated(context, role: role);
      return;
    }
    context.router.replaceNamed(landing);
  }

  @override
  void onRejected(BuildContext context, {String? role}) {
    // A rejected account must not keep a session: the login flow skips
    // persisting the online token before calling this, and the offline path
    // stores one before the role is known — deleting here covers both.
    LocalStorage.deleteToken();
    final trKey = rejectionMessageTrKey;
    if (trKey != null) {
      AppHelpers.showCheckTopSnackBar(
        context,
        AppHelpers.getTranslation(trKey),
      );
    }
    final route = rejectionRoute;
    if (route != null) {
      context.router.replaceNamed(route);
    }
  }
}
