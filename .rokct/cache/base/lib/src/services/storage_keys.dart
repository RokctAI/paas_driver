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
  static const String keyGlobalSettings = 'keyGlobalSettings';
  static const String keySettingsFetched = 'keySettingsFetched';
  static const String keyTranslations = 'keyTranslations';
  static const String keyLanguageData = 'keyLanguageData';
  static const String keyAuthenticatedWithSocial = 'keyAuthenticatedWithSocial';
  static const String keyLangLtr = 'keyLangLtr';
  static const String keyCarInfo = 'keyCarInfo';
  static const String keyShop = 'shop';
}
