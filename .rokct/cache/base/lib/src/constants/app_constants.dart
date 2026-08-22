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


import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:remixicon/remixicon.dart';
import 'package:base_sdk/src/presentation/app_assets.dart';

import 'package:base_sdk/src/services/enums.dart';

abstract class AppConstants {
  AppConstants._();

  static const bool isDemo = bool.fromEnvironment('IS_DEMO');
  static const bool isPhoneFirebase = true;
  static const int scheduleInterval = 60;
  /// Defaults to phone when SIGN_UP_TYPE isn't passed via --dart-define
  /// (e.g. a dev build that only sets IS_DEMO) — .byName('') on an empty
  /// env value throws "No enum value with that name" and crashes the
  /// login/register flow entirely, which is worse than a sensible default.
  static SignUpType get signUpType {
    const raw = String.fromEnvironment('SIGN_UP_TYPE');
    return SignUpType.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => SignUpType.phone,
    );
  }
  static const bool use24Format = true;
  static const double radius = 16;

  /// api urls
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String wsBaseUrl = String.fromEnvironment('WS_BASE_URL');
  static const String wsSecret = String.fromEnvironment('WS_SECRET');

  /// Mutable (not const) so the tenant's remote config can override it at
  /// boot — see RemoteConfigService. Share links (shop/product/group order)
  /// read it at call time, so a post-boot override is picked up everywhere.
  static String webUrl = const String.fromEnvironment('WEB_URL');
  static const String drawingBaseUrl = String.fromEnvironment('ROUTING_API');
  static String adminPageUrl = String.fromEnvironment('ADMIN_URL');
  static const String googleApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
  static const String firebaseWebKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String geminiKey = String.fromEnvironment('GEMINI_KEY');
  static const String uriPrefix = String.fromEnvironment('URL_PREFIX');
  static const String routingBaseUrl = String.fromEnvironment('ROUTING_API');
  static const String routingKey = String.fromEnvironment('ROUTING_KEY');
  static const String deepLinkHost = String.fromEnvironment('DEEP_LINK_URL');
  static const String androidPackageName = String.fromEnvironment(
    'CUSTOMER_ANDROID_PACKAGE_NAME',
  );
  static const String iosPackageName = String.fromEnvironment(
    'CUSTOMER_IOS_PACKAGE_NAME',
  );

  /// newStores and Recommendation Time
  static int newShopDays = 60;

  static bool bgImg = true;

  /// Google Maps POI
  static bool showGooglePOILayer = true;

  /// hero tags
  static const String heroTagSelectUser = 'heroTagSelectUser';
  static const String heroTagSelectAddress = 'heroTagSelectAddress';
  static const String heroTagSelectCurrency = 'heroTagSelectCurrency';
  // Shared by orders_sdk's manager create-order/POS pages and merchants_sdk's
  // manager home FAB — the Hero animation only connects when BOTH sides use
  // the same tag, which is why it is a named constant rather than a literal
  // repeated across SDKs (absorbed from the retired paas_manager host
  // app_constants.dart, manager migration M5).
  static const String heroTagAddOrderButton = 'heroTagAddOrderButton';
  static const String heroTagOrderHistory = 'heroTagOrderHistory';

  /// PayFast
  static const String passphrase = String.fromEnvironment('PAYFAST_PASSPHRASE');
  static const String merchantId = String.fromEnvironment(
    'PAYFAST_MERCHANT_ID',
  );
  static const String merchantKey = String.fromEnvironment(
    'PAYFAST_MERCHANT_KEY',
  );

  static const String demoUserLogin = String.fromEnvironment('DEMO_USER_LOGIN');
  static const String demoUserPassword = String.fromEnvironment(
    'DEMO_USER_PASSWORD',
  );

  /// locales
  static String localeCodeEn = const String.fromEnvironment('LOCALE_CODE');

  /// auth phone fields
  ///
  /// The full flag set (paas_manager#28 investigation) keeps two DISTINCT
  /// roles apart at the same call sites: [isSpecificNumberEnabled] is the UI
  /// gate (render the country-specific IntlPhoneField vs a free-form text
  /// field) while [isNumberLengthAlwaysSame] is the validation policy INSIDE
  /// the IntlPhoneField branch (disableLengthCheck / length validator /
  /// autovalidateMode). All five are env-initialized MUTABLE statics —
  /// never const — so the tenant's remote config can override them at boot
  /// (see RemoteConfigService); a compile-time const would freeze the flags
  /// against those overrides.
  static bool isSpecificNumberEnabled = const bool.fromEnvironment(
    'IS_SPECIFIC_NUMBER_ENABLED',
  );
  static bool isNumberLengthAlwaysSame = const bool.fromEnvironment(
    'IS_NUMBER_LENGTH_ALWAYS_SAME',
  );
  static String countryCodeISO = const String.fromEnvironment('COUNTRY_ISO');
  static bool showFlag = const bool.fromEnvironment('SHOW_FLAG');
  static bool showArrowIcon = const bool.fromEnvironment('SHOW_ARROW_ICON');

  /// location
  ///
  /// Mutable (not final) so the tenant's remote config can override the demo
  /// coordinates at boot — see RemoteConfigService.
  static double demoLatitude = double.parse(
    const String.fromEnvironment('DEMO_LATITUDE'),
  );
  static double demoLongitude = double.parse(
    const String.fromEnvironment('DEMO_LONGITUDE'),
  );
  static const double pinLoadingMin = 0.116666667;
  static const double pinLoadingMax = 0.611111111;

  /// Weather
  static const String openWeatherApiKey = String.fromEnvironment(
    'OPEN_WEATHER_API_KEY',
  );
  static const bool weatherIcon = true;
  static const int rainPOP = 60;

  static const Duration timeRefresh = Duration(seconds: 30);
  static const Duration animationDuration = Duration(milliseconds: 375);

  /// social sign-in
  static const socialSignIn = [
    Remix.google_fill,
    Remix.facebook_fill,
    Remix.apple_fill,
  ];

  static const socialSignInAndroid = [
    Remix.google_fill,
    Remix.facebook_fill,
  ];

  static const List infoImage = [
    Assets.imagesSave,
    Assets.imagesDelivery,
    Assets.imagesFast,
    Assets.imagesSet,
  ];

  static const List infoTitle = [
    TrKeys.saveTime,
    TrKeys.deliveryRestriction,
    TrKeys.fast,
    TrKeys.set,
  ];

  static const payLater = ["progress", "canceled", "rejected"];
  static const genderList = ["male", "female"];

  static const bool fixed = true;

  static bool cardDirect = false;

  /// Marketplace Settings
  static bool enableMarketplace = true;
  static String defaultShopId = "";
}
