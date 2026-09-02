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
import 'package:base_sdk/src/presentation/theme/theme.dart';

class NewTag extends StatelessWidget {
  final double? top, left, right;
  const NewTag({super.key, this.top = 5, this.left = 3, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          // borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          color: AppStyle.starColor,
        ),
        child: Text(
          AppHelpers.getTranslation(
            TrKeys.isAd,
          ), // Make sure AppHelpers is imported and accessible
          style: AppStyle.interNoSemi(size: 12, color: AppStyle.white),
        ),
      ),
    );
  }
}
