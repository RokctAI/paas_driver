import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/details/new_item/create_new_group_item_notifier.dart';
import 'package:products_sdk/src/manager/application/extras/details/new_item/create_new_group_item_state.dart';

final createNewGroupItemProvider =
    StateNotifierProvider<CreateNewGroupItemNotifier, CreateNewGroupItemState>(
  (ref) => CreateNewGroupItemNotifier(
    GetIt.instance<SellerProductsRepositoryFacade>(),
  ),
);
