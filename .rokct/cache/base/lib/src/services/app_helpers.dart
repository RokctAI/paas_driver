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


import 'dart:math';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:base_sdk/src/services/extension.dart';
import 'package:intl/intl.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
// [refork] removed host router import
import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/bundled_translations.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/models/data/address_old_data.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

abstract class AppHelpers {
  AppHelpers._();

  static String numberFormat({num? number, String? symbol, bool? isOrder}) {
    if (LocalStorage.getSelectedCurrency()?.position == "before") {
      return NumberFormat.currency(
        customPattern: '\u00a4#,###.#',
        symbol: (isOrder ?? false)
            ? symbol ?? LocalStorage.getSelectedCurrency()?.symbol
            : LocalStorage.getSelectedCurrency()?.symbol,
        decimalDigits: 2,
      ).format(number ?? 0);
    } else {
      return NumberFormat.currency(
        customPattern: '#,###.#\u00a4',
        symbol: (isOrder ?? false)
            ? symbol ?? LocalStorage.getSelectedCurrency()?.symbol
            : LocalStorage.getSelectedCurrency()?.symbol,
        decimalDigits: 2,
      ).format(number ?? 0);
    }
  }

  static String generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-.';
    final random = Random.secure();
    return List.generate(
      length,
      (i) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static bool checkYesterday(String? startTime, String? endTime) {
    final now = DateTime.now().subtract(const Duration(days: 1));
    final format = DateFormat('HH:mm');

    DateTime start = format.parse(startTime.toSingleTime);
    DateTime end = format.parse(endTime.toSingleTime);

    start = DateTime(
      now.year,
      now.month,
      now.day,
      start.hour,
      start.minute,
      start.second,
    );
    end = DateTime(
      now.year,
      now.month,
      now.day,
      end.hour,
      end.minute,
      end.second,
    );
    return end.isBefore(start);
  }

  static showNoConnectionSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(
      backgroundColor: AppStyle.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Text(
        'No internet connection',
        style: AppStyle.interNoSemi(size: 14, color: AppStyle.white),
      ),
      action: SnackBarAction(
        label: 'Close',
        disabledTextColor: AppStyle.black,
        textColor: AppStyle.black,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static ExtrasType getExtraTypeByValue(String? value) {
    switch (value) {
      case 'color':
        return ExtrasType.color;
      case 'text':
        return ExtrasType.text;
      case 'image':
        return ExtrasType.image;
      default:
        return ExtrasType.text;
    }
  }

  static OrderStatus getOrderStatus(String? value) {
    switch (value) {
      case 'new':
        return OrderStatus.open;
      case 'accepted':
        return OrderStatus.accepted;
      case 'ready':
        return OrderStatus.ready;
      case 'on_a_way':
        return OrderStatus.onWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'canceled':
        return OrderStatus.canceled;
      default:
        return OrderStatus.accepted;
    }
  }

  static String? getOrderByString(String value) {
    switch (getTranslationReverse(value)) {
      case "new":
        return "new";
      case "trust_you":
        return "trust_you";
      case 'highly_rated':
        return "high_rating";
      case 'best_sale':
        return "best_sale";
      case 'low_sale':
        return "low_sale";
      case 'low_rating':
        return "low_rating";
    }
    return null;
  }

  static String getOrderStatusText(OrderStatus value) {
    switch (value) {
      case OrderStatus.open:
        return "new";
      case OrderStatus.accepted:
        return "accepted";
      case OrderStatus.ready:
        return "ready";
      case OrderStatus.onWay:
        return "on_a_way";
      case OrderStatus.delivered:
        return "delivered";
      case OrderStatus.canceled:
        return "canceled";
    }
  }

  /// Legacy alias used by composed-app template pages (old core_sdk name).
  static errorSnackBar(BuildContext context, {required String text}) =>
      showCheckTopSnackBar(context, text);

  /// Shows a top error toast.
  ///
  /// Every top-snackbar helper below resolves its overlay with
  /// [Overlay.maybeOf] and returns without showing anything when the given
  /// context has no [Overlay] ancestor. A toast is decoration: it must never
  /// be able to take its caller down with it. `Overlay.of` asserts in that
  /// case, so a context handed in from outside the widget tree it belongs to
  /// -- an integration-test driver context, a callback running after its
  /// route is gone -- used to throw straight through the caller.
  static showCheckTopSnackBar(BuildContext context, String text) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    return showTopSnackBar(
      overlay,
      CustomSnackBar.error(
        message:
            text.isEmpty ? "Please check your credentials and try again" : text,
      ),
      animationDuration: const Duration(milliseconds: 700),
      reverseAnimationDuration: const Duration(milliseconds: 700),
      displayDuration: const Duration(milliseconds: 700),
    );
  }

  static showCheckTopSnackBarInfo(
    BuildContext context,
    String text, {
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    return showTopSnackBar(
      overlay,
      CustomSnackBar.info(message: text),
      animationDuration: const Duration(milliseconds: 700),
      reverseAnimationDuration: const Duration(milliseconds: 700),
      displayDuration: const Duration(milliseconds: 700),
      onTap: onTap,
    );
  }

  static showCheckTopSnackBarDone(BuildContext context, String text) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    return showTopSnackBar(
      overlay,
      CustomSnackBar.success(message: text),
      animationDuration: const Duration(milliseconds: 700),
      reverseAnimationDuration: const Duration(milliseconds: 700),
      displayDuration: const Duration(milliseconds: 700),
    );
  }

  static showCheckTopSnackBarInfoCustom(
    BuildContext context,
    String text, {
    VoidCallback? onTap,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    return showTopSnackBar(
      overlay,
      CustomSnackBar.info(
        message: text,
        icon: const SizedBox.shrink(),
        backgroundColor: AppStyle.primary,
        textStyle: AppStyle.interNormal(),
      ),
      animationDuration: const Duration(milliseconds: 700),
      reverseAnimationDuration: const Duration(milliseconds: 700),
      displayDuration: const Duration(milliseconds: 700),
      onTap: onTap,
    );
  }

  static double getOrderStatusProgress(String? status) {
    switch (status) {
      case 'new':
        return 0.2;
      case 'accepted':
        return 0.4;
      case 'ready':
        return 0.6;
      case 'on_a_way':
        return 0.8;
      case 'delivered':
        return 1;
      default:
        return 0.4;
    }
  }

  static String? getAppName() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'title') {
        return setting.value;
      }
    }
    // No server 'title' setting: fall back to the composed app's own brand
    // name (compose-time override of AppConstants.appTitle; 'JUVO' for apps
    // that declare nothing — the historical hardcoded fallback).
    return AppConstants.appTitle;
  }

  /// The trademark symbol rendered after the app name: '®' (Registered),
  /// '™' (Trademark), or '' (None — render no symbol at all).
  static String getTrademarkSymbol() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'trademark_symbol') {
        // An empty value means "None" — show nothing, do NOT fall back.
        return setting.value ?? '';
      }
    }
    // No server 'trademark_symbol' setting (older backend): keep the
    // historical hardcoded ® so existing apps look unchanged.
    return '®';
  }

  static String? getAppLogo() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'logo') {
        return setting.value;
      }
    }
    return '';
  }

  static int getType() {
    if (AppConstants.isDemo) {
      return LocalStorage.getUiType() ?? 0;
    }
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'ui_type') {
        return (int.tryParse(setting.value ?? "1") ?? 1) - 1;
      }
    }
    return 0;
  }

  static bool getGroupOrder() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'group_order') {
        return setting.value == "1";
      }
    }
    return true;
  }

  static bool getParcel() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'active_parcel') {
        return setting.value == "1";
      }
    }
    return false;
  }

  static bool getLendingEnabled() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'enable_paas_lending') {
        return setting.value == "1";
      }
    }
    return false;
  }

  static bool getReferralActive() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'referral_active') {
        return setting.value == "1";
      }
    }
    return false;
  }

  static String? getAppPhone() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'phone') {
        return setting.value;
      }
    }
    return '';
  }

  static String? getPaymentType() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'payment_type') {
        return setting.value;
      }
    }
    return 'admin';
  }

  static bool getPhoneRequired() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'before_order_phone_required') {
        return setting.value == "1";
      }
    }
    return false;
  }

  static bool getReservationEnable() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'reservation_enable_for_user') {
        return setting.value == "1";
      }
    }
    return false;
  }

  static String? getAppAddressName() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'address') {
        return setting.value;
      }
    }
    return '';
  }

  static String getTranslation(String trKey) {
    final Map<String, dynamic> translations = LocalStorage.getTranslations();
    final served = translations[trKey];
    if (served != null) return served;
    // Backend-served rows always win; for keys the served map lacks (no row
    // seeded for this locale, or the fetch never succeeded) consult the
    // locally bundled per-locale maps before humanizing the key.
    final bundled =
        BundledTranslations.lookup(LocalStorage.getLanguage()?.locale, trKey);
    if (bundled != null) return bundled;
    return humanizeTrKey(trKey);
  }

  /// The last-resort English rendering of a translation key: dots,
  /// underscores and camelCase boundaries become spaces and the first
  /// character is upper-cased — `daysInAppThisYear` reads
  /// "Days in app this year", not "DaysInAppThisYear". Shared by
  /// [getTranslation]'s fallback and TranslationSeeder's `en` candidate
  /// rows, so what the app shows for a missing key is exactly what it
  /// offers the backend as that key's English value.
  static String humanizeTrKey(String trKey) {
    if (trKey.isEmpty) return '';
    final spaced = trKey
        .replaceAll(".", " ")
        .replaceAll("_", " ")
        // A camelCase boundary (lowercase/digit, then uppercase) becomes a
        // word break, lower-cased: mid-sentence words of the humanized
        // fallback are plain English words, not Capitalized fragments.
        .replaceAllMapped(
          RegExp('(?<=[a-z0-9])[A-Z]'),
          (m) => ' ${m[0]!.toLowerCase()}',
        )
        .trim();
    if (spaced.isEmpty) return trKey;
    return spaced.replaceFirst(
      spaced.substring(0, 1),
      spaced.substring(0, 1).toUpperCase(),
    );
  }

  static String getTranslationReverse(String trKey) {
    final Map<String, dynamic> translations = LocalStorage.getTranslations();
    for (int i = 0; i < translations.values.length; i++) {
      if (trKey == translations.values.elementAt(i)) {
        return translations.keys.elementAt(i);
      }
    }
    return trKey;
  }

  static bool checkIsSvg(String? url) {
    if (url == null || (url.length) < 3) {
      return false;
    }
    final length = url.length;
    return url.substring(length - 3, length) == 'svg';
  }

  static double? getInitialLatitude() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'location') {
        final String? latString = setting.value?.substring(
          0,
          setting.value?.indexOf(','),
        );
        if (latString == null) {
          return null;
        }
        final double? lat = double.tryParse(latString);
        return lat;
      }
    }
    return null;
  }

  static double? getInitialLongitude() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'location') {
        final String? latString = setting.value?.substring(
          0,
          setting.value?.indexOf(','),
        );
        if (latString == null) {
          return null;
        }
        final String? lonString = setting.value?.substring(
          (latString.length) + 2,
          setting.value?.length,
        );
        if (lonString == null) {
          return null;
        }
        final double? lon = double.tryParse(lonString);
        return lon;
      }
    }
    return null;
  }

  /// Pins wide-window sheet content to the END edge (right in LTR, left in
  /// RTL) at [maxWidth].
  ///
  /// On non-compact windows the framework would center a width-capped sheet
  /// ([BottomSheet] wraps its constrained child in an `Align(bottomCenter)`),
  /// so instead the route is given unconstrained width and the cap + END
  /// alignment are applied here, inside the sheet.
  ///
  /// The sheet's transparent [Material] absorbs hit tests over its whole box,
  /// so the empty area beside the anchored content would otherwise swallow
  /// taps without dismissing; the outer detector mirrors the modal barrier
  /// there (when [isDismissible]) and the inner one keeps taps on the sheet
  /// body from bubbling up to it.
  static Widget _anchorSheetToEnd({
    required BuildContext context,
    required Widget sheet,
    required double maxWidth,
    required bool isDismissible,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isDismissible ? () => Navigator.of(context).maybePop() : null,
      child: Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: sheet,
          ),
        ),
      ),
    );
  }

  static void showCustomModalBottomSheet({
    required BuildContext context,
    required Widget modal,
    required bool isDarkMode,
    double radius = 16,
    bool isDrag = true,
    bool isDismissible = true,
    double paddingTop = 200,
    double maxWidth = AppBreakpoints.sheetMaxWidth,
  }) {
    // Compact windows keep the classic full-width sheet; anything wider
    // anchors the sheet to the END side instead of centering it.
    final bool anchorEnd = windowSizeOf(context).isAtLeastMedium;
    showModalBottomSheet(
      isDismissible: isDismissible,
      enableDrag: isDrag,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius.r),
          topRight: Radius.circular(radius.r),
        ),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height - paddingTop.r,
        maxWidth: anchorEnd ? double.infinity : maxWidth,
      ),
      backgroundColor: AppStyle.transparent,
      context: context,
      builder: (context) => anchorEnd
          ? _anchorSheetToEnd(
              context: context,
              sheet: modal,
              maxWidth: maxWidth,
              isDismissible: isDismissible,
            )
          : modal,
    );
  }

  static void showCustomModalBottomDragSheet({
    required BuildContext context,
    required Function(ScrollController controller) modal,
    bool isDarkMode = false,
    double radius = 16,
    bool isDrag = true,
    bool isDismissible = true,
    double paddingTop = 100,
    double maxChildSize = 0.9,
    double maxWidth = AppBreakpoints.sheetMaxWidth,
  }) {
    // Compact windows keep the classic full-width sheet; anything wider
    // anchors the sheet to the END side instead of centering it.
    final bool anchorEnd = windowSizeOf(context).isAtLeastMedium;
    showModalBottomSheet(
      isDismissible: isDismissible,
      enableDrag: isDrag,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius.r),
          topRight: Radius.circular(radius.r),
        ),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height - paddingTop.r,
        maxWidth: anchorEnd ? double.infinity : maxWidth,
      ),
      backgroundColor: AppStyle.transparent,
      context: context,
      builder: (context) {
        final Widget sheet = DraggableScrollableSheet(
          initialChildSize: maxChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return modal(scrollController);
          },
        );
        return anchorEnd
            ? _anchorSheetToEnd(
                context: context,
                sheet: sheet,
                maxWidth: maxWidth,
                isDismissible: isDismissible,
              )
            : sheet;
      },
    );
  }

  static void showAlertDialog({
    required BuildContext context,
    required Widget child,
    double radius = 16,
    bool isDismissible = true,
  }) {
    AlertDialog alert = AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius.r)),
      ),
      contentPadding: EdgeInsets.all(20.r),
      iconPadding: EdgeInsets.zero,
      content: child,
    );

    showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  static String errorHandler(e) {
    if (e is DioException && _isConnectionFailure(e)) {
      // No HTTP response ever arrived (offline, DNS failure, timeout).
      // The raw exception carries nothing a student can act on — the old
      // extraction chain null-shorted it down to the literal "null" — so
      // surface the friendly line and send the detail to telemetry for
      // the admin side.
      _reportConnectionFailure(e);
      return _connectionErrorMessage();
    }
    return _presentable(_extractErrorMessage(e));
  }

  /// Connection-class DioException: never got an HTTP response — offline,
  /// DNS failure, connection refused, or a timeout. Anything with a real
  /// response (DioExceptionType.badResponse) carries a server message and
  /// keeps the existing extraction path untouched.
  static bool _isConnectionFailure(DioException e) {
    if (e.response != null) return false;
    final classified = NetworkExceptions.getDioException(e);
    return classified is NoInternetConnection ||
        classified is RequestTimeout ||
        classified is SendTimeout;
  }

  /// Student-facing one-liner for connection failures — the same
  /// translation key every offline surface already shows, with a hard
  /// fallback for callers that run before LocalStorage is initialized.
  static String _connectionErrorMessage() {
    try {
      final message = getTranslation(TrKeys.checkYourNetworkConnection).trim();
      if (message.isNotEmpty && message != 'null') return message;
    } catch (_) {
      // Fall through to the literal below.
    }
    return "Couldn't connect. Please check your internet and try again.";
  }

  /// Admin-side detail for a connection failure whose student-facing
  /// message is the friendly one-liner. Fire-and-forget: TelemetryClient
  /// swallows its own delivery failures (an offline telemetry POST dies
  /// silently), and the guard here keeps errorHandler itself unable to
  /// throw. No recursion: nothing in TelemetryClient's failure path calls
  /// errorHandler.
  static void _reportConnectionFailure(DioException e) {
    try {
      String url = '';
      try {
        url = e.requestOptions.uri.toString();
      } catch (_) {}
      TelemetryClient.I.logError(
        type: 'network_unreachable',
        context: {
          'exception': e.type.name,
          'message': e.message ?? '',
          if (url.isNotEmpty) 'url': url,
        },
      );
    } catch (_) {
      // Telemetry must never break error handling.
    }
  }

  /// Last line of defense: no student-facing surface may ever receive the
  /// literal "null" (a null-shorted `.toString()`) or an empty string.
  static String _presentable(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty || trimmed == 'null') {
      try {
        return getTranslation(TrKeys.somethingWentWrongWithTheServer);
      } catch (_) {
        return 'Something went wrong. Please try again.';
      }
    }
    return message;
  }

  /// The pre-existing best-effort extraction chain, unchanged: server
  /// message, then HTML `<title>`, then `error.message`, then toString().
  static String _extractErrorMessage(e) {
    try {
      return (e.runtimeType == DioException)
          ? ((e as DioException).response?.data["message"] == "Bad request."
              ? (e.response?.data["params"] as Map).values.first[0]
              : e.response?.data["message"])
          : e.toString();
    } catch (s) {
      try {
        return (e.runtimeType == DioException)
            ? ((e as DioException).response?.data.toString().substring(
                  (e.response?.data.toString().indexOf("<title>") ?? 0) + 7,
                  e.response?.data.toString().indexOf("</title") ?? 0,
                )).toString()
            : e.toString();
      } catch (r) {
        try {
          return (e.runtimeType == DioException)
              ? ((e as DioException).response?.data["error"]["message"])
                  .toString()
              : e.toString();
        } catch (f) {
          return e.toString();
        }
      }
    }
  }

  static String reviewText(num? review) {
    if (review == null || review == 0) {
      return AppHelpers.getTranslation(TrKeys.newKey);
    }

    if (review > 0 && review <= 1) {
      return AppHelpers.getTranslation(TrKeys.veryBad);
    }
    if (review <= 2) {
      return AppHelpers.getTranslation(TrKeys.bad);
    }
    if (review <= 3) {
      return AppHelpers.getTranslation(TrKeys.notBad);
    }
    if (review <= 4) {
      return AppHelpers.getTranslation(TrKeys.good);
    }
    if (review <= 4.5) {
      return AppHelpers.getTranslation(TrKeys.veryGood);
    }
    if (review <= 5) {
      return AppHelpers.getTranslation(TrKeys.exceptional);
    }

    // For any value greater than 5
    return AppHelpers.getTranslation(TrKeys.newKey);
  }

  static openDialog({required BuildContext context, required String title}) {
    return showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: AppStyle.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            margin: EdgeInsets.all(24.w),
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppStyle.bgGrey,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppStyle.interNormal(
                      color: AppStyle.textGrey,
                      size: 18,
                    ),
                  ),
                  24.verticalSpace,
                  CustomButton(
                    onPressed: () => Navigator.pop(context),
                    title: AppHelpers.getTranslation(TrKeys.close),
                    background: AppStyle.primary,
                    textColor: AppStyle.white,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static bool isUsingDefaultCoordinates() {
    // Don't show the tooltip if user is logged in
    if (LocalStorage.getToken().isNotEmpty) {
      return false;
    }

    AddressData? addressData = LocalStorage.getAddressSelected();

    // Get current coordinates
    final double? currentLat = addressData?.location?.latitude;
    final double? currentLng = addressData?.location?.longitude;

    // Get default coordinates
    final double defaultLat = AppConstants.demoLatitude;
    final double defaultLng = AppConstants.demoLongitude;

    // If location is null or coordinates are null, consider it as using default
    if (addressData?.location == null ||
        currentLat == null ||
        currentLng == null) {
      return true;
    }

    // Check if current coordinates match default coordinates
    // Using a slightly larger epsilon for floating point comparison
    const double epsilon = 0.01;
    return ((currentLat - defaultLat).abs() < epsilon &&
        (currentLng - defaultLng).abs() < epsilon);
  }

  static void showNoConnectionDialog(BuildContext context) {
    showAlertDialog(
      context: context,
      isDismissible: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Remix.wifi_off_fill,
            size: 80.sp,
            color: AppStyle.textGrey,
          ),
          24.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.noInternetConnection),
            style: AppStyle.interSemi(size: 18.sp),
            textAlign: TextAlign.center,
          ),
          12.verticalSpace,
          Text(
            'Please check your internet connection and try again.',
            style: AppStyle.interNormal(size: 14.sp, color: AppStyle.textGrey),
            textAlign: TextAlign.center,
          ),
          32.verticalSpace,
          CustomButton(
            title: "Retry",
            background: AppStyle.primary,
            textColor: AppStyle.white,
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog first

              try {
                final hasConnection = await AppConnectivity.connectivity();

                if (context.mounted && hasConnection) {
                  // Connection restored
                  AppHelpers.showCheckTopSnackBarDone(
                    context,
                    "Connection restored!",
                  );
                } else {
                  // Still no connection, show dialog again
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      AppHelpers.showNoConnectionDialog(context);
                    }
                  });
                }
              } catch (e) {
                // Error checking connection, show dialog again
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (context.mounted) {
                    AppHelpers.showNoConnectionDialog(context);
                  }
                });
              }
            },
          ),
          16.verticalSpace,
          CustomButton(
            title: "Continue Offline",
            background: AppStyle.transparent,
            borderColor: AppStyle.black,
            textColor: AppStyle.black,
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
          ),
        ],
      ),
    );
  }

  static void goHome(BuildContext context) {
    if (AppConstants.enableMarketplace) {
      AppRoutes.I.replaceMainRoute(context);
    } else {
      AppRoutes.I.replaceShopRoute(context, shopId: AppConstants.defaultShopId);
    }
  }
}

extension TimeOfDayExtension on TimeOfDay {
  TimeOfDay plusMinutes({required int minute}) {
    DateTime today = DateTime.now();
    DateTime customDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      hour,
      this.minute,
    );
    return TimeOfDay.fromDateTime(
      customDateTime.add(Duration(minutes: minute)),
    );
  }
}

extension ExtendedIterable<E> on Iterable<E> {
  Iterable mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}
