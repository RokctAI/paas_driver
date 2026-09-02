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
