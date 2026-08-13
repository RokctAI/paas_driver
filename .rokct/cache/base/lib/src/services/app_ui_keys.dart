import 'package:flutter/material.dart';

/// Global handles to root-level UI hosts of the composed app.
///
/// SDK-resident services that run outside the widget tree (e.g. comms'
/// DesktopNotificationPoller ticking on a background timer) have no
/// BuildContext to reach the app's ScaffoldMessenger. The composed
/// app_widget template wires [scaffoldMessenger] into its
/// `MaterialApp.router(scaffoldMessengerKey: ...)`, so such services can
/// surface SnackBars/MaterialBanners through
/// `AppUiKeys.scaffoldMessenger.currentState`.
///
/// ALWAYS null-check `currentState` and fail open: apps composed from a
/// pre-1.10.0 base_sdk template (main.dart/app_widget.dart are host-owned
/// after first compose — the installer's hash guard stops overwriting
/// them) never attach the key, and even wired apps have a window before
/// the first frame where it is unattached.
class AppUiKeys {
  AppUiKeys._();

  /// Root [ScaffoldMessenger] of the composed app, or unattached (null
  /// [GlobalKey.currentState]) when the host template does not wire it.
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessenger =
      GlobalKey<ScaffoldMessengerState>();
}
