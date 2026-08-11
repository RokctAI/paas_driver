import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/manager/application/addons/edit/units/edit_addon_units_notifier.dart';
import 'package:products_sdk/src/manager/application/addons/edit/units/edit_addon_units_state.dart';

final editAddonUnitsProvider =
    StateNotifierProvider<EditAddonUnitsNotifier, EditAddonUnitsState>(
  (ref) =>
      EditAddonUnitsNotifier(GetIt.instance<SellerCatalogRepositoryFacade>()),
);
