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

import 'dart:async';

import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/demo_session.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';
import 'package:base_sdk/src/services/session_handoff.dart';
import 'package:flutter/foundation.dart';

import 'package:auth_sdk/src/common/domain/interface/auth_session_policy.dart';
import 'package:auth_sdk/src/common/domain/interface/session_handoff_exchange.dart';
import 'package:auth_sdk/src/common/infrastructure/services/offline_auth_service.dart';
import 'package:auth_sdk/src/common/services/demo_account_session.dart';
import 'package:auth_sdk/src/common/services/offline_login_decision.dart';
import 'package:auth_sdk/src/common/services/session_profile.dart';

/// The local account record one fleet app hands another when there is no
/// server to mint or redeem a code (a local-only account, or the backend
/// unreachable). Display fields, role and sync state only: NEVER a
/// password, a password-vault entry or a token.
@immutable
class HandoffAccountRecord {
  const HandoffAccountRecord({
    required this.issuedAt,
    this.localId,
    this.backendUserId,
    this.synced = false,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.role,
  });

  static const int version = 1;

  /// How long a record stays usable after the sender built it.
  static const Duration maxAge = Duration(minutes: 5);

  final DateTime issuedAt;

  /// The sender's own local row id (a local account), when it has one.
  final String? localId;

  /// The backend user id, once the account exists on the backend.
  final String? backendUserId;
  final bool synced;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;

  /// The backend-verified role the sender last saw (null for a local-only
  /// account, which has none yet).
  final String? role;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': version,
        'issued_at': issuedAt.toUtc().toIso8601String(),
        if (localId != null) 'local_id': localId,
        if (backendUserId != null) 'backend_user_id': backendUserId,
        'synced': synced,
        if (firstName != null) 'firstname': firstName,
        if (lastName != null) 'lastname': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (role != null) 'role': role,
      };

  /// The record in [json], or null when it is not one this build trusts:
  /// another version, too old (or from the future), or naming no account.
  static HandoffAccountRecord? fromJson(
    Map<String, dynamic>? json, {
    DateTime? now,
  }) {
    if (json == null || json['v'] != version) return null;
    final DateTime? issued =
        DateTime.tryParse('${json['issued_at'] ?? ''}')?.toUtc();
    if (issued == null) return null;
    final DateTime at = (now ?? DateTime.now()).toUtc();
    if (at.difference(issued) > maxAge ||
        issued.difference(at) > const Duration(minutes: 1)) {
      return null;
    }
    String? text(String key) {
      final Object? v = json[key];
      if (v == null) return null;
      final String s = '$v'.trim();
      return s.isEmpty ? null : s;
    }

    final record = HandoffAccountRecord(
      issuedAt: issued,
      localId: text('local_id'),
      backendUserId: text('backend_user_id'),
      synced: json['synced'] == true,
      firstName: text('firstname'),
      lastName: text('lastname'),
      email: text('email'),
      phone: text('phone'),
      role: text('role'),
    );
    if (record.localId == null && record.backendUserId == null) return null;
    if (record.email == null && record.phone == null) return null;
    return record;
  }
}

/// Whether [policy] lets the account in [record] into this app while
/// offline. The same gate a sign-in here would face:
///
///   * a backend account whose role the sender knows: the policy's own
///     role check (the manager admits "seller" only);
///   * a local-only account (no role yet): admitted only where this app's
///     offline sign-in admits local accounts AND this app does not sign
///     people up for a particular role. A local account made on the
///     launcher asked for no role, so it is not a seller and cannot enter
///     the manager (which signs people up as seller).
bool handoffRecordAdmitted(
  AuthSessionPolicy policy,
  HandoffAccountRecord record,
) {
  final String? role = record.role;
  if (role != null && record.synced) return policy.allows(role);
  return policy.allowsOfflineAccount() && policy.signUpAppRole == null;
}

/// What became of a hand-off this app was opened with.
enum HandoffOutcomeKind {
  /// Nothing happened (no hand-off, or this app already holds a session it
  /// must keep). The app carries on as it was.
  ignored,

  /// Signed in for real with a new session of its own (server code).
  online,

  /// Signed in offline on its copy of the handed-over local account.
  offline,

  /// The account is not allowed into this app (session policy). Nothing
  /// was stored.
  rejected,
}

@immutable
class HandoffOutcome {
  const HandoffOutcome(this.kind, {this.role});

  static const HandoffOutcome ignored = HandoffOutcome(HandoffOutcomeKind.ignored);

  final HandoffOutcomeKind kind;
  final String? role;
}

/// Shared sign-in between the fleet's own apps on one phone, auth side.
///
/// Sending ([buildPayload], plugged into base_sdk's
/// SessionHandoff.payloadProvider): with a backend session and the backend
/// reachable, a one-time server code; always, when signed in, the local
/// account record as the fallback for a receiver that cannot reach the
/// backend.
///
/// Receiving ([accept]): a code is redeemed for this app's OWN new session
/// and goes through [AuthSessionPolicy] exactly as a password sign-in does.
/// Without a backend, the record becomes this app's copy of the local
/// account and signs in offline, through the same policy
/// ([handoffRecordAdmitted]). A hand-off never replaces a backend session
/// this app already holds, so apps never sign each other out.
class SessionHandoffService {
  SessionHandoffService({
    AuthRepositoryFacade? Function()? repository,
    OfflineAuthService? offlineAuth,
    Future<bool> Function()? isOnline,
    Future<String?> Function()? ownPackage,
    DateTime Function()? clock,
  })  : _repository = repository ?? (() => null),
        _offlineAuth = offlineAuth ?? OfflineAuthService(),
        _isOnline = isOnline ?? AppConnectivity.connectivity,
        _ownPackage = ownPackage ?? SessionHandoff.ownPackage,
        _clock = clock ?? DateTime.now;

  final AuthRepositoryFacade? Function() _repository;
  final OfflineAuthService _offlineAuth;
  final Future<bool> Function() _isOnline;
  final Future<String?> Function() _ownPackage;
  final DateTime Function() _clock;

  /// How long the sender waits for a server code before handing over the
  /// record alone.
  static const Duration mintTimeout = Duration(seconds: 3);

  // ------------------------------------------------------------- sending

  Future<SessionHandoffPayload?> buildPayload(String targetPackage) async {
    final String token = LocalStorage.getToken();
    if (token.isEmpty || DemoSession.demoActive) return null;
    final HandoffAccountRecord? record = await _recordFor(token);
    String? code;
    final AuthRepositoryFacade? repo = _repository();
    if (!OfflineAuthService.isOfflineToken(token) &&
        repo is SessionHandoffExchange) {
      try {
        if (await _isOnline()) {
          code = await (repo as SessionHandoffExchange)
              .mintHandoffCode(targetPackage: targetPackage)
              .timeout(mintTimeout);
        }
      } catch (_) {
        code = null;
      }
    }
    if (code == null && record == null) return null;
    return SessionHandoffPayload(code: code, account: record?.toJson());
  }

  Future<HandoffAccountRecord?> _recordFor(String token) async {
    final String? localId = OfflineAuthService.localIdOfToken(token);
    if (localId != null) {
      final row = await _offlineAuth.findById(localId);
      if (row == null) return null;
      return HandoffAccountRecord(
        issuedAt: _clock(),
        localId: row.id,
        backendUserId: row.backendUserId,
        synced: row.synced,
        firstName: row.firstName,
        lastName: row.lastName,
        email: row.email,
        phone: row.phone,
      );
    }
    final ProfileData? user = LocalStorage.getUser();
    final String? id = user?.id;
    if (user == null || id == null || id.isEmpty) return null;
    return HandoffAccountRecord(
      issuedAt: _clock(),
      backendUserId: id,
      synced: true,
      firstName: user.firstname,
      lastName: user.lastname,
      email: user.email,
      phone: user.phone,
      role: user.role,
    );
  }

  // ----------------------------------------------------------- receiving

  Future<HandoffOutcome> accept(SessionHandoffPayload payload) async {
    final String current = LocalStorage.getToken();
    // A backend session this app holds is never replaced; nor is a local
    // account of its own unless the hand-off is for that same person.
    if (current.isNotEmpty && !OfflineAuthService.isOfflineToken(current)) {
      return HandoffOutcome.ignored;
    }
    final HandoffAccountRecord? record =
        HandoffAccountRecord.fromJson(payload.account, now: _clock());

    final String? code = payload.code;
    final AuthRepositoryFacade? repo = _repository();
    if (code != null && code.isNotEmpty && repo is SessionHandoffExchange) {
      final ApiResult<LoginResponse> result =
          await (repo as SessionHandoffExchange).redeemHandoffCode(
        code: code,
        clientId: await _ownPackage(),
      );
      bool transportFailure = false;
      UserData? data;
      result.when(
        success: (r) => data = r.data,
        failure: (failure, status) =>
            transportFailure = loginFailureMeansOffline('$failure'),
      );
      final UserData? session = data;
      if (session != null && (session.accessToken ?? '').isNotEmpty) {
        return _establishOnline(session, current);
      }
      // The backend answered and refused the code: no offline fallback, so
      // the app does not sit "signed in" on a session the server rejected.
      if (!transportFailure) return HandoffOutcome.ignored;
    }

    if (record == null) return HandoffOutcome.ignored;
    return _establishOffline(record, payload.sourcePackage, current);
  }

  Future<HandoffOutcome> _establishOnline(
    UserData session,
    String current,
  ) async {
    final UserModel? user = session.user;
    final String? role = user?.role;
    if (current.isNotEmpty &&
        !await _sameLocalAccount(current, user?.email, user?.phone)) {
      return HandoffOutcome.ignored;
    }
    if (!AuthSessionPolicy.I.allows(role)) {
      // Turned away; but a session this app already holds stays as it is.
      if (current.isNotEmpty) return HandoffOutcome.ignored;
      return HandoffOutcome(HandoffOutcomeKind.rejected, role: role);
    }
    final String? linkId = OfflineAuthService.localIdOfToken(current);
    // Same order as the login flow: setToken clears any stale refresh
    // contract, so the fresh one is stored strictly after it.
    await LocalStorage.setToken(session.accessToken!);
    await SecureStorage.setRefreshToken(session.refreshToken);
    await LocalStorage.setTokenExpiry(session.expiresAt);
    if (user != null) await LocalStorage.setUser(sessionProfileOf(user));
    await applyDemoAccountSession(user);
    if (linkId != null && OfflineAuthService.isHandoffMirrorId(linkId)) {
      await _offlineAuth.linkHandoffAccount(
        linkId,
        backendUserId: user?.id,
      );
    }
    return HandoffOutcome(HandoffOutcomeKind.online, role: role);
  }

  Future<HandoffOutcome> _establishOffline(
    HandoffAccountRecord record,
    String? source,
    String current,
  ) async {
    if (current.isNotEmpty &&
        !OfflineAuthService.isHandoffMirrorToken(current) &&
        !await _sameLocalAccount(current, record.email, record.phone)) {
      return HandoffOutcome.ignored;
    }
    if (!handoffRecordAdmitted(AuthSessionPolicy.I, record)) {
      if (current.isNotEmpty) return HandoffOutcome.ignored;
      return HandoffOutcome(HandoffOutcomeKind.rejected, role: record.role);
    }
    final String sourceKey =
        '${source ?? 'app'}:${record.localId ?? 'user-${record.backendUserId}'}';
    final String? id = await _offlineAuth.importHandoffAccount(
      sourceKey: sourceKey,
      backendUserId: record.backendUserId,
      synced: record.synced,
      phone: record.phone,
      email: record.email,
      firstName: record.firstName,
      lastName: record.lastName,
    );
    if (id == null) return HandoffOutcome.ignored;
    await _offlineAuth.activateOfflineSession(id);
    await LocalStorage.setUser(ProfileData(
      id: record.backendUserId,
      firstname: record.firstName,
      lastname: record.lastName,
      email: record.email,
      phone: record.phone,
      role: record.role,
    ));
    return HandoffOutcome(HandoffOutcomeKind.offline, role: record.role);
  }

  /// Whether the offline session [current] is on the local account for
  /// [email] / [phone].
  Future<bool> _sameLocalAccount(
    String current,
    String? email,
    String? phone,
  ) async {
    final String? localId = OfflineAuthService.localIdOfToken(current);
    if (localId == null) return false;
    final row = await _offlineAuth.findById(localId);
    if (row == null) return true; // the session names nothing: nobody to keep
    bool same(String? a, String? b) =>
        a != null && a.isNotEmpty && b != null && a.toLowerCase() == b.toLowerCase();
    return same(row.email, email) || same(row.phone, phone);
  }
}
