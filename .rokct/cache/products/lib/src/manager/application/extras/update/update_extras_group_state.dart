/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class UpdateExtrasGroupState {
  const UpdateExtrasGroupState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed update; the page decides how to show it.
  final String? error;

  UpdateExtrasGroupState copyWith({bool? isLoading, String? error}) =>
      UpdateExtrasGroupState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
