import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// Plain immutable state, not `freezed`.
///
/// products_sdk gitignores `*.freezed.dart` and never commits it, so every
/// freezed-backed file in this package fails analysis on a fresh checkout until
/// a `build_runner` pass runs. Hand-written `copyWith` keeps the manager slice
/// analyzable on its own.
class FoodsState {
  const FoodsState({this.isLoading = false, this.foods = const []});

  final bool isLoading;
  final List<SellerProductData> foods;

  FoodsState copyWith({bool? isLoading, List<SellerProductData>? foods}) =>
      FoodsState(
        isLoading: isLoading ?? this.isLoading,
        foods: foods ?? this.foods,
      );
}
