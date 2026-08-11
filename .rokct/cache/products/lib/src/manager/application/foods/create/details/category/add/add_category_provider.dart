import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/category/add/add_category_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/create/details/category/add/add_category_state.dart';

final addCategoryProvider =
    StateNotifierProvider.autoDispose<AddCategoryNotifier, AddCategoryState>(
  (ref) =>
      AddCategoryNotifier(GetIt.instance<SellerCatalogRepositoryFacade>()),
);
