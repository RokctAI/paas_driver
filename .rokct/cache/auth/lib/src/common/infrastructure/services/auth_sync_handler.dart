// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:convert';

import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';

import 'offline_auth_service.dart';

/// Pushes `auth.register` outbox ops: a registration that happened offline
/// (local account row + offline session) is registered with the real
/// backend the next time the SyncEngine drains (boot / connectivity
/// regain). Registered with the engine in `AuthSdkDependencies.register`.
///
/// Payload contract (written by RegisterNotifier): `{"localUserId": "<id>"}`
/// — the row itself stays the source of truth so an account edited or
/// discarded locally between enqueue and drain is pushed as it is now, not
/// as it was.
class AuthSyncHandler extends SyncHandler {
  AuthSyncHandler({
    OfflineAuthService? offlineAuth,
    AuthRepositoryFacade? authRepository,
  })  : _offlineAuth = offlineAuth ?? OfflineAuthService(),
        _authRepositoryOverride = authRepository;

  /// Op type this handler serves.
  static const String opType = 'auth.register';

  /// `sdk` column value for ops this SDK enqueues.
  static const String sdkName = 'auth_sdk';

  final OfflineAuthService _offlineAuth;
  final AuthRepositoryFacade? _authRepositoryOverride;

  // Resolved lazily: at DI-registration time the facade registration order
  // between SDKs is not guaranteed, at push time it is.
  AuthRepositoryFacade get _authRepository =>
      _authRepositoryOverride ?? GetIt.instance<AuthRepositoryFacade>();

  /// Temp-id token for a local account, matching the engine's
  /// `offline:<id>` mapping convention.
  static String tempIdFor(String localUserId) =>
      '$kOfflineIdPrefix$localUserId';

  @override
  Future<SyncResult> push(OutboxEntry op) async {
    final String localUserId;
    try {
      final payload = jsonDecode(op.payload) as Map<String, dynamic>;
      localUserId = (payload['localUserId'] ?? '') as String;
    } catch (e) {
      return SyncResult.rejected('auth.register payload unreadable: $e');
    }
    if (localUserId.isEmpty) {
      return const SyncResult.rejected('auth.register op missing localUserId');
    }

    final row = await _offlineAuth.findById(localUserId);
    if (row == null) {
      // Account discarded locally since enqueue; nothing left to push.
      return const SyncResult.synced();
    }
    if (row.synced) {
      // Already reconciled (e.g. the register flow finished online after
      // this op was enqueued). Surface the mapping; skip the network.
      return SyncResult.synced(
        idMappings: row.backendUserId == null
            ? const {}
            : {tempIdFor(localUserId): row.backendUserId!},
        entityType: 'user',
      );
    }

    final outcome = await _offlineAuth.syncOne(row, _authRepository);
    if (outcome.success) {
      // The offline:<localUserId> -> backendUserId mapping lets queued ops
      // created while logged in as the temp user get rewritten.
      return SyncResult.synced(
        idMappings: outcome.backendUserId == null
            ? const {}
            : {tempIdFor(localUserId): outcome.backendUserId!},
        entityType: 'user',
      );
    }
    // NetworkExceptions.getDioStatus maps connection failures and timeouts
    // to 500, so >= 500 (plus 408) is "backend unreachable / transient";
    // a concrete 4xx (phone or email already registered, validation) is a
    // definitive rejection to park with the server's message.
    final status = outcome.statusCode;
    if (status != null && status >= 400 && status < 500 && status != 408) {
      return SyncResult.rejected(
        outcome.error ?? 'registration rejected (HTTP $status)',
      );
    }
    return SyncResult.retryable(outcome.error ?? 'network error');
  }
}
