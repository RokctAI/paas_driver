import 'package:base_sdk/src/models/data/shop_data.dart';

/// Plain immutable state rather than a `freezed` union — merchants_sdk
/// convention (see `application/main/main_state.dart`).
///
/// [shop] is base_sdk's [ShopData]; the legacy manager twin is not carried
/// over. `orderPayment` mirrors the legacy field that base's model lacks.
class RestaurantState {
  const RestaurantState({
    this.isLoading = false,
    this.backgroundImageFile,
    this.logoImageFile,
    this.orderPayment,
    this.shop,
  });

  final bool isLoading;
  final String? backgroundImageFile;
  final String? logoImageFile;
  final String? orderPayment;
  final ShopData? shop;

  RestaurantState copyWith({
    bool? isLoading,
    String? backgroundImageFile,
    String? logoImageFile,
    String? orderPayment,
    ShopData? shop,
    bool clearBackgroundImageFile = false,
    bool clearLogoImageFile = false,
  }) =>
      RestaurantState(
        isLoading: isLoading ?? this.isLoading,
        backgroundImageFile: clearBackgroundImageFile
            ? null
            : (backgroundImageFile ?? this.backgroundImageFile),
        logoImageFile:
            clearLogoImageFile ? null : (logoImageFile ?? this.logoImageFile),
        orderPayment: orderPayment ?? this.orderPayment,
        shop: shop ?? this.shop,
      );
}
