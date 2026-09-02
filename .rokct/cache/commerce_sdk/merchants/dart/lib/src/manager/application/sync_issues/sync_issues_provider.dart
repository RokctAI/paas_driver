// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

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
