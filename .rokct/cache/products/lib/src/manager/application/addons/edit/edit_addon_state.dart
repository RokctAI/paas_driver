/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class EditAddonState {
  const EditAddonState({
    this.isLoading = false,
    this.mapOfDesc = const {},
    this.error,
  });

  final bool isLoading;

  /// Locale -> `[title, description]`, one entry per authored language.
  final Map<String, List<String>> mapOfDesc;

  /// Set on a failed update; the page decides how to show it.
  final String? error;

  EditAddonState copyWith({
    bool? isLoading,
    Map<String, List<String>>? mapOfDesc,
    String? error,
  }) =>
      EditAddonState(
        isLoading: isLoading ?? this.isLoading,
        mapOfDesc: mapOfDesc ?? this.mapOfDesc,
        error: error,
      );
}
