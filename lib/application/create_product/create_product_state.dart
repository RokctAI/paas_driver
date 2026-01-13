import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_product_state.freezed.dart';

@freezed
class CreateProductState with _$CreateProductState {
  const factory CreateProductState({@Default(0) int currentIndex}) =
      _CreateProductState;

  const CreateProductState._();
}
