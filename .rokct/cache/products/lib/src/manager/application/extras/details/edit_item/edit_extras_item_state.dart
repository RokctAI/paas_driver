/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class EditExtrasItemState {
  const EditExtrasItemState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed update; the page decides how to show it.
  final String? error;

  EditExtrasItemState copyWith({bool? isLoading, String? error}) =>
      EditExtrasItemState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
