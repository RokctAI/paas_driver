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

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';

/// Picks the system UI mode to restore once the native splash is gone.
///
/// Tour builds on large screens go immersive: Android only hides the
/// launcher taskbar (it lives in the navigation-bar window) while the app
/// hides its navigation bar, and the taskbar otherwise burns into every
/// tablet still. Shipped builds and phones keep edge-to-edge.
///
/// "Large" is a window whose shortest side reaches [AppBreakpoints.medium],
/// so a tablet qualifies in either orientation and a phone in neither.
/// [tourMode] defaults to the compile-time [AppConstants.isTour] flag; it is
/// a parameter only so tests can exercise both answers in one process.
SystemUiMode postSplashSystemUiMode({
  required Size size,
  bool tourMode = AppConstants.isTour,
}) => tourMode && size.shortestSide >= AppBreakpoints.medium
    ? SystemUiMode.immersiveSticky
    : SystemUiMode.edgeToEdge;

/// Applies [postSplashSystemUiMode] for the window [context] sits in.
Future<void> applyPostSplashSystemUi(
  BuildContext context, {
  bool tourMode = AppConstants.isTour,
}) => SystemChrome.setEnabledSystemUIMode(
  postSplashSystemUiMode(size: MediaQuery.sizeOf(context), tourMode: tourMode),
);
