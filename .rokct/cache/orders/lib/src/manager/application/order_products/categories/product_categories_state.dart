import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'product_categories_state.freezed.dart';

@freezed
class ProductCategoriesState with _$ProductCategoriesState {
  const factory ProductCategoriesState({
    @Default(false) bool isLoading,
    @Default([]) List<CategoryData> categories,
    @Default(1) int activeIndex,
  }) = _ProductCategoriesState;

  const ProductCategoriesState._();
}
