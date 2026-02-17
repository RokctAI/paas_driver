import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../styles/style.dart';

class CustomDatePicker extends StatefulWidget {
  final List<DateTime?> range;
  final ValueChanged<List<DateTime?>> onChange;

  const CustomDatePicker({
    super.key,
    required this.range,
    required this.onChange,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  final config = CalendarDatePicker2Config(
    calendarType: CalendarDatePicker2Type.range,
    selectedDayHighlightColor: Style.primary,
    weekdayLabelTextStyle: Style.interNormal(
      size: 14.sp,
      letterSpacing: -0.3,
      color: Style.black,
    ),
    controlsTextStyle: Style.interNormal(
      size: 14.sp,
      letterSpacing: -0.3,
      color: Style.black,
    ),
    dayTextStyle: Style.interNormal(
      size: 14.sp,
      letterSpacing: -0.3,
      color: Style.black,
    ),
    disabledDayTextStyle: Style.interNormal(
      size: 14.sp,
      letterSpacing: -0.3,
      color: Style.textColor,
    ),
    dayBorderRadius: BorderRadius.circular(10.r),
  );

  @override
  Widget build(BuildContext context) {
    return CalendarDatePicker2(
      key: UniqueKey(),
      config: config,
      // initialValue: widget.range,
      onValueChanged: widget.onChange,
      value: const [],
    );
  }
}
