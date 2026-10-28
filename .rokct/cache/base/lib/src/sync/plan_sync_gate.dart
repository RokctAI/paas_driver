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

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';

/// Gateway cmd (merchants backend) that answers "may this shop's data leave
/// the device?".
const String kSyncStatusCmd = 'api.seller_subscription.get_sync_status';

const String _kCacheKey = 'base_sdk.plan_sync_gate.allowed';

/// Whether screens that only a paying (or unrestricted) seller gets, such as
/// the productivity group, should be shown.
///
/// True by default, so every app that never installs [PlanSyncGate] is
/// unchanged. [PlanSyncGate] sets it to the sync answer: with no plan or the
/// free plan the value is false and the host hides those entries. Purely
/// client-side; the host reads it, nothing is sent anywhere.
class PlanAccess {
  PlanAccess._();

  static final ValueNotifier<bool> planGatedVisible = ValueNotifier<bool>(true);

  static final Set<String> _gatedSections = <String>{};

  /// Declares profile section ids that need a plan. An SDK (subscriptions_sdk
  /// does, for the whole fleet) calls this once at bootstrap; the profile
  /// registry then leaves those sections out while [planGatedVisible] is
  /// false. Adding an id is the only step, no per-SDK code. Inert in apps
  /// that never install [PlanSyncGate].
  static void gateProfileSections(Iterable<String> ids) =>
      _gatedSections.addAll(ids);

  /// True when [id] was declared plan-gated and the seller has no plan.
  static bool isSectionHidden(String id) =>
      !planGatedVisible.value && _gatedSections.contains(id);

  @visibleForTesting
  static void reset() {
    _gatedSections.clear();
    planGatedVisible.value = true;
  }
}

/// The free local-only tier's sync gate.
///
/// Registered on [SyncEngine.pushGate] by an app that ships a free tier
/// (nothing registers it by default, so every other app drains exactly as
/// before). While it answers false the outbox keeps every op `pending`:
/// local selling, receipts and stock are never touched, only the upload
/// waits. Account creation and sign-in do not go through the outbox and are
/// never gated.
///
/// The answer comes from the backend ([kSyncStatusCmd]) and is cached on
/// the device so offline use never blocks. With no answer and no cache yet
/// the data stays local.
class PlanSyncGate {
  PlanSyncGate({
    Future<dynamic> Function()? fetch,
    Future<bool?> Function()? readCache,
    Future<void> Function(bool)? writeCache,
    this.fetchTimeout = const Duration(seconds: 5),
  })  : _fetch = fetch ?? _gatewayFetch,
        _readCache = readCache ?? _prefsRead,
        _writeCache = writeCache ?? _prefsWrite;

  /// How long [allowsPush] waits for the backend before falling back to the
  /// cached answer; [SyncEngine.kick] awaits the gate, so a hung connection
  /// must not stall its callers.
  final Duration fetchTimeout;

  final Future<dynamic> Function() _fetch;
  final Future<bool?> Function() _readCache;
  final Future<void> Function(bool) _writeCache;

  /// Registers this gate on the sync engine.
  void install([SyncEngine? engine]) {
    (engine ?? SyncEngine()).pushGate = allowsPush;
    // Start from the cached answer so the gated entries are hidden from the
    // first frame on a free device; allowsPush corrects it once online.
    _readCache().then((bool? cached) {
      PlanAccess.planGatedVisible.value = cached ?? false;
    }).catchError((Object _) {});
  }

  /// Backend answer when reachable (and cached), else the cached answer,
  /// else false.
  Future<bool> allowsPush() async {
    try {
      final dynamic body = await _fetch().timeout(fetchTimeout);
      final bool? allowed = _parse(body);
      if (allowed != null) {
        await _writeCache(allowed);
        PlanAccess.planGatedVisible.value = allowed;
        return allowed;
      }
    } catch (e) {
      debugPrint('==> plan sync gate: status fetch failed: $e');
    }
    final bool cached = (await _readCache()) ?? false;
    PlanAccess.planGatedVisible.value = cached;
    return cached;
  }

  /// Re-asks the backend and, if the gate has just opened (a plan was
  /// bought), drains the backlog. Call after a purchase.
  Future<void> refreshAndKick([SyncEngine? engine]) =>
      (engine ?? SyncEngine()).kick();

  static bool? _parse(dynamic body) {
    dynamic data = body;
    if (data is Map && data['message'] is Map) data = data['message'];
    if (data is Map && data['sync_allowed'] != null) {
      final dynamic v = data['sync_allowed'];
      return v == true || v == 1 || v == 'true';
    }
    return null;
  }

  static Future<dynamic> _gatewayFetch() =>
      const PlatformGateway().tenant(kSyncStatusCmd);

  static Future<bool?> _prefsRead() async =>
      (await SharedPreferences.getInstance()).getBool(_kCacheKey);

  static Future<void> _prefsWrite(bool value) async {
    await (await SharedPreferences.getInstance()).setBool(_kCacheKey, value);
  }
}
