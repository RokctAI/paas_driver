import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateFoodStocksState {
  const CreateFoodStocksState({
    this.isLoading = false,
    this.isSaving = false,
    this.isFetchingGroups = false,
    this.groups = const [],
    this.stocks = const [],
    this.activeGroupExtras = const [],
    this.selectGroups = const {},
    this.error,
  });

  final bool isLoading;
  final bool isSaving;
  final bool isFetchingGroups;
  final List<SellerExtrasGroup> groups;
  final List<SellerStock> stocks;
  final List<SellerExtras> activeGroupExtras;

  /// Selected extra values keyed by group id (as string) — the cartesian
  /// product of the values becomes the stock variants.
  final Map<String, List<SellerExtras?>> selectGroups;

  /// Set on a failed fetch or save; the page decides how to show it.
  final String? error;

  CreateFoodStocksState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isFetchingGroups,
    List<SellerExtrasGroup>? groups,
    List<SellerStock>? stocks,
    List<SellerExtras>? activeGroupExtras,
    Map<String, List<SellerExtras?>>? selectGroups,
    String? error,
  }) =>
      CreateFoodStocksState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        isFetchingGroups: isFetchingGroups ?? this.isFetchingGroups,
        groups: groups ?? this.groups,
        stocks: stocks ?? this.stocks,
        activeGroupExtras: activeGroupExtras ?? this.activeGroupExtras,
        selectGroups: selectGroups ?? this.selectGroups,
        error: error,
      );
}
