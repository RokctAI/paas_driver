import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merchants_sdk/src/manager/application/sync_issues/sync_issues_state.dart';
import 'package:merchants_sdk/src/manager/infrastructure/services/sync_issues_service.dart';

/// List/resolve state for the sync-issues screen: parked local-first records
/// with per-record retry (requeue the push as-is) and discard (delete record
/// and op) actions. Every action re-reads the boxes, so the list always
/// shows the current parked set.
class SyncIssuesNotifier extends StateNotifier<SyncIssuesState> {
  SyncIssuesNotifier(this._service) : super(const SyncIssuesState());

  final SyncIssuesService _service;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    final issues = await _service.listNeedsAttention();
    if (!mounted) return;
    state = state.copyWith(isLoading: false, issues: issues);
  }

  /// Returns whether the push was actually requeued; false leaves the
  /// record parked (no matching outbox op to retry).
  Future<bool> retry(SyncIssue issue) async {
    final retried = await _service.retry(issue);
    await fetch();
    return retried;
  }

  Future<void> discard(SyncIssue issue) async {
    await _service.discard(issue);
    await fetch();
  }
}
