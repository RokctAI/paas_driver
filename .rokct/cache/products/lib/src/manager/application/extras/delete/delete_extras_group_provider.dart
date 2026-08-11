import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/delete/delete_extras_group_notifier.dart';
import 'package:products_sdk/src/manager/application/extras/delete/delete_extras_group_state.dart';

final deleteExtrasGroupProvider =
    StateNotifierProvider<DeleteExtrasGroupNotifier, DeleteExtrasGroupState>(
  (ref) =>
      DeleteExtrasGroupNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
