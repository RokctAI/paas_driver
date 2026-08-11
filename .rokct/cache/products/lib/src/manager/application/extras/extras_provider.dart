import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/extras_notifier.dart';
import 'package:products_sdk/src/manager/application/extras/extras_state.dart';

final extrasProvider = StateNotifierProvider<ExtrasNotifier, ExtrasState>(
  (ref) => ExtrasNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
