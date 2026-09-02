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
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/components/app_bars/common_app_bar.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/presentation/components/buttons/pop_button.dart';

@RoutePage()
class ShareReferralFaqPage extends StatefulWidget {
  final String terms;
  const ShareReferralFaqPage({super.key, required this.terms});

  @override
  State<ShareReferralFaqPage> createState() => _ShareReferralFaqPageState();
}

class _ShareReferralFaqPageState extends State<ShareReferralFaqPage> {
  final bool isLtr = LocalStorage.getLangLtr();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppStyle.bgGrey,
        body: Column(
          children: [
            CommonAppBar(
              child: Text(
                AppHelpers.getTranslation(TrKeys.referralFaq),
                style: AppStyle.interNoSemi(size: 18, color: AppStyle.black),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Text(
                widget.terms,
                style: AppStyle.interNoSemi(size: 20, color: AppStyle.black),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: const PopButton(),
        ),
      ),
    );
  }
}
