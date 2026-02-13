abstract class AppConstants {
  AppConstants._();

  static const bool isDemo = bool.fromEnvironment('IS_DEMO');

  /// api urls
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static String drawingBaseUrl = const String.fromEnvironment('ROUTING_API');
  static String googleApiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const String adminPageUrl = String.fromEnvironment('ADMIN_URL', defaultValue: baseUrl);
  static String webUrl = const String.fromEnvironment('WEB_URL');
  static String routingKey = const String.fromEnvironment('ROUTING_KEY');

  /// hero tags
  static const String heroTagProfileAvatar = 'heroTagProfileAvatar';

  /// auth phone fields
  static bool isSpecificNumberEnabled = const bool.fromEnvironment('IS_SPECIFIC_NUMBER_ENABLED');
  static bool isNumberLengthAlwaysSame = const bool.fromEnvironment('IS_NUMBER_LENGTH_ALWAYS_SAME');
  static String countryCodeISO = const String.fromEnvironment('COUNTRY_ISO');
  static bool showFlag = const bool.fromEnvironment('SHOW_FLAG');
  static bool showArrowIcon = const bool.fromEnvironment('SHOW_ARROW_ICON');

  /// location
  static double demoLatitude = double.tryParse(const String.fromEnvironment('DEMO_LATITUDE')) ?? 41.304223;
  static double demoLongitude = double.tryParse(const String.fromEnvironment('DEMO_LONGITUDE')) ?? 69.2348277;
  static double pinLoadingMin = 0.116666667;
  static double pinLoadingMax = 0.611111111;

  /// demo app info
  static const String demoSellerLogin = String.fromEnvironment('DEMO_DRIVER_LOGIN');
  static const String demoSellerPassword = String.fromEnvironment('DEMO_DRIVER_PASSWORD');

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
