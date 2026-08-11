import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class AddonsState {
  const AddonsState({this.isLoading = false, this.addons = const []});

  final bool isLoading;
  final List<SellerProductData> addons;

  AddonsState copyWith({bool? isLoading, List<SellerProductData>? addons}) =>
      AddonsState(
        isLoading: isLoading ?? this.isLoading,
        addons: addons ?? this.addons,
      );
}
