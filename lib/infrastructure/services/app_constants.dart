class AppConstants {
  AppConstants._();

  static const bool appStoreMode = false;

  /// shared preferences keys
  static const String keyLangSelected = 'keyLangSelected';
  static const String keyUser = 'keyUser';
  static const String keyOnline = 'keyOnline';
  static const String keyCarInfo = 'keyCarInfo';
  static const String keyToken = 'keyToken';
  static const String keyAddressSelected = 'keyAddressSelected';
  static const String keySelectedCurrency = 'keySelectedCurrency';
  static const String keyAppThemeMode = 'keyAppThemeMode';
  static const String keyGlobalSettings = 'keyGlobalSettings';
  static const String keyTranslations = 'keyTranslations';
  static const String keyLanguageData = 'keyLanguageData';
  static const String keyLangLtr = 'keyLangLtr';
  static const String keyWallet = 'keyWallet';

  /// hero tags
  static const String heroTagProfileAvatar = 'heroTagProfileAvatar';

  /// app strings
  static const String emptyString = '';

  /// api urls
  static const String drawingBaseUrl = 'https://api.openrouteservice.org';
  static const String baseUrl = 'https://api.foodyman.org';
  static const String imageBaseUrl = '$baseUrl/storage/images';
  static const String googleApiKey = 'AIzaSyBgNvtPqsuKcgp26ukVPobjKw0Igx2dp5M';
  static const String routingKey =
      '5b3ce3597851110001cf62480384c1db92764d1b8959761ea2510ac8';
  static const String privacyPolicyUrl = '$baseUrl/privacy-policy';
  static const String webUrl = 'https://foodyman.org';



  /// auth phone fields
  static const bool isSpecificNumberEnabled = false;
  static const bool isNumberLengthAlwaysSame = true;
  static const String countryCodeISO = 'UZ';
  static const bool showFlag = true;
  static const bool showArrowIcon = true;



  /// locales
  static const String localeCodeEn = 'en';

  /// location
  static const double demoLatitude = 41.304223;
  static const double demoLongitude = 69.2348277;
  static const double pinLoadingMin = 0.116666667;
  static const double pinLoadingMax = 0.611111111;

  /// demo app info
  static const String demoSellerLogin = 'delivery@githubit.com';
  static const String demoSellerPassword = 'delivery';
}

enum UploadType {
  extras,
  brands,
  categories,
  shopsLogo,
  shopsBack,
  products,
  reviews,
  users,
  deliveryCar
}