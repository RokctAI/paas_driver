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


import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/time_service.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';

class CustomTimePicker {
  static void getTimePicker(
    BuildContext context, {
    bool showSaveButton = false,
    Function? saveButton,
    required ValueChanged<String> onTimeChanged,
    required String helperText,
  }) {
    if (!Platform.isIOS) {
      _iosTimePicker(
        onTimeChanged,
        context,
        showSaveButton: showSaveButton,
        saveButtonOnTap: () {
          if (saveButton != null) saveButton();
        },
      );
    } else {
      _androidTimePicker(
        context,
        onTimeChanged,
        showSaveButton: showSaveButton,
        saveButtonOnTap: () {
          if (saveButton != null) saveButton();
        },
        helperText: helperText,
      );
    }
  }

  static void _androidTimePicker(
    BuildContext context,
    ValueChanged<String> onTimeChanged, {
    bool showSaveButton = false,
    Function? saveButtonOnTap,
    required String helperText,
  }) async {
    var date = await showTimePicker(
      context: context,
      helpText: helperText,
      confirmText: AppHelpers.getTranslation(TrKeys.save),
      initialTime: TimeOfDay.now(),
    );
    if (date != null) {
      final String selectedDate = _dateToAmPm(
        hour: date.hour,
        minute: date.minute,
      );
      onTimeChanged(selectedDate);
    }

    if (showSaveButton) {
      saveButtonOnTap!();
    }
  }

  static void _iosTimePicker(
    ValueChanged<String> onTimeChanged,
    BuildContext context, {
    bool showSaveButton = false,
    Function? saveButtonOnTap,
  }) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        color: AppStyle.cardDark,
        child: Material(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Visibility(
                visible: showSaveButton,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    saveButtonOnTap!();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: EdgeInsets.only(top: 20.h, right: 20.w),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        AppHelpers.getTranslation(TrKeys.save),
                        style: AppStyle.interSemi(
                          size: 16,
                          color: AppStyle.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 290.h,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  minuteInterval: 1,
                  use24hFormat: AppConstants.use24Format,
                  onDateTimeChanged: (value) {
                    final String selectedDate = _dateToAmPm(
                      hour: value.hour,
                      minute: value.minute,
                    );
                    onTimeChanged(selectedDate);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateToAmPm({required int hour, required int minute}) {
    final DateTime now = DateTime.now();
    return TimeService.timeFormat(
      DateTime(now.year, now.month, now.day, hour, minute),
    );
  }
}
