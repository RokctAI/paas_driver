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


import 'dart:ui';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';

@RoutePage()
class NoConnectionPage extends ConsumerStatefulWidget {
  const NoConnectionPage({super.key});

  @override
  ConsumerState<NoConnectionPage> createState() => _NoConnectionPageState();
}

class _NoConnectionPageState extends ConsumerState<NoConnectionPage> {
  @override
  void initState() {
    super.initState();
    // Automatically show dialog when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNoConnectionDialog();
    });
  }

  void _showNoConnectionDialog() {
    AppHelpers.showAlertDialog(
      context: context,
      isDismissible: false,
      child: const NoConnectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.transparent,
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: Container(
          color: AppStyle.black.withOpacity(0.5),
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class NoConnectionDialog extends ConsumerWidget {
  const NoConnectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Remix.wifi_off_fill, size: 80.sp, color: AppStyle.textGrey),
        24.verticalSpace,
        Text(
          AppHelpers.getTranslation(TrKeys.noInternetConnection),
          style: AppStyle.interSemi(size: 18.sp),
          textAlign: TextAlign.center,
        ),
        12.verticalSpace,
        Text(
          'Please check your internet connection and try again.',
          style: AppStyle.interNormal(size: 14.sp, color: AppStyle.textGrey),
          textAlign: TextAlign.center,
        ),
        32.verticalSpace,
        CustomButton(
          title: AppHelpers.getTranslation(TrKeys.tryAgain),
          background: AppStyle.primary,
          textColor: AppStyle.white,
          onPressed: () => _checkConnectionAndNavigate(context),
        ),
        16.verticalSpace,
        CustomButton(
          title: AppHelpers.getTranslation(TrKeys.continueText),
          background: AppStyle.transparent,
          borderColor: AppStyle.black,
          textColor: AppStyle.black,
          onPressed: () => _continueOffline(context),
        ),
      ],
    );
  }

  Future<void> _checkConnectionAndNavigate(BuildContext context) async {
    Navigator.of(context).pop(); // Close dialog first

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection =
          connectivityResult.contains(ConnectivityResult.mobile) ||
              connectivityResult.contains(ConnectivityResult.ethernet) ||
              connectivityResult.contains(ConnectivityResult.wifi);

      if (hasConnection) {
        // Connection restored, go back to splash to reinitialize
        if (context.mounted) {
          AppRoutes.I.replaceSplashRoute(context);
        }
      } else {
        // Still no connection, show snackbar and reopen dialog
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
          // Reopen dialog after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              AppHelpers.showAlertDialog(
                context: context,
                isDismissible: false,
                child: const NoConnectionDialog(),
              );
            }
          });
        }
      }
    } catch (e) {
      // Error checking connection
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
        // Reopen dialog after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            AppHelpers.showAlertDialog(
              context: context,
              isDismissible: false,
              child: const NoConnectionDialog(),
            );
          }
        });
      }
    }
  }

  void _continueOffline(BuildContext context) {
    Navigator.of(context).pop(); // Close dialog
    // Continue with limited functionality
    AppHelpers.goHome(context);
  }
}
