import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/create_food_details_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/create_food_details_state.dart';

final createFoodDetailsProvider =
    StateNotifierProvider<CreateFoodDetailsNotifier, CreateFoodDetailsState>(
  (ref) => CreateFoodDetailsNotifier(
    GetIt.instance<SellerProductsRepositoryFacade>(),
    GetIt.instance<GalleryRepositoryFacade>(),
  ),
);
