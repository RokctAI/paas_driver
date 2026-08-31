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


abstract class StorageKeys {
  StorageKeys._();

  /// shared preferences keys
  static const String keyLangSelected = 'keyLangSelected';
  static const String keyUser = 'keyUser';
  static const String keyToken = 'keyToken';
  // Access-token expiry (not secret — the refresh token itself lives in
  // SecureStorage, not in shared preferences).
  static const String keyTokenExpiry = 'keyTokenExpiry';
  static const String keyUiType = 'keyUiType';
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
}
