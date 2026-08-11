// Host composition file (ADR-005). auth_sdk's real pages (LoginPage,
// RegisterPage, ResetPasswordPage, RegisterConfirmationPage) are
// @RoutePage()-annotated inside auth_sdk itself, but auto_route's codegen
// in this app only generates route classes for @RoutePage widgets that
// live in the HOST's own lib/ — it never reaches into a path-dependency
// SDK's lib/ to generate one for a page defined there. Every other working
// route in this app (LessonRoute, ScheduleRoute, LibraryRoute, ...) follows
// this same pattern: a thin host wrapper class, not the SDK's raw page.
//
// So auth_sdk's manifest.json "routes" entries point at THIS file (via the
// ${package} placeholder, same as lms_sdk's manifest already does), not at
// auth_sdk's page files directly — these wrappers are what actually gets a
// route class generated.

import 'package:auto_route/auto_route.dart';
// Re-exported (not just imported): the generated app_router.gr.dart shares
// app_router.dart's library scope, and RegisterConfirmationRoute's
// generated args class references UserModel by type — it needs to be
// visible there, not just inside this file.
export 'package:base_sdk/src/models/models.dart';

import 'package:base_sdk/src/models/models.dart';
import 'package:flutter/material.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/login/login_page.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/register/register_page.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/confirmation/register_confirmation_page.dart';
import 'package:auth_sdk/src/common/presentation/pages/auth/reset/reset_password_page.dart';
// The session-policy shell installed next to this file (${package} is
// substituted with the host app's package name at install time, same as the
// manifest "routes" imports).
import 'package:${package}/presentation/routes/auth_session_policy.dart';

@RoutePage(name: 'LoginRoute')
class LoginRouteView extends StatelessWidget {
  const LoginRouteView({super.key});

  @override
  Widget build(BuildContext context) {
    // Put the composition-declared session policy (auth_session_policy.dart,
    // installed next to this file) in force before the login page builds:
    // every sign-in path goes through this route, so this is the one wiring
    // point the policy needs. A no-op when the app declares no policy.
    applyComposedSessionPolicy();
    return const LoginPage();
  }
}

@RoutePage(name: 'RegisterRoute')
class RegisterRouteView extends StatelessWidget {
  final bool isOnlyEmail;

  const RegisterRouteView({super.key, this.isOnlyEmail = false});

  @override
  Widget build(BuildContext context) =>
      RegisterPage(isOnlyEmail: isOnlyEmail);
}

@RoutePage(name: 'RegisterConfirmationRoute')
class RegisterConfirmationRouteView extends StatelessWidget {
  final UserModel userModel;
  final bool isResetPassword;
  final String verificationId;

  const RegisterConfirmationRouteView({
    super.key,
    required this.userModel,
    required this.verificationId,
    this.isResetPassword = false,
  });

  @override
  Widget build(BuildContext context) => RegisterConfirmationPage(
        userModel: userModel,
        verificationId: verificationId,
        isResetPassword: isResetPassword,
      );
}

@RoutePage(name: 'ResetPasswordRoute')
class ResetPasswordRouteView extends StatelessWidget {
  const ResetPasswordRouteView({super.key});

  @override
  Widget build(BuildContext context) => const ResetPasswordPage();
}
