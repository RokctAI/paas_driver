import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

class CustomDatePicker extends StatefulWidget {
  final List<DateTime?> range;

  const CustomDatePicker({super.key, required this.range});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  final config = CalendarDatePicker2Config(
    calendarType: CalendarDatePicker2Type.range,
    selectedDayHighlightColor: AppStyle.primary,
    weekdayLabelTextStyle: AppStyle.interNormal(
      size: 14.sp,
      letterSpacing: -0.3,
      color: AppStyle.blackColor,
    ),
    controlsTextStyle: AppStyle.interNormal(
      size: 14.sp,
      letterSpacing: -0.3,
      color: AppStyle.blackColor,
    ),
    dayTextStyle: AppStyle.interNormal(
      size: 14.sp,
      letterSpacing: -0.3,
      color: AppStyle.blackColor,
    ),
    disabledDayTextStyle: AppStyle.interNormal(
      size: 14.sp,
      letterSpacing: -0.3,
      color: AppStyle.textGrey,
    ),
    dayBorderRadius: BorderRadius.circular(10.r),
  );

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker2(
      config: config,
      value: widget.range,
      onValueChanged: (values) {},
    );
  }
}
