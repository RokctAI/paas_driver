/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class AddCategoryState {
  const AddCategoryState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed create; the page decides how to show it.
  final String? error;

  AddCategoryState copyWith({bool? isLoading, String? error}) =>
      AddCategoryState(isLoading: isLoading ?? this.isLoading, error: error);
}
