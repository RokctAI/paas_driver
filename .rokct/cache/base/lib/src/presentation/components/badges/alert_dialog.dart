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


import 'package:flutter/material.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart'; // Import your theme file

class ComingSoonDialog extends StatelessWidget {
  const ComingSoonDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // The mode comes from the inherited theme, not from the app-wide
    // AppStyle.isDark static (Ray, 2026-09-19: "glance doesnt change test
    // immediately untill you come back if you switched theme mode" - the
    // same defect, found here by the fleet audit that followed). A static
    // is not an inherited widget, so a mode flip scheduled no rebuild of
    // this widget and it kept the previous mode's colours until something
    // else happened to rebuild it.
    final Brightness brightness = Theme.of(context).brightness;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // Adjust the radius as needed
      child: AlertDialog(
        backgroundColor: AppStyle.cardFor(brightness),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Match this with ClipRRect
        ),
        title: Text(
          AppHelpers.getTranslation(TrKeys.comingSoon),
          style: AppStyle.interBold(size: 18, color: AppStyle.inkFor(brightness)),
        ),
        content: Text(
          AppHelpers.getTranslation(TrKeys.featureNotAvailable),
          style: AppStyle.interRegular(size: 16, color: AppStyle.inkFor(brightness)),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              AppHelpers.getTranslation(TrKeys.ok),
              style: AppStyle.interBold(size: 16, color: AppStyle.primary),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
