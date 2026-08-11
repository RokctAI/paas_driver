import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/details/delete_item/delete_extras_item_notifier.dart';
import 'package:products_sdk/src/manager/application/extras/details/delete_item/delete_extras_item_state.dart';

final deleteExtrasItemProvider =
    StateNotifierProvider<DeleteExtrasItemNotifier, DeleteExtrasItemState>(
  (ref) => DeleteExtrasItemNotifier(
    GetIt.instance<SellerProductsRepositoryFacade>(),
  ),
);
