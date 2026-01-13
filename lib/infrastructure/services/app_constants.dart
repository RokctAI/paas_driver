class AppConstants {
  AppConstants._();

  static bool appStoreMode = false;

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
  static String drawingBaseUrl = 'https://api.openrouteservice.org';
  static String baseUrl = 'https://api.foodyman.org';
  static String imageBaseUrl = '$baseUrl/storage/images';
  static String googleApiKey = 'AIzaSyBgNvtPqsuKcgp26ukVPobjKw0Igx2dp5M';
  static String routingKey =
      '5b3ce3597851110001cf62480384c1db92764d1b8959761ea2510ac8';
  static String privacyPolicyUrl = '$baseUrl/privacy-policy';
  static String webUrl = 'https://foodyman.org';



  /// auth phone fields
  static bool isSpecificNumberEnabled = false;
  static bool isNumberLengthAlwaysSame = true;
  static String countryCodeISO = 'ZA';
  static bool showFlag = true;
  static bool showArrowIcon = true;



  /// locales
  static String localeCodeEn = 'en';

  /// location
  static double demoLatitude = 41.304223;
  static double demoLongitude = 69.2348277;
  static double pinLoadingMin = 0.116666667;
  static double pinLoadingMax = 0.611111111;

  /// demo app info
  static const String demoSellerLogin = '';
  static const String demoSellerPassword = '';

  ///Google Maps POI
  static bool showGooglePOILayer = true;
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