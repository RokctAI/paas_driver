/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class DeleteExtrasItemState {
  const DeleteExtrasItemState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed delete; the page decides how to show it.
  final String? error;

  DeleteExtrasItemState copyWith({bool? isLoading, String? error}) =>
      DeleteExtrasItemState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
