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
