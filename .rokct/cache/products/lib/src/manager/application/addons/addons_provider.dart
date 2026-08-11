import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/addons/addons_notifier.dart';
import 'package:products_sdk/src/manager/application/addons/addons_state.dart';

final addonsProvider = StateNotifierProvider<AddonsNotifier, AddonsState>(
  (ref) => AddonsNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
