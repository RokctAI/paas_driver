import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/restaurant_notifier.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/restaurant_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';

/// [SellerShopRepositoryFacade] is registered by
/// `ManagerMerchantsDependencies.register`; [GalleryRepositoryFacade] by
/// base_sdk's own DI.
final restaurantProvider =
    StateNotifierProvider<RestaurantNotifier, RestaurantState>(
  (ref) => RestaurantNotifier(
    GetIt.instance<SellerShopRepositoryFacade>(),
    GetIt.instance<GalleryRepositoryFacade>(),
  ),
);
