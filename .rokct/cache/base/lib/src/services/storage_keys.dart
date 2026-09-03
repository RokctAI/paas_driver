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


abstract class StorageKeys {
  StorageKeys._();

  /// shared preferences keys
  static const String keyLangSelected = 'keyLangSelected';
  static const String keyUser = 'keyUser';
  static const String keyToken = 'keyToken';
  // Access-token expiry (not secret — the refresh token itself lives in
  // SecureStorage, not in shared preferences).
  static const String keyTokenExpiry = 'keyTokenExpiry';
  static const String keyLocaleCode = 'keyLocaleCode';
  static const String keyBoard = 'keyBoard';
  static const String keyProfileImage = 'keyProfileImage';
  static const String keySavedStores = 'keySavedStores';
  static const String keySearchStores = 'keySearchStores';
  static const String keyViewedProducts = 'keyViewedProducts';
  static const String keyAddressSelected = 'keyAddressSelected';
  static const String keyAddressInformation = 'keyAddressInformation';
  static const String keyIsGuest = 'keyIsGuest';
  static const String keyLocalAddresses = 'keyLocalAddresses';
  static const String keyActiveAddressTitle = 'keyActiveAddressTitle';
  static const String keyLikedProducts = 'keyLikedProducts';
  static const String keySelectedCurrency = 'keySelectedCurrency';
  static const String keyCartProducts = 'keyCartProducts';
  static const String keyAppThemeMode = 'keyAppThemeMode';
  // Marks that the app's theme has been initialised once, so a composed app
  // can apply a dark-first (or light-first) default on the very first launch
  // and thereafter respect the user's explicit choice.
  static const String keyThemeSeeded = 'keyThemeSeeded';
  static const String keyWalletData = 'keyWalletData';
  // The key-feedback on/off gate (KeySound): tap.wav + haptic on every
  // keypad press. Default ON (paas_pos AppConstants.sound parity).
  static const String keyKeypadSound = 'keyKeypadSound';
  static const String keyGlobalSettings = 'keyGlobalSettings';
  static const String keySettingsFetched = 'keySettingsFetched';
  static const String keyTranslations = 'keyTranslations';
  // Fingerprint of the last candidate set TranslationSeeder successfully
  // pushed to the backend, so each candidate set is only pushed once.
  static const String keySeededTranslationsHash = 'keySeededTranslationsHash';
  static const String keyLanguageData = 'keyLanguageData';
  static const String keyAuthenticatedWithSocial = 'keyAuthenticatedWithSocial';
  static const String keyLangLtr = 'keyLangLtr';
  static const String keyCarInfo = 'keyCarInfo';
  static const String keyShop = 'shop';

  // Namespace for the generic JSON key API (LocalStorage.setJson/getJson/
  // deleteJson): every caller-supplied key is stored as
  // `keyHostRecordPrefix + key`, so a host-owned record can never land on
  // one of the typed keys above (or on a bare key another SDK writes to the
  // same SharedPreferences directly).
  static const String keyHostRecordPrefix = 'hostRecord.';
  // First-run setup progress (design 46e): the sub-key onboarding_sdk's
  // progress store hands to setOnboardingRun/getOnboardingRun. Stored as
  // `hostRecord.onboardingRun`.
  static const String keyOnboardingRun = 'onboardingRun';
}
