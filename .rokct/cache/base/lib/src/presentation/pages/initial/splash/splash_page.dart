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
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';

@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  /// Non-null once the boot path has failed to put any real screen on top
  /// of this one, so [build] renders the stand-in below instead of leaving
  /// the splash artwork up forever. Carries only the friendly line — the
  /// reason it is set is diagnostic detail and rides telemetry.
  String? _fallbackLine;

  /// Guards the retry button against a second concurrent boot.
  bool _booting = false;

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
    if (_booting) return;
    _booting = true;
    try {
      // Backend-triggered maintenance gate: the tenant's api_status
      // endpoint reports "maintenance" while the site's maintenance_mode
      // site_config flag is set (replaces the old compile-time isMaintain).
      final backendStatus = await AppConnectivity.backendStatus();
      if (backendStatus == BackendStatus.maintenance) {
        if (!mounted) return;
        _leaveSplash('maintenance', () {
          AppRoutes.I.replaceMaintenanceRoute(context);
        });
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
          if (!mounted) return;
          _leaveSplash('no_connection', () {
            AppRoutes.I.replaceNoConnectionRoute(context);
          });
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
      _report('splash_bootstrap_failed', e);
      final hasOfflineData = _hasRequiredOfflineData();
      if (hasOfflineData) {
        await _proceedOffline();
      } else {
        if (!mounted) return;
        _leaveSplash('no_connection', () {
          AppRoutes.I.replaceNoConnectionRoute(context);
        });
      }
    } finally {
      _booting = false;
    }
  }

  /// The one telemetry door for boot failures (ADR-006): the verbatim
  /// cause — not configured, provider down, timed out, no route declared —
  /// is admin-grade detail, so it goes to the `log_frontend_error` lane and
  /// never to the screen. Same split ErrorPresenter applies everywhere
  /// else; this page cannot use ErrorPresenter itself because its snackbar
  /// needs a Scaffold that is about to be replaced.
  void _report(String type, Object detail, {Map<String, dynamic> extra = const {}}) {
    unawaited(
      TelemetryClient.I.logError(
        type: type,
        context: <String, dynamic>{
          'stage': 'splash',
          'detail': detail.toString(),
          // Whether a BASE_URL was compiled in at all separates "not
          // configured" from "configured but unreachable" without putting
          // the URL itself in the event.
          'base_url_configured': AppConstants.baseUrl.isNotEmpty,
          ...extra,
        },
      ),
    );
  }

  /// Hands the screen over to [navigate], and guarantees SOMETHING replaces
  /// this page if that fails.
  ///
  /// A composition that declares no route for the destination throws a
  /// StateError out of `_HostAppRoutes.noSuchMethod`. That used to happen
  /// inside an un-awaited future where nothing could catch it, so the app
  /// sat on the splash artwork indefinitely with no error anywhere. Now the
  /// cause goes to telemetry and the app falls back to the no-connection
  /// page, then to an in-place stand-in — a real screen either way.
  void _leaveSplash(String destination, VoidCallback navigate) {
    if (!mounted) return;
    _removeSplash();
    try {
      navigate();
      return;
    } catch (e) {
      _report('splash_navigation_failed', e, extra: {'destination': destination});
    }

    if (destination != 'no_connection') {
      try {
        if (!mounted) return;
        AppRoutes.I.replaceNoConnectionRoute(context);
        return;
      } catch (e) {
        _report('splash_fallback_route_failed', e,
            extra: {'destination': destination});
      }
    }

    _showFallback();
  }

  /// Last resort: render in place. Reached only when the host declares no
  /// usable route at all, which is a composition bug — but the person
  /// holding the phone still gets a screen that says the app is running
  /// without its backend, and a way to try again.
  void _showFallback() {
    if (!mounted) return;
    setState(() => _fallbackLine = _friendlyOfflineLine());
  }

  /// Friendly, named, and nothing else. The hard-coded fallback matches
  /// ErrorPresenter's: this can run before any translation has been
  /// fetched or bundled.
  static String _friendlyOfflineLine() {
    try {
      final line =
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection).trim();
      if (line.isNotEmpty && line != 'null') return line;
    } catch (_) {
      // Fall through to the literal below.
    }
    return 'Check your network connection.';
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
      if (backendUp) {
        // Load translations first
        await ref.read(splashProvider.notifier).getTranslations(context);
      } else {
        // The api_status probe above already answered: the tenant backend
        // is not reachable. Asking it for translations anyway bought
        // nothing and cost the dio timeout twice over (the repository
        // retries the fetch under the control-role cmd), so the app sat on
        // the splash for up to a minute before falling back to exactly the
        // translations it already had. Skip straight to the token check and
        // let the app start from local data; WHY it is starting without a
        // backend is diagnostic detail, so it rides telemetry.
        _report(
          'splash_backend_unreachable',
          'api_status did not answer; starting from local data',
        );
      }

      if (!mounted) return;
      // Then check authentication. AWAITED: the callbacks below navigate,
      // and a composition that declares no route for the destination throws
      // out of AppRoutes. Un-awaited, that throw escaped into an orphan
      // future — no catch, no telemetry, no navigation, and the app simply
      // stayed on this page.
      await ref.read(splashProvider.notifier).getToken(
        context,
        goMain: () => _leaveSplash('main', () {
          AppHelpers.goHome(context);
        }),
        goLogin: () => _leaveSplash('login', () {
          AppRoutes.I.replaceLoginRoute(context);
        }),
        goNoInternet: () => _leaveSplash('no_connection', () {
          AppRoutes.I.replaceNoConnectionRoute(context);
        }),
      );
    } catch (e) {
      // If online flow fails, try offline
      _report('splash_online_boot_failed', e);
      await _proceedOffline();
    }
  }

  Future<void> _proceedOffline() async {
    // Add a small delay to show splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Check if user was previously logged in
    final token = LocalStorage.getToken();

    if (!mounted) return;

    if (token.isNotEmpty) {
      // User was logged in, go to main page
      _leaveSplash('main', () {
        AppHelpers.goHome(context);
      });
    } else {
      // User not logged in, go to login
      _leaveSplash('login', () {
        AppRoutes.I.replaceLoginRoute(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Boot could not hand the screen to any route (see [_leaveSplash]).
    // Anything is better than the splash artwork forever: the app's name,
    // one friendly line, and a way to try again.
    final fallbackLine = _fallbackLine;
    if (fallbackLine != null) {
      return Scaffold(
        backgroundColor: AppStyle.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppHelpers.getAppName() ?? AppConstants.appTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppStyle.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fallbackLine,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppStyle.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      setState(() => _fallbackLine = null);
                      unawaited(_initializeApp());
                    },
                    child: Text(
                      AppHelpers.getTranslation(TrKeys.tryAgain),
                      style: GoogleFonts.inter(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
