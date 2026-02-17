import 'package:freezed_annotation/freezed_annotation.dart';

part 'products_state.freezed.dart';

@freezed
class ProductsState with _$ProductsState {
  const factory ProductsState({@Default(0) int currentIndex}) = _ProductsState;

  const ProductsState._();
}
