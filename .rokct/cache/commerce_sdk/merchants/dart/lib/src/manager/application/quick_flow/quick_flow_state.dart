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

import 'package:merchants_sdk/src/manager/domain/interface/quick_flow.dart';

/// Plain immutable state, hand-written `copyWith` — the
/// `MainState`/`SyncIssuesState` call in this SDK (no `build_runner` pass).
///
/// [settings] is the only truth about the surface; [saving] drives nothing
/// but the row's own busy affordance, and [loaded] is what tells the till
/// apart from "autodial is off" and "we have not asked yet" — the
/// difference matters, because an unarmed pad and an unread pad look the
/// same and only one of them should replace the ticket.
class QuickFlowState {
  const QuickFlowState({
    this.settings = const QuickFlowSettings(),
    this.isLoading = false,
    this.loaded = false,
    this.saving = false,
    this.error,
  });

  final QuickFlowSettings settings;
  final bool isLoading;

  /// A read has completed at least once (successfully or not).
  final bool loaded;

  /// A write is in flight.
  final bool saving;

  /// Last failure, surfaced by the page and cleared by the next attempt.
  final String? error;

  QuickFlowState copyWith({
    QuickFlowSettings? settings,
    bool? isLoading,
    bool? loaded,
    bool? saving,
    String? error,
    bool clearError = false,
  }) =>
      QuickFlowState(
        settings: settings ?? this.settings,
        isLoading: isLoading ?? this.isLoading,
        loaded: loaded ?? this.loaded,
        saving: saving ?? this.saving,
        error: clearError ? null : (error ?? this.error),
      );
}
