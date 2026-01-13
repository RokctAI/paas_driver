abstract class AppConstants {
  AppConstants._();

  static const bool isDemo = false;

  /// api urls
  static const String baseUrl = 'https://juvo.tenant.rokct.ai/';
  static String drawingBaseUrl = 'https://api.openrouteservice.org';
  static String googleApiKey = 'Yor Map key';
  static const String adminPageUrl = baseUrl;
  static String webUrl = 'https://web.juvo.app';
  static String routingKey =
      '5b3ce3597851110001cf62480384c1db92764d1b8959761ea2510ac8';

  /// hero tags
  static const String heroTagProfileAvatar = 'heroTagProfileAvatar';

  /// auth phone fields
  static bool isSpecificNumberEnabled = false;
  static bool isNumberLengthAlwaysSame = true;
  static String countryCodeISO = 'UZ';
  static bool showFlag = true;
  static bool showArrowIcon = true;

  /// location
  static double demoLatitude = 41.304223;
  static double demoLongitude = 69.2348277;
  static double pinLoadingMin = 0.116666667;
  static double pinLoadingMax = 0.611111111;

  /// demo app info
  static const String demoSellerLogin = 'delivery@githubit.com';
  static const String demoSellerPassword = 'delivery';

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
