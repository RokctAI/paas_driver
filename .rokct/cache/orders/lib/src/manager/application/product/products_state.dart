import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'products_state.freezed.dart';

@freezed
class ProductsState with _$ProductsState {
  const factory ProductsState({
    @Default(false) bool isLoading,
    @Default([]) List<TypedExtra> typedExtras,
    @Default([]) List<Stock> initialStocks,
    @Default([]) List<int> selectedIndexes,
    @Default(0) int stockCount,
    ProductData? productData,
    Stock? selectedStock,
  }) = _ProductsState;

  const ProductsState._();
}
