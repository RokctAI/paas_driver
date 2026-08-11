/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateAddonState {
  const CreateAddonState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed create; the page decides how to show it.
  final String? error;

  CreateAddonState copyWith({bool? isLoading, String? error}) =>
      CreateAddonState(isLoading: isLoading ?? this.isLoading, error: error);
}
