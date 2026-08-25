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
