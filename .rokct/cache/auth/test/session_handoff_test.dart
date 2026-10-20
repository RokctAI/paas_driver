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

// Shared sign-in between the fleet's own apps (Ray: "its one device and same
// account so i expect them to use same token"; "what happens if the account
// is local only and backend is not available?").

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/secure_storage.dart';
import 'package:base_sdk/src/services/session_handoff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/src/common/domain/interface/auth_session_policy.dart';
import 'package:auth_sdk/src/common/domain/interface/session_handoff_exchange.dart';
import 'package:auth_sdk/src/common/infrastructure/repositories/auth_repository.dart';
import 'package:auth_sdk/src/common/infrastructure/services/offline_auth_service.dart';
import 'package:auth_sdk/src/common/services/session_handoff_service.dart';

class MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _Repo implements AuthRepositoryFacade, SessionHandoffExchange {
  String? mintAnswer;
  ApiResult<LoginResponse>? redeemAnswer;
  final List<String?> mintedFor = [];
  final List<String?> redeemedBy = [];

  @override
  Future<String?> mintHandoffCode({String? targetPackage}) async {
    mintedFor.add(targetPackage);
    return mintAnswer;
  }

  @override
  Future<ApiResult<LoginResponse>> redeemHandoffCode({
    required String code,
    String? clientId,
  }) async {
    redeemedBy.add(clientId);
    return redeemAnswer!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// OfflineAuthService without a database: rows live in a map.
class _Offline extends OfflineAuthService {
  final Map<String, OfflineUserEntity> rows = {};
  final List<String> linked = [];

  @override
  Future<OfflineUserEntity?> findById(String localUserId) async =>
      rows[localUserId];

  @override
  Future<String?> importHandoffAccount({
    required String sourceKey,
    String? backendUserId,
    bool synced = false,
    String? phone,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    final id = '${OfflineAuthService.handoffIdPrefix}$sourceKey';
    rows[id] = OfflineUserEntity(
      id: id,
      phone: phone,
      email: email,
      firstName: firstName,
      lastName: lastName,
      passwordHash: 'random',
      synced: synced,
      backendUserId: backendUserId,
      createdAt: DateTime(2026),
    );
    return id;
  }

  @override
  Future<void> activateOfflineSession(String localUserId) =>
      LocalStorage.setToken('offline:$localUserId');

  @override
  Future<void> linkHandoffAccount(
    String localUserId, {
    required String? backendUserId,
  }) async {
    linked.add('$localUserId=$backendUserId');
  }
}

class _ManagerPolicy extends DeclaredSessionPolicy {
  const _ManagerPolicy()
      : super(
          roleLandings: const {'seller': '/main'},
          appRole: 'seller',
          allowOfflineAccounts: true,
        );
}

final DateTime now = DateTime.utc(2026, 5, 1, 9);

Map<String, dynamic> localRecord({String? role, bool synced = false}) =>
    HandoffAccountRecord(
      issuedAt: now,
      localId: '1714550400000000',
      backendUserId: synced ? 'seller@example.invalid' : null,
      synced: synced,
      firstName: 'Fixture',
      lastName: 'Person',
      email: 'fixture@example.invalid',
      role: role,
    ).toJson();

LoginResponse loginAs(String role) => LoginResponse.fromJson({
      'message': 'Logged In',
      'data': {
        'access_token': 'key:secret',
        'refresh_token': 'refresh',
        'expires_at': '2026-05-02 09:00:00',
        'token_type': 'Bearer',
        'user': {
          'id': 'seller@example.invalid',
          'email': 'fixture@example.invalid',
          'firstname': 'Fixture',
          'role': role,
        },
      },
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Repo repo;
  late _Offline offline;
  late bool online;
  late SessionHandoffService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    SecureStorage.store = MemorySecureStore();
    AuthSessionPolicy.I = const AuthSessionPolicy();
    repo = _Repo();
    offline = _Offline();
    online = true;
    service = SessionHandoffService(
      repository: () => repo,
      offlineAuth: offline,
      isOnline: () async => online,
      ownPackage: () async => 'com.example.manager',
      clock: () => now,
    );
  });

  tearDown(() => AuthSessionPolicy.I = const AuthSessionPolicy());

  test('AuthRepository exposes the SessionHandoffExchange capability', () {
    expect(AuthRepository(), isA<SessionHandoffExchange>());
  });

  group('the record', () {
    test('never carries a password, vault entry or token', () {
      final json = localRecord(role: 'seller', synced: true);
      final text = json.toString().toLowerCase();
      for (final banned in ['password', 'token', 'secret', 'hash', 'vault']) {
        expect(text, isNot(contains(banned)));
      }
    });

    test('round-trips', () {
      final record = HandoffAccountRecord.fromJson(
        localRecord(role: 'seller', synced: true),
        now: now,
      )!;
      expect(record.role, 'seller');
      expect(record.synced, isTrue);
      expect(record.email, 'fixture@example.invalid');
    });

    test('a stale, future or empty record is refused', () {
      expect(
        HandoffAccountRecord.fromJson(localRecord(),
            now: now.add(const Duration(minutes: 6))),
        isNull,
      );
      expect(
        HandoffAccountRecord.fromJson(localRecord(),
            now: now.subtract(const Duration(minutes: 2))),
        isNull,
      );
      expect(HandoffAccountRecord.fromJson({'v': 1}, now: now), isNull);
      expect(HandoffAccountRecord.fromJson({'v': 2}, now: now), isNull);
    });
  });

  group('who the policy lets in offline', () {
    HandoffAccountRecord rec({String? role, bool synced = false}) =>
        HandoffAccountRecord.fromJson(localRecord(role: role, synced: synced),
            now: now)!;

    test('the manager admits a synced seller', () {
      expect(handoffRecordAdmitted(const _ManagerPolicy(),
          rec(role: 'seller', synced: true)), isTrue);
    });

    test('the manager turns away a synced plain user', () {
      expect(handoffRecordAdmitted(const _ManagerPolicy(),
          rec(role: 'user', synced: true)), isFalse);
    });

    test('the manager turns away a local-only account (not a seller)', () {
      expect(handoffRecordAdmitted(const _ManagerPolicy(), rec()), isFalse);
    });

    test('an app with the default policy admits a local-only account', () {
      expect(handoffRecordAdmitted(const AuthSessionPolicy(), rec()), isTrue);
    });
  });

  group('sending', () {
    test('signed out: nothing to hand over', () async {
      expect(await service.buildPayload('com.example.manager'), isNull);
    });

    test('backend session, backend up: a code for that app plus the record',
        () async {
      await LocalStorage.setToken('key:secret');
      await LocalStorage.setUser(ProfileData(
        id: 'seller@example.invalid',
        email: 'fixture@example.invalid',
        role: 'seller',
      ));
      repo.mintAnswer = 'one-time';
      final payload = await service.buildPayload('com.example.manager');
      expect(payload!.code, 'one-time');
      expect(repo.mintedFor, ['com.example.manager']);
      expect(payload.account!['role'], 'seller');
      expect(payload.account!['synced'], isTrue);
    });

    test('backend unreachable: the record alone, no mint attempted', () async {
      online = false;
      await LocalStorage.setToken('key:secret');
      await LocalStorage.setUser(ProfileData(
        id: 'seller@example.invalid',
        email: 'fixture@example.invalid',
      ));
      final payload = await service.buildPayload('com.example.manager');
      expect(payload!.code, isNull);
      expect(payload.account, isNotNull);
      expect(repo.mintedFor, isEmpty);
    });

    test('local-only account: its record, never a mint', () async {
      offline.rows['42'] = OfflineUserEntity(
        id: '42',
        email: 'fixture@example.invalid',
        passwordHash: 'local-hash',
        synced: false,
        createdAt: DateTime(2026),
      );
      await LocalStorage.setToken('offline:42');
      final payload = await service.buildPayload('com.example.manager');
      expect(payload!.code, isNull);
      expect(payload.account!['local_id'], '42');
      expect(payload.account!['synced'], isFalse);
      expect(payload.account.toString(), isNot(contains('local-hash')));
      expect(repo.mintedFor, isEmpty);
    });
  });

  group('receiving', () {
    test('a code signs this app in with its own session', () async {
      repo.redeemAnswer = ApiResult.success(data: loginAs('seller'));
      AuthSessionPolicy.I = const _ManagerPolicy();
      final outcome = await service.accept(
          const SessionHandoffPayload(code: 'one-time'));
      expect(outcome.kind, HandoffOutcomeKind.online);
      expect(repo.redeemedBy, ['com.example.manager']);
      expect(LocalStorage.getToken(), 'key:secret');
      expect(await SecureStorage.getRefreshToken(), 'refresh');
    });

    test('the manager still admits sellers only', () async {
      repo.redeemAnswer = ApiResult.success(data: loginAs('user'));
      AuthSessionPolicy.I = const _ManagerPolicy();
      final outcome = await service.accept(
          const SessionHandoffPayload(code: 'one-time'));
      expect(outcome.kind, HandoffOutcomeKind.rejected);
      expect(LocalStorage.getToken(), isEmpty);
    });

    test('a backend session this app holds is never replaced', () async {
      await LocalStorage.setToken('mine:secret');
      repo.redeemAnswer = ApiResult.success(data: loginAs('seller'));
      final outcome = await service.accept(
          const SessionHandoffPayload(code: 'one-time'));
      expect(outcome.kind, HandoffOutcomeKind.ignored);
      expect(LocalStorage.getToken(), 'mine:secret');
      expect(repo.redeemedBy, isEmpty);
    });

    test('backend unreachable: the record signs in offline', () async {
      repo.redeemAnswer = const ApiResult.failure(
          error: kCouldNotReachServerLine, statusCode: 0);
      final outcome = await service.accept(SessionHandoffPayload(
        code: 'one-time',
        account: localRecord(),
        sourcePackage: 'com.example.launcher',
      ));
      expect(outcome.kind, HandoffOutcomeKind.offline);
      expect(LocalStorage.getToken(),
          startsWith('offline:${OfflineAuthService.handoffIdPrefix}'));
      expect(LocalStorage.getUser()?.email, 'fixture@example.invalid');
    });

    test('a code the backend refused does not fall back to offline', () async {
      repo.redeemAnswer = const ApiResult.failure(
          error: 'This sign-in link has expired.', statusCode: 401);
      final outcome = await service.accept(SessionHandoffPayload(
        code: 'one-time',
        account: localRecord(),
      ));
      expect(outcome.kind, HandoffOutcomeKind.ignored);
      expect(LocalStorage.getToken(), isEmpty);
    });

    test('a local-only launcher account cannot enter the manager offline',
        () async {
      AuthSessionPolicy.I = const _ManagerPolicy();
      final outcome = await service.accept(
          SessionHandoffPayload(account: localRecord()));
      expect(outcome.kind, HandoffOutcomeKind.rejected);
      expect(LocalStorage.getToken(), isEmpty);
    });

    test('a later code upgrades the offline copy and links it', () async {
      await service.accept(SessionHandoffPayload(
        account: localRecord(role: 'seller', synced: true),
        sourcePackage: 'com.example.launcher',
      ));
      final copyToken = LocalStorage.getToken();
      expect(OfflineAuthService.isHandoffMirrorToken(copyToken), isTrue);

      repo.redeemAnswer = ApiResult.success(data: loginAs('seller'));
      final outcome = await service.accept(
          const SessionHandoffPayload(code: 'one-time'));
      expect(outcome.kind, HandoffOutcomeKind.online);
      expect(LocalStorage.getToken(), 'key:secret');
      expect(offline.linked.single, endsWith('=seller@example.invalid'));
    });
  });

  test('a handoff copy is never pushed to the backend by syncOne', () async {
    final row = OfflineUserEntity(
      id: '${OfflineAuthService.handoffIdPrefix}com.example.launcher:42',
      email: 'fixture@example.invalid',
      passwordHash: 'random',
      synced: false,
      createdAt: DateTime(2026),
    );
    final outcome = await OfflineAuthService().syncOne(row, repo);
    expect(outcome.success, isFalse);
    expect(outcome.statusCode, 409);
  });
}
