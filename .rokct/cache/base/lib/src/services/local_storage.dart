// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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


import 'dart:convert';
import 'package:base_sdk/src/models/data/address_information.dart';
import 'package:base_sdk/src/models/data/address_old_data.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:base_sdk/src/models/response/driver_show_response.dart';
import 'package:base_sdk/src/presentation/theme/app_theme.dart';
import 'package:base_sdk/src/services/secure_storage.dart';
import 'package:base_sdk/src/services/storage_keys.dart';

abstract class LocalStorage {
  LocalStorage._();

  /*/Added
  static final LocalStorage _instance = LocalStorage._internal();

  factory LocalStorage() {
    return _instance;
  }

  LocalStorage._internal();

  Future<bool> isFirstAppLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLaunch = prefs.getBool('isFirstAppLaunch') ?? true;

    return isFirstLaunch;
  }


*/ //end
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static Future<void> setToken(String? token) async {
    await _preferences?.setString(StorageKeys.keyToken, token ?? '');
    // Installing a new access token invalidates any stored refresh
    // contract. Flows that hold a fresh pair (login's establish-session,
    // TokenRefreshService) persist it straight after this call; every
    // other token-minting flow (OTP verify, offline session) mints none,
    // and a stale pair from a previous session must not linger under the
    // new token — a proactive refresh against it would kill the session.
    await deleteTokenExpiry();
    await SecureStorage.deleteRefreshToken();
  }

  static String getToken() =>
      _preferences?.getString(StorageKeys.keyToken) ?? '';

  static void deleteToken() => _preferences?.remove(StorageKeys.keyToken);

  /// Access-token expiry as returned by login/refresh
  /// (`YYYY-MM-DD HH:MM:SS`, server time); empty when the session has no
  /// recorded expiry. Null/empty [expiresAt] clears the stored value.
  static Future<void> setTokenExpiry(String? expiresAt) async {
    if (expiresAt == null || expiresAt.isEmpty) {
      await _preferences?.remove(StorageKeys.keyTokenExpiry);
    } else {
      await _preferences?.setString(StorageKeys.keyTokenExpiry, expiresAt);
    }
  }

  static String getTokenExpiry() =>
      _preferences?.getString(StorageKeys.keyTokenExpiry) ?? '';

  static Future<void> deleteTokenExpiry() async {
    await _preferences?.remove(StorageKeys.keyTokenExpiry);
  }

  static Future<void> setUiType(int type) async {
    await _preferences?.setInt(StorageKeys.keyUiType, type);
  }

  static int? getUiType() => _preferences?.getInt(StorageKeys.keyUiType);

  static Future<void> setUser(ProfileData? user) async {
    if (_preferences != null) {
      final String userString = user != null ? jsonEncode(user.toJson()) : '';
      await _preferences!.setString(StorageKeys.keyUser, userString);
    }
  }

  static ProfileData? getUser() {
    final savedString = _preferences?.getString(StorageKeys.keyUser);
    if (savedString == null) {
      return null;
    }
    final map = jsonDecode(savedString);
    if (map == null) {
      return null;
    }
    return ProfileData.fromJson(map);
  }

  static void _deleteUser() => _preferences?.remove(StorageKeys.keyUser);

  static Future<void> setSearchHistory(List<String> list) async {
    final List<String> idsStrings = list.map((e) => e.toString()).toList();
    await _preferences?.setStringList(StorageKeys.keySearchStores, idsStrings);
  }

  static List<String> getSearchList() {
    final List<String> strings =
        _preferences?.getStringList(StorageKeys.keySearchStores) ?? [];
    return strings;
  }

  static void deleteSearchList() =>
      _preferences?.remove(StorageKeys.keySearchStores);

  static Future<void> setSavedShopsList(List<String> ids) async {
    await _preferences?.setStringList(StorageKeys.keySavedStores, ids);
  }

  static List<String> getSavedShopsList() {
    return _preferences?.getStringList(StorageKeys.keySavedStores) ?? [];
  }

  static void deleteSavedShopsList() =>
      _preferences?.remove(StorageKeys.keySavedStores);

  static Future<void> setAddressSelected(AddressData data) async {
    await _preferences?.setString(
      StorageKeys.keyAddressSelected,
      jsonEncode(data.toJson()),
    );
  }

  static AddressData? getAddressSelected() {
    String dataString =
        _preferences?.getString(StorageKeys.keyAddressSelected) ?? "";
    if (dataString.isNotEmpty) {
      AddressData data = AddressData.fromJson(jsonDecode(dataString));
      // Check if the address ends with a number
      RegExp numericRegex = RegExp(r'\d$');
      if (numericRegex.hasMatch(data.address ?? "")) {
        // Use null-aware operator
        // Reorder the address components
        List<String> addressParts = (data.address ?? "")
            .split(',')
            .map((part) => part.trim())
            .toList(); // Use null-aware operator
        if (addressParts.length >= 3) {
          String postalCode =
              addressParts.removeLast(); // Remove and store postal code
          addressParts.insert(
            0,
            postalCode,
          ); // Insert postal code at the beginning
          String formattedAddress = addressParts.join(
            ', ',
          ); // Join the parts back together

          // Update the address property in the AddressData object
          data = data.copyWith(address: formattedAddress);
        }
      }
      return data;
    } else {
      return null;
    }
  }

  static void deleteAddressSelected() =>
      _preferences?.remove(StorageKeys.keyAddressSelected);

  static Future<void> setAddressInformation(AddressInformation data) async {
    await _preferences?.setString(
      StorageKeys.keyAddressInformation,
      jsonEncode(data.toJson()),
    );
  }

  static AddressInformation? getAddressInformation() {
    String dataString =
        _preferences?.getString(StorageKeys.keyAddressInformation) ?? "";
    if (dataString.isNotEmpty) {
      AddressInformation data = AddressInformation.fromJson(
        jsonDecode(dataString),
      );
      return data;
    } else {
      return null;
    }
  }

  static void deleteAddressInformation() =>
      _preferences?.remove(StorageKeys.keyAddressInformation);

  static Future<void> setLanguageSelected(bool selected) async {
    await _preferences?.setBool(StorageKeys.keyLangSelected, selected);
  }

  static bool getLanguageSelected() =>
      _preferences?.getBool(StorageKeys.keyLangSelected) ?? false;

  static void deleteLangSelected() =>
      _preferences?.remove(StorageKeys.keyLangSelected);

  static Future<void> setSelectedCurrency(CurrencyData currency) async {
    final String currencyString = jsonEncode(currency.toJson());
    await _preferences?.setString(
      StorageKeys.keySelectedCurrency,
      currencyString,
    );
  }

  static CurrencyData? getSelectedCurrency() {
    String json =
        _preferences?.getString(StorageKeys.keySelectedCurrency) ?? '';
    if (json.isEmpty) {
      return null;
    } else {
      final map = jsonDecode(json);
      return CurrencyData.fromJson(map);
    }
  }

  static void deleteSelectedCurrency() =>
      _preferences?.remove(StorageKeys.keySelectedCurrency);

  static Future<void> setWalletData(Wallet? wallet) async {
    final String walletString = jsonEncode(wallet?.toJson());
    await _preferences?.setString(StorageKeys.keyWalletData, walletString);
  }

  /// RETENTION POLICY (refork 2026-07-11 audit): wallet balance is
  /// externally-controlled, fast-changing data. Owners (wallet_sdk) must
  /// treat this as fetch-live-then-cache — refresh from the API first and
  /// use this value only as an offline fallback, never as the primary read.
  static Wallet? getWalletData() {
    final wallet = _preferences?.getString(StorageKeys.keyWalletData);
    if (wallet == null) {
      return null;
    }
    final map = jsonDecode(wallet);
    if (map == null) {
      return null;
    }
    return Wallet.fromJson(map);
  }

  static void deleteWalletData() =>
      _preferences?.remove(StorageKeys.keyWalletData);

  /// Raw JSON of the signed-in merchant's own shop (manager persona).
  ///
  /// The kernel stores it untyped: persona SDKs own their typed views of it
  /// (e.g. subscriptions_sdk reads the `subscription` submap). RETENTION:
  /// own-shop data is safe as a long-lived cache (persona owns it), but
  /// writers should refresh it after any server-side change.
  static Map<String, dynamic>? getShopJson() {
    final raw = _preferences?.getString(StorageKeys.keyShop);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setShopJson(Map<String, dynamic>? shop) async {
    if (shop == null) {
      await _preferences?.remove(StorageKeys.keyShop);
      return;
    }
    await _preferences?.setString(StorageKeys.keyShop, jsonEncode(shop));
  }

  static Future<void> setSettingsList(List<SettingsData> settings) async {
    final List<String> strings =
        settings.map((setting) => jsonEncode(setting.toJson())).toList();
    await _preferences?.setStringList(StorageKeys.keyGlobalSettings, strings);
  }

  /// RETENTION POLICY (refork 2026-07-11 audit): global settings are
  /// server-controlled configuration. Owners (comms_sdk settings) must treat
  /// this as fetch-live-then-cache — refresh from the API on session start
  /// and use this value only as an offline fallback, never as the primary
  /// read.
  static List<SettingsData> getSettingsList() {
    final List<String> settings =
        _preferences?.getStringList(StorageKeys.keyGlobalSettings) ?? [];
    final List<SettingsData> settingsList = settings
        .map((setting) => SettingsData.fromJson(jsonDecode(setting)))
        .toList();
    return settingsList;
  }

  static void deleteSettingsList() =>
      _preferences?.remove(StorageKeys.keyGlobalSettings);

  static Future<void> setTranslations(
    Map<String, dynamic>? translations,
  ) async {
    final String encoded = jsonEncode(translations);
    await _preferences?.setString(StorageKeys.keyTranslations, encoded);
  }

  static Map<String, dynamic> getTranslations() {
    final String encoded =
        _preferences?.getString(StorageKeys.keyTranslations) ?? '';
    if (encoded.isEmpty) {
      return {};
    }
    final Map<String, dynamic> decoded = jsonDecode(encoded);
    return decoded;
  }

  static void deleteTranslations() =>
      _preferences?.remove(StorageKeys.keyTranslations);

  static Future<void> setSeededTranslationsHash(String hash) async {
    await _preferences?.setString(
      StorageKeys.keySeededTranslationsHash,
      hash,
    );
  }

  static String getSeededTranslationsHash() =>
      _preferences?.getString(StorageKeys.keySeededTranslationsHash) ?? '';

  static void deleteSeededTranslationsHash() =>
      _preferences?.remove(StorageKeys.keySeededTranslationsHash);

  /// The KeySound gate: keypad tap/error feedback on or off. Default ON
  /// (the paas_pos `AppConstants.sound` default carried forward).
  static Future<void> setKeypadSound(bool enabled) async {
    await _preferences?.setBool(StorageKeys.keyKeypadSound, enabled);
  }

  static bool getKeypadSound() =>
      _preferences?.getBool(StorageKeys.keyKeypadSound) ?? true;

  static Future<void> setAppThemeMode(bool isDarkMode) async {
    await _preferences?.setBool(StorageKeys.keyAppThemeMode, isDarkMode);
  }

  /// The persisted dark-mode preference; when the user has never chosen a
  /// theme, falls back to the app's [AppTheme.defaultDarkMode] polarity
  /// (set by app glue before runApp — kernel default: light).
  static bool getAppThemeMode() =>
      _preferences?.getBool(StorageKeys.keyAppThemeMode) ??
      AppTheme.defaultDarkMode;

  static void deleteAppThemeMode() =>
      _preferences?.remove(StorageKeys.keyAppThemeMode);

  static Future<void> setThemeSeeded(bool seeded) async {
    await _preferences?.setBool(StorageKeys.keyThemeSeeded, seeded);
  }

  static bool getThemeSeeded() =>
      _preferences?.getBool(StorageKeys.keyThemeSeeded) ?? false;

  static Future<void> setSettingsFetched(bool fetched) async {
    await _preferences?.setBool(StorageKeys.keySettingsFetched, fetched);
  }

  static bool getSettingsFetched() =>
      _preferences?.getBool(StorageKeys.keySettingsFetched) ?? false;

  static void deleteSettingsFetched() =>
      _preferences?.remove(StorageKeys.keySettingsFetched);

  static Future<void> setLanguageData(LanguageData? langData) async {
    final String lang = jsonEncode(langData?.toJson());
    await _preferences?.setString(StorageKeys.keyLanguageData, lang);
  }

  static LanguageData? getLanguage() {
    final lang = _preferences?.getString(StorageKeys.keyLanguageData);
    if (lang == null) {
      return null;
    }
    final map = jsonDecode(lang);
    if (map == null) {
      return null;
    }
    return LanguageData.fromJson(map);
  }

  static void deleteLanguage() =>
      _preferences?.remove(StorageKeys.keyLanguageData);

  static Future<void> setLangLtr(bool? backward) async {
    await _preferences?.setBool(StorageKeys.keyLangLtr, (backward ?? false));
  }

  static bool getLangLtr() =>
      !(_preferences?.getBool(StorageKeys.keyLangLtr) ?? false);

  static void deleteLangLtr() => _preferences?.remove(StorageKeys.keyLangLtr);

  static deleteBoard() {
    return _preferences?.remove(StorageKeys.keyBoard);
  }

  /// RETENTION POLICY (refork 2026-07-11 audit): delivery/vehicle info is
  /// externally-controlled and can change between sessions. Owners
  /// (delivery_sdk) must treat this as fetch-live-then-cache — refresh from
  /// the API first and use this value only as an offline fallback, never as
  /// the primary read.
  static DeliveryResponse? getDeliveryInfo() {
    final savedString = _preferences?.getString(StorageKeys.keyCarInfo);
    if (savedString == null) {
      return null;
    }
    final map = jsonDecode(savedString);
    if (map == null) {
      return null;
    }
    return DeliveryResponse.fromJson(map);
  }

  static void logout() {
    deleteWalletData();
    deleteSavedShopsList();
    deleteSearchList();
    _deleteUser();
    deleteToken();
    deleteTokenExpiry();
    SecureStorage.deleteRefreshToken();
    deleteAddressSelected();
    deleteAddressInformation();
    deleteBoard();
  }
}
