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

import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/navigation/embedded_widgets.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/theme/app_style.dart';
//import '../../../../application/edit_profile/edit_profile_provider.dart';
import 'package:base_sdk/src/presentation/components/buttons/button_item.dart';
import 'package:marketplace_sdk/src/common/presentation/pages/profile/edit_profile_page.dart';
// [refork] embed via EmbeddedWidgets
import 'package:marketplace_sdk/src/common/presentation/pages/profile/currency_page.dart';
// [refork] embed via EmbeddedWidgets

class MyAccount extends StatelessWidget {
  final bool isBackButton;

  const MyAccount({super.key, this.isBackButton = true});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = LocalStorage.getAppThemeMode();
    final bool isLtr = LocalStorage.getLangLtr();
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDarkMode ? AppStyle.mainBackDark : AppStyle.bgGrey,
        body: Column(
          children: [
            Row(
              children: [
                // const PopButton(),
                const SizedBox(width: 20, height: 120),
                //  CommonAppBar( child:
                SafeArea(
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.account),
                    style: AppStyle.interNoSemi(color: Colors.black, size: 18),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 24),
            ButtonItem(
              isLtr: isLtr,
              icon: FlutterRemix.edit_2_line,
              title: AppHelpers.getTranslation(TrKeys.editAccount),
              onTap: () {
                //  ref.refresh(editProfileProvider);
                AppHelpers.showCustomModalBottomDragSheet(
                  context: context,
                  modal: (c) => EditProfileScreen(controller: c),
                  isDarkMode: isDarkMode,
                );
              },
            ),
            ButtonItem(
              isLtr: isLtr,
              icon: FlutterRemix.lock_2_line,
              title: AppHelpers.getTranslation(TrKeys.changePassword),
              onTap: () {
                Navigator.pop(context);
                AppHelpers.showCustomModalBottomSheet(
                  context: context,
                  modal: EmbeddedWidgets.I.resetPasswordPage(),
                  isDarkMode: isDarkMode,
                );
              },
            ),
            ButtonItem(
              isLtr: isLtr,
              icon: FlutterRemix.hotel_line,
              title: AppHelpers.getTranslation(TrKeys.deliveryTo),
              onTap: () {
                AppRoutes.I.pushAddressListRoute(context);
              },
            ),
            ButtonItem(
              isLtr: isLtr,
              icon: FlutterRemix.settings_3_line,
              title: AppHelpers.getTranslation(TrKeys.notifications),
              onTap: () {
                AppRoutes.I.pushSettingRoute(context);
              },
            ),
            ButtonItem(
              isLtr: isLtr,
              title: AppHelpers.getTranslation(TrKeys.language),
              icon: FlutterRemix.global_line,
              onTap: () {
                AppHelpers.showCustomModalBottomSheet(
                  isDismissible: false,
                  context: context,
                  modal: EmbeddedWidgets.I.languageScreen(
                    onSave: () {
                      Navigator.pop(context);
                    },
                  ),
                  isDarkMode: isDarkMode,
                );
              },
            ),
            ButtonItem(
              isLtr: isLtr,
              title: AppHelpers.getTranslation(TrKeys.currencies),
              icon: FlutterRemix.bank_card_line,
              onTap: () {
                AppHelpers.showCustomModalBottomSheet(
                  context: context,
                  modal: const CurrencyScreen(),
                  isDarkMode: isDarkMode,
                );
              },
            ),
          ],
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: //isBackButton ?
            Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: const PopButton(),
        ),
        // : const SizedBox.shrink(),
      ),
    );
  }
}
