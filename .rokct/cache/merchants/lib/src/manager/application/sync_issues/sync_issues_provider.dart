import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:merchants_sdk/src/manager/application/sync_issues/sync_issues_notifier.dart';
import 'package:merchants_sdk/src/manager/application/sync_issues/sync_issues_state.dart';
import 'package:merchants_sdk/src/manager/infrastructure/services/sync_issues_service.dart';

/// [SyncIssuesService] is registered by
/// `ManagerMerchantsDependencies.register` (the manager host's DI hook);
/// the direct construction fallback keeps hand-wired hosts working.
final syncIssuesProvider =
    StateNotifierProvider<SyncIssuesNotifier, SyncIssuesState>(
  (ref) => SyncIssuesNotifier(
    GetIt.instance.isRegistered<SyncIssuesService>()
        ? GetIt.instance<SyncIssuesService>()
        : SyncIssuesService(),
  ),
);
