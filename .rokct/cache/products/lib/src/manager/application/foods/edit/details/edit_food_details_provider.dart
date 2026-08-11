import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/edit_food_details_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/edit_food_details_state.dart';

final editFoodDetailsProvider =
    StateNotifierProvider<EditFoodDetailsNotifier, EditFoodDetailsState>(
  (ref) => EditFoodDetailsNotifier(
    GetIt.instance<SellerProductsRepositoryFacade>(),
    GetIt.instance<GalleryRepositoryFacade>(),
  ),
);
