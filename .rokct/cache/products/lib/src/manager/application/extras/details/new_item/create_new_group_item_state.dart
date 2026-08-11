/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateNewGroupItemState {
  const CreateNewGroupItemState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed create; the page decides how to show it.
  final String? error;

  CreateNewGroupItemState copyWith({bool? isLoading, String? error}) =>
      CreateNewGroupItemState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
