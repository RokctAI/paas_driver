import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/addons/create/create_addon_notifier.dart';
import 'package:products_sdk/src/manager/application/addons/create/create_addon_state.dart';

final createAddonProvider =
    StateNotifierProvider.autoDispose<CreateAddonNotifier, CreateAddonState>(
  (ref) =>
      CreateAddonNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
