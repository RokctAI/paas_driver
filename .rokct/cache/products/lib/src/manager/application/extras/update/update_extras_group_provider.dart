import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/update/update_extras_group_notifier.dart';
import 'package:products_sdk/src/manager/application/extras/update/update_extras_group_state.dart';

final updateExtrasGroupProvider =
    StateNotifierProvider<UpdateExtrasGroupNotifier, UpdateExtrasGroupState>(
  (ref) =>
      UpdateExtrasGroupNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
