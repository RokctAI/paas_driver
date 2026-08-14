// Copyright (c) 2024 RokctAI
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/application/splash/splash_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';

@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // First, check if app is in maintenance mode
      if (AppConstants.isMaintain) {
        if (!mounted) return;
        FlutterNativeSplash.remove();
        AppRoutes.I.replaceClosedRoute(context);
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
          FlutterNativeSplash.remove();
          if (!mounted) return;
          AppRoutes.I.replaceNoConnectionRoute(context);
          return;
        }
      } else {
        // Has internet - proceed with normal flow
        await _proceedOnline();
      }
    } catch (e) {
      // Error occurred - check if we can proceed offline
      final hasOfflineData = _hasRequiredOfflineData();
      if (hasOfflineData) {
        await _proceedOffline();
      } else {
        FlutterNativeSplash.remove();
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

  Future<void> _proceedOnline() async {
    // Boot trigger for the offline outbox: fire-and-forget so queued work
    // from a previous offline session drains without delaying startup.
    SyncEngine().kick();
    try {
      // Load translations first
      await ref.read(splashProvider.notifier).getTranslations(context);

      if (!mounted) return;
      // Then check authentication
      ref.read(splashProvider.notifier).getToken(
        context,
        goMain: () {
          FlutterNativeSplash.remove();
          if (!mounted) return;
          AppHelpers.goHome(context);
        },
        goLogin: () {
          FlutterNativeSplash.remove();
          if (!mounted) return;
          AppRoutes.I.replaceLoginRoute(context);
        },
        goNoInternet: () {
          FlutterNativeSplash.remove();
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

    FlutterNativeSplash.remove();

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
    // Adaptive splash: the phone-shaped splash image stretched across a
    // wide (tablet/desktop) window looks bad, so only compact windows show
    // it. Wider windows get a bare surface with a spinner (mirroring the
    // POS splash) while the same boot flow above runs unchanged.
    if (!windowSizeOf(context).isCompact) {
      return Scaffold(
        backgroundColor: AppStyle.white,
        body: Center(
          child: CircularProgressIndicator(color: AppStyle.black),
        ),
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
