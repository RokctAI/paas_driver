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


import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

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
import 'package:base_sdk/src/constants/demo_currency.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:base_sdk/src/presentation/adaptive/breakpoints.dart';
import 'package:base_sdk/src/handlers/log_redaction.dart';
import 'package:base_sdk/src/handlers/network_exceptions.dart';
import 'package:base_sdk/src/models/data/address_old_data.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// Hard fallback for `could_not_reach_server`, for callers that run before
/// LocalStorage is initialized. Named so [AppHelpers.errorHandler] (which
/// returns it) and [AppHelpers.isAuthoredConnectionMessage] (which
/// recognises it) cannot drift apart.
const String kCouldNotReachServerLine =
    "We couldn't reach the server. Please try again.";

/// Hard fallback for `server_took_too_long`. See
/// [kCouldNotReachServerLine].
const String kServerTookTooLongLine =
    'The server took too long to respond. Please try again.';

abstract class AppHelpers {
  AppHelpers._();

  /// The currency money strings print in: the selected one, else - in a
  /// demo build only - [DemoCurrency.rand]. A real build with nothing
  /// selected keeps intl's own default (the locale's ISO code as a suffix)
  /// until `CurrencyNotifier.fetchCurrency` stores the backend's list.
  static CurrencyData? _formatCurrency() =>
      LocalStorage.getSelectedCurrency() ?? DemoCurrency.fallback;

  static String numberFormat({num? number, String? symbol, bool? isOrder}) {
    final CurrencyData? currency = _formatCurrency();
    if (currency?.position == "before") {
      return NumberFormat.currency(
        customPattern: '\u00a4#,###.#',
        symbol: (isOrder ?? false)
            ? symbol ?? currency?.symbol
            : currency?.symbol,
        decimalDigits: 2,
      ).format(number ?? 0);
    } else {
      return NumberFormat.currency(
        customPattern: '#,###.#\u00a4',
        symbol: (isOrder ?? false)
            ? symbol ?? currency?.symbol
            : currency?.symbol,
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

  /// The order status for [value]. Takes the dart wire strings ('new',
  /// 'on_a_way', ...) and the Order doctype's own options, which the
  /// backend returns as they are stored ('Shipped', 'Cancelled',
  /// 'Cooking', ...), case-insensitively. Anything unknown reads as
  /// accepted, as before.
  static OrderStatus getOrderStatus(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'new':
        return OrderStatus.open;
      case 'accepted':
      case 'cooking':
      case 'processing':
        return OrderStatus.accepted;
      case 'ready':
        return OrderStatus.ready;
      case 'on_a_way':
      case 'shipped':
        return OrderStatus.onWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'canceled':
      case 'cancelled':
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

  /// The app name with a dotted suffix folded away: `acme.school` reads
  /// `acme`. A name with no dot, an empty name, or a name whose first
  /// character is the dot (nothing to keep in front of it) comes back
  /// unchanged - only the value is inspected, never a brand.
  static String appNameStem(String name) {
    final int dot = name.indexOf('.');
    if (dot <= 0) {
      return name;
    }
    return name.substring(0, dot);
  }

  /// Whether [appNameStem] would shorten [name]: a dot with at least one
  /// character before it.
  static bool appNameFolds(String name) => appNameStem(name) != name;

  /// The part [appNameStem] folds away - the first dot and everything after
  /// it (`.school` for `acme.school`), or '' when the name does not fold.
  static String appNameSuffix(String name) =>
      name.substring(appNameStem(name).length);

  /// [getAppName] with its dotted suffix folded away (see [appNameStem]).
  static String? getAppNameStem() {
    final String? name = getAppName();
    return name == null ? null : appNameStem(name);
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

  /// The app's UI type (home style), 0-based.
  ///
  /// Two suppliers only, in this order:
  ///  1. the backend's 'ui_type' design setting (1-based on the wire, so it
  ///     is converted here);
  ///  2. [AppConstants.uiType], the compose-time default, when the backend
  ///     carries no such setting.
  ///
  /// There is deliberately no third source. The user-facing picker that used
  /// to write a per-device choice into LocalStorage is gone, and this reader
  /// no longer consults that stored value at all - an install that still
  /// holds an old pick resolves to the backend/AppConstants answer like a
  /// fresh one, instead of being frozen on a choice it can never change
  /// again. Demo builds take the same path (the demo settings seed carries
  /// no 'ui_type'), so a demo shows the app's composed default.
  static int getType() {
    final List<SettingsData> settings = LocalStorage.getSettingsList();
    for (final setting in settings) {
      if (setting.key == 'ui_type') {
        return (int.tryParse(setting.value ?? "1") ?? 1) - 1;
      }
    }
    return AppConstants.uiType;
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
    //
    // A null stored language is not "no bundled copy": it is the state
    // every app is in on the screens that run before a language has been
    // chosen - splash, and the login screen whose own `checkLanguage`
    // cannot store one while the backend is unreachable. Passing that null
    // through made `lookup` return null for every key, so those two screens
    // humanized past the bundled English map and showed clipped fragments
    // ("Could not reach server") in place of the copy written for them.
    // English is already the fleet's base locale (the `isDefault` row of
    // BundledTranslations.fallbackLanguages), so it stands in until a
    // language is chosen; a language that IS chosen behaves exactly as
    // before.
    final bundled = BundledTranslations.lookup(
      LocalStorage.getLanguage()?.locale ?? BundledTranslations.baseLocale,
      trKey,
    );
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

  /// Inline ("data:") image support.
  ///
  /// The demo seed data (see [DemoImages]) carries its imagery inline rather
  /// than pointing at an image host: the guided-tour build talks to no
  /// backend, and the CI emulator that walks the guided tour has no
  /// dependable route to a public placeholder host either, so a remote URL
  /// there renders as the image widgets' broken-image error state.
  /// [CustomNetworkImage] and [CommonImage] check this before they reach for
  /// the network.
  static bool isInlineImage(String? url) =>
      url != null && url.startsWith('data:image/');

  /// True for an inline image whose payload is SVG markup.
  static bool isInlineSvg(String? url) =>
      url != null && url.startsWith('data:image/svg+xml');

  /// The payload of a `data:` URI: the part after the first comma, base64
  /// decoded when the media type says so, else percent-decoded. Returns an
  /// empty string when [url] is not a well-formed `data:` URI - callers
  /// render their normal empty/error state on that.
  static String inlineImagePayload(String? url) {
    if (url == null) return '';
    final int comma = url.indexOf(',');
    if (comma < 0) return '';
    final String header = url.substring(0, comma);
    final String body = url.substring(comma + 1);
    try {
      if (header.endsWith(';base64')) {
        return utf8.decode(base64.decode(body));
      }
      return body.contains('%') ? Uri.decodeFull(body) : body;
    } catch (e) {
      debugPrint('==> inline image payload could not be decoded: $e');
      return '';
    }
  }

  /// The bytes of an inline raster image (`data:image/png;base64,...`), or
  /// null when [url] is not one / cannot be decoded.
  static Uint8List? inlineImageBytes(String? url) {
    if (url == null) return null;
    final int comma = url.indexOf(',');
    if (comma < 0) return null;
    try {
      final String header = url.substring(0, comma);
      final String body = url.substring(comma + 1);
      return header.endsWith(';base64')
          ? base64.decode(body)
          : Uint8List.fromList(utf8.encode(
              body.contains('%') ? Uri.decodeFull(body) : body,
            ));
    } catch (e) {
      debugPrint('==> inline image bytes could not be decoded: $e');
      return null;
    }
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
      return _connectionErrorMessage(e);
    }
    return _presentable(_extractErrorMessage(e));
  }

  /// Connection-class DioException: never got an HTTP response — offline,
  /// DNS failure, connection refused, a dead host, a rejected certificate,
  /// a timeout, or a request Dio itself cancelled. Anything with a real
  /// response (DioExceptionType.badResponse) carries a server message and
  /// keeps the existing extraction path untouched.
  ///
  /// [RequestCancelled] is in the list on purpose: a cancelled request also
  /// has no response, so leaving it out sent it down the extraction chain,
  /// which has nothing to extract and ends at `e.toString()` — raw
  /// "DioException [request cancelled]" text on a student's screen.
  static bool _isConnectionFailure(DioException e) {
    if (e.response != null) return false;
    final classified = NetworkExceptions.getDioException(e);
    return classified is NoInternetConnection ||
        classified is RequestTimeout ||
        classified is SendTimeout ||
        classified is RequestCancelled;
  }

  /// Student-facing one-liner for a connection failure, with a hard
  /// fallback for callers that run before LocalStorage is initialized.
  ///
  /// This runs only for a request that was ATTEMPTED, and every network
  /// path in the fleet sits behind an `AppConnectivity.connectivity()`
  /// guard (`ProfileNotifier.fetchUser` and siblings) that shows its own
  /// offline snackbar and returns without calling anything. So by the time
  /// a response-less failure lands here the device had a network moments
  /// ago, and "check your network connection" is the one thing this is NOT
  /// — it blames the reader for a server that did not answer. Ray,
  /// 2026-09-19: "not check your connection but check your network
  /// connection" and "i think it could be that the backend is unreachable
  /// rather than the phone being offline". He was right.
  ///
  /// Two outcomes, because they carry different instructions: a server
  /// that never answered is not a server that answered too slowly.
  static String _connectionErrorMessage(DioException e) {
    final bool timedOut = e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.transformTimeout;
    try {
      final message = getTranslation(
        timedOut ? TrKeys.serverTookTooLong : TrKeys.couldNotReachServer,
      ).trim();
      if (message.isNotEmpty && message != 'null') return message;
    } catch (_) {
      // Fall through to the literals below.
    }
    return timedOut ? kServerTookTooLongLine : kCouldNotReachServerLine;
  }

  /// True when [message] is one of the two connection-failure lines
  /// [errorHandler] AUTHORS in [_connectionErrorMessage] — not something
  /// scraped off an exception.
  ///
  /// Why this exists. [errorHandler] already does the honest thing for a
  /// response-less failure: it sends the verbatim cause to telemetry and
  /// returns student-facing copy that names the SERVER rather than the
  /// reader's connection. Repositories put that string into
  /// `ApiResult.failure(error:)`, so a presenter standing between the
  /// repository and the screen receives a friendly line, not technical
  /// detail — and [ErrorPresenter]'s unconditional technical branch was
  /// throwing it away for the generic "something went wrong with the
  /// server" fallback. Surfaces that render `failure` directly (the base
  /// profile page) kept the honest line; surfaces that go through the
  /// presenter (every auth screen, including login) lost it. This lets the
  /// presenter recognise its own fleet's copy instead of guessing at it.
  ///
  /// Matching is exact against the same values [_connectionErrorMessage]
  /// can return — the translated row for either key, or the two literal
  /// fallbacks — so no arbitrary server or exception text can pass.
  static bool isAuthoredConnectionMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed == kCouldNotReachServerLine ||
        trimmed == kServerTookTooLongLine) {
      return true;
    }
    for (final key in const <String>[
      TrKeys.couldNotReachServer,
      TrKeys.serverTookTooLong,
    ]) {
      try {
        final line = getTranslation(key).trim();
        if (line.isNotEmpty && line != 'null' && line == trimmed) return true;
      } catch (_) {
        // LocalStorage not initialized yet: the literals above already
        // covered the only strings this helper could have produced.
      }
    }
    return false;
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
        // Redacted at the source: this URL is debugPrinted by the
        // telemetry client in debug builds (and a debug console is a CI
        // job log), and stored server-side after that. A credential
        // carried as a query parameter must survive neither trip.
        url = redactUri(e.requestOptions.uri).toString();
      } catch (_) {}
      TelemetryClient.I.logError(
        type: 'network_unreachable',
        context: {
          'exception': e.type.name,
          // Dio folds the failing address into some transport messages.
          'message': redactLogText(e.message),
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
              color: AppStyle.surfaceFor(Theme.of(context).brightness),
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
            textColor: AppStyle.inkFor(Theme.of(context).brightness),
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
