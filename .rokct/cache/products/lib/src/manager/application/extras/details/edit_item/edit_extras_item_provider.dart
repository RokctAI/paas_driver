import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/details/edit_item/edit_extras_item_notifier.dart';
import 'package:products_sdk/src/manager/application/extras/details/edit_item/edit_extras_item_state.dart';

final editExtrasItemProvider =
    StateNotifierProvider<EditExtrasItemNotifier, EditExtrasItemState>(
  (ref) =>
      EditExtrasItemNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
