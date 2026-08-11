/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateExtrasGroupState {
  const CreateExtrasGroupState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed create; the page decides how to show it.
  final String? error;

  CreateExtrasGroupState copyWith({bool? isLoading, String? error}) =>
      CreateExtrasGroupState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
