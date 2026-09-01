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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';



import 'package:${package}/presentation/routes/app_router.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/application/profile/provider/profile_settings_provider.dart';

class LogoutModal extends StatelessWidget {
  final bool isDeleteAccount;

  const LogoutModal({super.key, this.isDeleteAccount = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Text(
            AppHelpers.getTranslation(isDeleteAccount
                ? TrKeys.areYouSure
                : TrKeys.doYouReallyWantToLogout),
            style: AppStyle.interSemi(size: 16.sp),
            textAlign: TextAlign.center,
          ),
          40.verticalSpace,
          Row(
            children: [
              Expanded(
                child: CustomButton(
                    borderColor: AppStyle.black,
                    background: AppStyle.transparent,
                    title: AppHelpers.getTranslation(TrKeys.cancel),
                    onPressed: () {
                      Navigator.pop(context);
                    }),
              ),
              16.horizontalSpace,
              Expanded(
                child: Consumer(builder: (context, ref, child) {
                  if (isDeleteAccount) {
                    return CustomButton(
                        background: AppStyle.red,
                        textColor: AppStyle.white,
                        title: AppHelpers.getTranslation(TrKeys.deleteAccount),
                        onPressed: () {
                          ref
                              .read(profileSettingsProvider.notifier)
                              .deleteAccount(context);
                        });
                  } else {
                    return CustomButton(
                        title: AppHelpers.getTranslation(TrKeys.logout),
                        onPressed: () {
                          final GoogleSignIn signIn = GoogleSignIn();
                          signIn.disconnect();
                          signIn.signOut();
                          LocalStorage.logout();
                          context.router.popUntilRoot();
                          context.replaceRoute(const LoginRoute());
                        });
                  }
                }),
              ),
            ],
          ),
          24.verticalSpace,
        ],
      ),
    );
  }
}
