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

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';

/// Holds an outbox handler back while the demo switch is on.
///
/// [DemoSession.demoActive] is a demo BUILD (`--dart-define=IS_DEMO=true`)
/// or the runtime demo SESSION a backend-marked account flips at sign-in
/// (base_sdk 1.61.0). Neither may reach the real backend, so while it is
/// on [push] answers [SyncResult.retryable] without handing the op to
/// [inner] at all - no local row is read, no repository is touched - and
/// the op stays queued for the first drain after the session ends (every
/// sign-out path ends in `LocalStorage.logout()`, which clears it; boot
/// and connectivity regain kick the engine). The switch is read per push,
/// so the handler `AuthSdkDependencies.register` attaches once follows it
/// with no re-registration.
///
/// The engine offers no hold verdict, so a held op counts an attempt and
/// backs off like a transient failure; a demo session sees a kick or two,
/// never the ten that park an op. A first-class hold in the engine is the
/// core follow-up.
class DemoHoldSyncHandler extends SyncHandler {
  DemoHoldSyncHandler(this.inner);

  /// The handler that does the pushing whenever the switch is off.
  final SyncHandler inner;

  /// `lastError` recorded on a held op. Neutral on purpose: an outbox
  /// row's last error can reach a sync status surface, and nothing
  /// rendered may name the demo.
  static const String sessionHoldError = 'sync paused for this session';

  @override
  Future<SyncResult> push(OutboxEntry op) {
    if (DemoSession.demoActive) {
      return Future.value(const SyncResult.retryable(sessionHoldError));
    }
    return inner.push(op);
  }

  @override
  Future<void> onSynced(OutboxEntry op, Map<String, String> idMappings) =>
      inner.onSynced(op, idMappings);
}
