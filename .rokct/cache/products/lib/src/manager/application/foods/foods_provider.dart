import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/foods/foods_notifier.dart';
import 'package:products_sdk/src/manager/application/foods/foods_state.dart';

final foodsProvider = StateNotifierProvider<FoodsNotifier, FoodsState>(
  (ref) => FoodsNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
