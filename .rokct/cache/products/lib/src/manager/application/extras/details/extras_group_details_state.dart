import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class ExtrasGroupDetailsState {
  const ExtrasGroupDetailsState({
    this.isLoading = false,
    this.extras = const [],
  });

  final bool isLoading;
  final List<SellerExtras> extras;

  ExtrasGroupDetailsState copyWith({
    bool? isLoading,
    List<SellerExtras>? extras,
  }) =>
      ExtrasGroupDetailsState(
        isLoading: isLoading ?? this.isLoading,
        extras: extras ?? this.extras,
      );
}
