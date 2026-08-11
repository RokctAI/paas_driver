import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';

class FoodCategoriesState {
  const FoodCategoriesState({
    this.isLoading = false,
    this.categories = const [],
    this.activeIndex = 0,
    this.error,
  });

  final bool isLoading;
  final List<SellerCategoryData> categories;
  final int activeIndex;

  /// Set on a failed fetch. The app raised a snackbar from inside the notifier,
  /// passing a `BuildContext` into the application layer; the failure is
  /// surfaced as state instead and the page decides how to show it.
  final String? error;

  FoodCategoriesState copyWith({
    bool? isLoading,
    List<SellerCategoryData>? categories,
    int? activeIndex,
    String? error,
  }) =>
      FoodCategoriesState(
        isLoading: isLoading ?? this.isLoading,
        categories: categories ?? this.categories,
        activeIndex: activeIndex ?? this.activeIndex,
        error: error,
      );
}
