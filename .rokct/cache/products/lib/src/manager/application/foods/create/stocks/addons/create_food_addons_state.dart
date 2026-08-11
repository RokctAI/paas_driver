import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateFoodAddonsState {
  const CreateFoodAddonsState({
    this.isLoading = false,
    this.addons = const [],
    this.error,
  });

  final bool isLoading;
  final List<SellerProductData> addons;

  /// Set on a failed fetch; the page decides how to show it.
  final String? error;

  CreateFoodAddonsState copyWith({
    bool? isLoading,
    List<SellerProductData>? addons,
    String? error,
  }) =>
      CreateFoodAddonsState(
        isLoading: isLoading ?? this.isLoading,
        addons: addons ?? this.addons,
        error: error,
      );
}
