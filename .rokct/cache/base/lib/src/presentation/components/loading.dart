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


import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class Loading extends StatelessWidget {
  final Color bgColor;

  const Loading({super.key, this.bgColor = AppStyle.textGrey});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Platform.isAndroid
          ? CircularProgressIndicator(color: AppStyle.primary)
          : CupertinoActivityIndicator(color: bgColor, radius: 12),
    );
  }
}
