abstract class AppConstants {
  AppConstants._();

  static const bool isDemo = bool.fromEnvironment('IS_DEMO');

  /// api urls
  static const String baseUrl = String.fromEnvironment('BASE_URL');
  static const String drawingBaseUrl = String.fromEnvironment('ROUTING_API');
  static const String googleApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );
  static const String adminPageUrl = String.fromEnvironment('ADMIN_URL');
  static const String webUrl = String.fromEnvironment('WEB_URL');
  static const String routingKey = String.fromEnvironment('ROUTING_KEY');
  static const String androidPackageName = String.fromEnvironment(
    'DRIVER_ANDROID_PACKAGE_NAME',
  );
  static const String iosPackageName = String.fromEnvironment(
    'DRIVER_IOS_PACKAGE_NAME',
  );

  /// hero tags
  static const String heroTagProfileAvatar = 'heroTagProfileAvatar';

  /// auth phone fields
  static const bool isSpecificNumberEnabled = bool.fromEnvironment(
    'IS_SPECIFIC_NUMBER_ENABLED',
  );
  static const bool isNumberLengthAlwaysSame = bool.fromEnvironment(
    'IS_NUMBER_LENGTH_ALWAYS_SAME',
  );
  static const String countryCodeISO = String.fromEnvironment('COUNTRY_ISO');
  static const bool showFlag = bool.fromEnvironment('SHOW_FLAG');
  static const bool showArrowIcon = bool.fromEnvironment('SHOW_ARROW_ICON');

  /// location
  static final double demoLatitude = double.parse(
    const String.fromEnvironment('DEMO_LATITUDE'),
  );
  static final double demoLongitude = double.parse(
    const String.fromEnvironment('DEMO_LONGITUDE'),
  );
  static const double pinLoadingMin = 0.116666667;
  static const double pinLoadingMax = 0.611111111;

  /// demo app info
  static const String demoSellerLogin = String.fromEnvironment(
    'DEMO_DRIVER_LOGIN',
  );
  static const String demoSellerPassword = String.fromEnvironment(
    'DEMO_DRIVER_PASSWORD',
  );
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
  deliveryCar,
}
