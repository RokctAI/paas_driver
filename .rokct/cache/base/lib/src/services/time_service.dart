// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:intl/intl.dart';

abstract class TimeService {
  TimeService._();

  static final String _timeFormat =
      AppConstants.use24Format ? 'HH:mm' : 'h:mm a';

  static String dateFormatYMD(DateTime? time) {
    return DateFormat("yyyy-MM-dd").format(time ?? DateTime.now());
  }

  static String dateFormatMDYHm(DateTime? time) {
    return DateFormat(
      "MMM d, yyyy - $_timeFormat",
    ).format(time ?? DateTime.now());
  }

  static String dateFormatDMY(DateTime? time) {
    return DateFormat("d MMM, yyyy").format(time ?? DateTime.now());
  }

  static String dateFormatMD(DateTime? time) {
    return DateFormat("MMMM dd").format(time ?? DateTime.now());
  }

  static String dateFormatEMD(DateTime? time) {
    return DateFormat("EEEE, MMM dd").format(time ?? DateTime.now());
  }

  static String dateFormatMDHm(DateTime? time) {
    return DateFormat("MMM dd, $_timeFormat").format(time ?? DateTime.now());
  }

  static String dateFormatEE(DateTime? time) {
    return DateFormat("EEEE").format(time ?? DateTime.now());
  }

  static String dateFormatDM(DateTime? time) {
    if (DateTime.now().year == time?.year) {
      return DateFormat("d MMMM").format(time ?? DateTime.now());
    }
    return DateFormat("d MMMM, yyyy").format(time ?? DateTime.now());
  }

  static String timeFormat(DateTime? time) {
    return DateFormat(_timeFormat).format(time ?? DateTime.now());
  }

  static String dateFormatForChat(DateTime? time) {
    if ((DateTime.now().difference(time ?? DateTime.now()).inHours) > 24 &&
        (DateTime.now().difference(time ?? DateTime.now()).inDays) < 7) {
      return DateFormat("EEEE").format(time ?? DateTime.now());
    }
    if ((DateTime.now().difference(time ?? DateTime.now()).inDays) > 7) {
      return DateFormat("MMM/d/yyyy").format(time ?? DateTime.now());
    }
    return DateFormat(_timeFormat).format(time ?? DateTime.now());
  }

  static String dateFormatForNotification(DateTime? time) {
    return DateFormat("d MMM, $_timeFormat").format(time ?? DateTime.now());
  }

  static String formatHHMMSS(int seconds) {
    seconds = (seconds % 3600).truncate();
    int minutes = (seconds / 60).truncate();
    String minutesStr = (minutes).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    return "$minutesStr:$secondsStr";
  }

  static String timeFormatTime(String? time) {
    if (time == null) {
      return '';
    }
    return DateFormat(_timeFormat).format(
      DateTime.now().copyWith(
        hour: int.tryParse(time.substring(0, 2)),
        minute: int.tryParse(time.substring(3, 5)),
      ),
    );
  }
}
