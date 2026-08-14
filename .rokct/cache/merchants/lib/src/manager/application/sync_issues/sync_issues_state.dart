import 'package:merchants_sdk/src/manager/infrastructure/services/sync_issues_service.dart';

/// Plain immutable state, hand-written `copyWith` — same call as
/// `MainState`/`RestaurantState` (no `build_runner` pass in this SDK).
class SyncIssuesState {
  const SyncIssuesState({
    this.isLoading = false,
    this.issues = const [],
  });

  final bool isLoading;

  /// Parked (`needs_attention`) records across the three manager boxes.
  final List<SyncIssue> issues;

  SyncIssuesState copyWith({
    bool? isLoading,
    List<SyncIssue>? issues,
  }) =>
      SyncIssuesState(
        isLoading: isLoading ?? this.isLoading,
        issues: issues ?? this.issues,
      );
}
