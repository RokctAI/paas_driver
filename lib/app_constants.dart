abstract class AppConstants {
  AppConstants._();

  static const bool isDemo = true;

  /// api urls
  static const String baseUrl = 'https://api.foodyman.org/';
  static const String drawingBaseUrl = 'https://api.openrouteservice.org';
  static const String googleApiKey = 'Yor Map key';
  static const String adminPageUrl = 'https://admin.foodyman.org';
  static const String webUrl = 'https://foodyman.org';
  static const String routingKey =
      '5b3ce3597851110001cf62480384c1db92764d1b8959761ea2510ac8';

  /// hero tags
  static const String heroTagProfileAvatar = 'heroTagProfileAvatar';

  /// auth phone fields
  static const bool isSpecificNumberEnabled = false;
  static const bool isNumberLengthAlwaysSame = true;
  static const String countryCodeISO = 'UZ';
  static const bool showFlag = true;
  static const bool showArrowIcon = true;

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
