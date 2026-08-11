import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/details/extras_group_details_notifier.dart';
import 'package:products_sdk/src/manager/application/extras/details/extras_group_details_state.dart';

final extrasGroupDetailsProvider =
    StateNotifierProvider<ExtrasGroupDetailsNotifier, ExtrasGroupDetailsState>(
  (ref) => ExtrasGroupDetailsNotifier(
    GetIt.instance<SellerProductsRepositoryFacade>(),
  ),
);
