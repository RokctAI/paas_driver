import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class ExtrasState {
  const ExtrasState({
    this.isLoading = false,
    this.isSaving = false,
    this.groups = const [],
  });

  final bool isLoading;
  final bool isSaving;
  final List<SellerExtrasGroup> groups;

  ExtrasState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<SellerExtrasGroup>? groups,
  }) =>
      ExtrasState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        groups: groups ?? this.groups,
      );
}
