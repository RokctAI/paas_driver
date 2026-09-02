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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class AppBarBottomSheet extends StatelessWidget {
  final String title;
  const AppBarBottomSheet({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          padding: const EdgeInsets.only(
            top: 16,
            right: 32,
            bottom: 16,
            left: 0,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: AppStyle.textPrimary),
        ),
        Text(
          title,
          style: AppStyle.interNoSemi(
            size: 20,
            color: AppStyle.textPrimary,
            letterSpacing: -0.01,
          ),
        ),
        Container(width: 24.w, height: 24.h, margin: const EdgeInsets.all(8)),
      ],
    );
  }
}
