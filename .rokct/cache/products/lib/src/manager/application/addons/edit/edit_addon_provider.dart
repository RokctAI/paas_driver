import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/addons/edit/edit_addon_notifier.dart';
import 'package:products_sdk/src/manager/application/addons/edit/edit_addon_state.dart';

final editAddonProvider =
    StateNotifierProvider<EditAddonNotifier, EditAddonState>(
  (ref) => EditAddonNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
