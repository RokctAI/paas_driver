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


// Copyright (c) 2024 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:base_sdk/src/application/splash/splash_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';

@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  /// Removes the native splash AND re-asserts the app's full-frame chrome.
  ///
  /// The splash theme runs with `windowFullscreen` (flutter_native_splash's
  /// `fullscreen: true`), so the edge-to-edge mode main() requested is
  /// applied while the splash window flags are still in force and is lost
  /// when they clear — leaving the app sitting ABOVE an opaque black
  /// navigation bar (the "bottom of the phone eats the app" band under the
  /// gesture pill). Re-asserting the mode and the shared overlay style here,
  /// at the exact moment the splash goes away, restores the full frame:
  /// content draws behind both transparent bars with white icons.
  static void _removeSplash() {
    FlutterNativeSplash.remove();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(AppStyle.systemUiOverlay);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Backend-triggered maintenance gate: the tenant's api_status
      // endpoint reports "maintenance" while the site's maintenance_mode
      // site_config flag is set (replaces the old compile-time isMaintain).
      final backendStatus = await AppConnectivity.backendStatus();
      if (backendStatus == BackendStatus.maintenance) {
        if (!mounted) return;
        _removeSplash();
        AppRoutes.I.replaceMaintenanceRoute(context);
        return;
      }

      // Check connectivity first
      final hasConnection = await _checkConnectivity();

      if (!hasConnection) {
        // No internet - check if we have offline data to continue
        final hasOfflineData = _hasRequiredOfflineData();

        if (hasOfflineData) {
          // We have enough offline data, proceed offline
          await _proceedOffline();
        } else {
          // No offline data and no internet - show no connection page
          _removeSplash();
          if (!mounted) return;
          AppRoutes.I.replaceNoConnectionRoute(context);
          return;
        }
      } else {
        // Has internet - proceed with normal flow. The backend probe above
        // already answered, so the online path knows whether the backend is
        // actually reachable (radio alone false-passes on networks without
        // internet, or when only the tenant backend is down).
        await _proceedOnline(backendUp: backendStatus == BackendStatus.up);
      }
    } catch (e) {
      // Error occurred - check if we can proceed offline
      final hasOfflineData = _hasRequiredOfflineData();
      if (hasOfflineData) {
        await _proceedOffline();
      } else {
        _removeSplash();
        if (!mounted) return;
        AppRoutes.I.replaceNoConnectionRoute(context);
      }
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.ethernet) ||
          connectivityResult.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }

  bool _hasRequiredOfflineData() {
    // Check if we have essential offline data
    final translations = LocalStorage.getTranslations();
    final settings = LocalStorage.getSettingsList();

    // Return true if we have basic data to run the app offline
    return translations.isNotEmpty || settings.isNotEmpty;
  }

  Future<void> _proceedOnline({required bool backendUp}) async {
    // Boot trigger for the offline outbox: fire-and-forget so queued work
    // from a previous offline session drains without delaying startup.
    // Gated on the backend actually answering (the api_status probe in
    // _initializeApp), not just device connectivity — draining against an
    // unreachable backend only burns retry attempts toward the dead cap.
    if (backendUp) SyncEngine().kick();
    try {
      // Load translations first
      await ref.read(splashProvider.notifier).getTranslations(context);

      if (!mounted) return;
      // Then check authentication
      ref.read(splashProvider.notifier).getToken(
        context,
        goMain: () {
          _removeSplash();
          if (!mounted) return;
          AppHelpers.goHome(context);
        },
        goLogin: () {
          _removeSplash();
          if (!mounted) return;
          AppRoutes.I.replaceLoginRoute(context);
        },
        goNoInternet: () {
          _removeSplash();
          if (!mounted) return;
          AppRoutes.I.replaceNoConnectionRoute(context);
        },
      );
    } catch (e) {
      // If online flow fails, try offline
      await _proceedOffline();
    }
  }

  Future<void> _proceedOffline() async {
    // Add a small delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Check if user was previously logged in
    final token = LocalStorage.getToken();

    _removeSplash();

    if (token.isNotEmpty) {
      // User was logged in, go to main page
      if (!mounted) return;
      AppHelpers.goHome(context);
    } else {
      // User not logged in, go to login
      if (!mounted) return;
      AppRoutes.I.replaceLoginRoute(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adaptive splash: the phone-shaped splash image stretched edge-to-edge
    // across a wide (tablet/desktop) window looks bad (and per core#35 no
    // image belongs there at all), so only compact windows fill the screen
    // with it. Wider windows show the app's display name at the center of
    // the screen with a slow "breathing" pulse — the same mechanics as
    // paas_pos's LoadingAnimation splash — so the desktop boot screen is
    // branded without any artwork or a bare spinner.
    if (!windowSizeOf(context).isCompact) {
      return const Scaffold(
        backgroundColor: AppStyle.white,
        body: Center(child: _BreathingBrandName()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white, // Ensure background color for dark theme
      body: SizedBox.expand(
        child: Image.asset("assets/images/splash.png", fit: BoxFit.fill),
      ),
    );
  }
}

/// The wide-window boot brand: the app's display name "breathing" at the
/// center of the screen.
///
/// Mechanics mirror paas_pos's LoadingAnimation reference: an
/// [AnimationController] at [AppConstants.animationDuration] x11 (~4.1 s per
/// half-cycle) repeating with `reverse: true` through an easeInOut curve,
/// driving opacity 0.5 -> 1.0 and scale 0.95 -> 1.0 together. The name is
/// resolved the way the rest of base_sdk does it (server 'title' setting via
/// [AppHelpers.getAppName], falling back to the composed app's
/// [AppConstants.appTitle]) and sized off the window width (20%, clamped
/// 40-80) exactly like the reference.
class _BreathingBrandName extends StatefulWidget {
  const _BreathingBrandName();

  @override
  State<_BreathingBrandName> createState() => _BreathingBrandNameState();
}

class _BreathingBrandNameState extends State<_BreathingBrandName>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.animationDuration * 11,
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize =
        (MediaQuery.sizeOf(context).width * 0.2).clamp(40.0, 80.0).toDouble();
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_animation.value * 0.5),
          child: Transform.scale(
            scale: 0.95 + (_animation.value * 0.05),
            child: child,
          ),
        );
      },
      child: Text(
        AppHelpers.getAppName() ?? AppConstants.appTitle,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppStyle.black,
        ),
      ),
    );
  }
}
