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


import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Backend-triggered maintenance page.
///
/// Shown when [AppConnectivity.backendStatus] reports maintenance — the
/// tenant site's `maintenance_mode` site_config flag flips its guest
/// `api_status` endpoint to "maintenance". Retry re-probes and resumes the
/// normal boot flow (via the splash page) once the backend is up again.
@RoutePage()
class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  bool isChecking = false;

  Future<void> _retry() async {
    setState(() => isChecking = true);
    final status = await AppConnectivity.backendStatus();
    if (!mounted) return;
    setState(() => isChecking = false);
    if (status == BackendStatus.up) {
      // Backend is back — restart the boot flow from splash.
      AppRoutes.I.replaceSplashRoute(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Remix.tools_line, size: 80.sp, color: AppStyle.textGrey),
              24.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.maintenanceTitle),
                style: AppStyle.interSemi(size: 20.sp),
                textAlign: TextAlign.center,
              ),
              12.verticalSpace,
              Text(
                AppHelpers.getTranslation(TrKeys.maintenanceBrief),
                style:
                    AppStyle.interNormal(size: 14.sp, color: AppStyle.textGrey),
                textAlign: TextAlign.center,
              ),
              32.verticalSpace,
              CustomButton(
                title: AppHelpers.getTranslation(TrKeys.tryAgain),
                isLoading: isChecking,
                background: AppStyle.primary,
                textColor: AppStyle.white,
                onPressed: isChecking ? null : _retry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
