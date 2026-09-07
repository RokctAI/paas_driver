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

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CustomDatePicker extends StatefulWidget {
  final List<DateTime?> range;
  final ValueChanged<List<DateTime?>> onChange;

  const CustomDatePicker(
      {super.key, required this.range, required this.onChange});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  // A getter, not a field: the styles below resolve through AppStyle's
  // mode-dependent getters, so the config has to be rebuilt when the mode
  // changes rather than frozen at State construction.
  CalendarDatePicker2Config get config => CalendarDatePicker2Config(
    calendarType: CalendarDatePicker2Type.range,
    selectedDayHighlightColor: AppStyle.primary,
    weekdayLabelTextStyle:
        AppStyle.interNormal(size: 14.sp, letterSpacing: -0.3, color: AppStyle.textPrimary),
    controlsTextStyle:
        AppStyle.interNormal(size: 14.sp, letterSpacing: -0.3, color: AppStyle.textPrimary),
    dayTextStyle:
        AppStyle.interNormal(size: 14.sp, letterSpacing: -0.3, color: AppStyle.textPrimary),
    // The SELECTED day's ground is selectedDayHighlightColor above
    // (AppStyle.primary), not the sheet, so its ink stays the pinned black
    // that pairs with orange - resolving it would put white on orange.
    // Declared explicitly because dayTextStyle would otherwise cover it.
    selectedDayTextStyle:
        AppStyle.interNormal(size: 14.sp, letterSpacing: -0.3, color: AppStyle.black),
    disabledDayTextStyle: AppStyle.interNormal(
        size: 14.sp, letterSpacing: -0.3, color: AppStyle.textGrey),
    dayBorderRadius: BorderRadius.circular(10.r),
  );

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker2(
      key: UniqueKey(),
      config: config,
      // initialValue: widget.range,
      onValueChanged: widget.onChange, value: const [],
    );
  }
}
