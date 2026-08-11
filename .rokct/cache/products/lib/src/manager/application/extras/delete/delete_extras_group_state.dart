/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class DeleteExtrasGroupState {
  const DeleteExtrasGroupState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed delete; the page decides how to show it.
  final String? error;

  DeleteExtrasGroupState copyWith({bool? isLoading, String? error}) =>
      DeleteExtrasGroupState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
