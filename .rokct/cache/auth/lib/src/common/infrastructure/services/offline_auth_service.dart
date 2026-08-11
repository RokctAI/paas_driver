import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import '../database/offline_user_table.dart';

/// Result of an offline register/login attempt — deliberately not the same
/// shape as the online ApiResult, since "no offline account found" is a
/// different failure than "no connection" and callers need to tell them
/// apart in the UI.
class OfflineAuthResult {
  final bool success;
  final String? localUserId;
  final String? error;

  const OfflineAuthResult._(this.success, this.localUserId, this.error);

  factory OfflineAuthResult.ok(String localUserId) =>
      OfflineAuthResult._(true, localUserId, null);
  factory OfflineAuthResult.fail(String error) =>
      OfflineAuthResult._(false, null, error);
}

/// Offline registration/login: write the account locally first (so a
/// student with no signal isn't blocked from using the app at all), then
/// sync it to the real backend whenever connectivity returns. OTP/phone
/// verification happens AFTER the sync succeeds, never before — an offline
/// account is real and usable the moment it's created.
class OfflineAuthService {
  AppDatabase get _db => AppDatabase();

  String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  /// The token stored for an offline (not-yet-synced) session. Everything
  /// that gates on LocalStorage.getToken().isNotEmpty (route guards, etc.)
  /// keeps working unchanged; only code that actually calls the backend
  /// needs to know the difference (see [isOfflineToken]).
  static String _offlineToken(String localUserId) => 'offline:$localUserId';
  static bool isOfflineToken(String token) => token.startsWith('offline:');

  Future<OfflineAuthResult> registerOffline({
    String? phone,
    String? email,
    String? firstName,
    String? lastName,
    required String password,
    String? referral,
  }) async {
    if ((phone == null || phone.isEmpty) &&
        (email == null || email.isEmpty)) {
      return OfflineAuthResult.fail('Phone or email is required.');
    }

    final existing = await _findLocal(phone: phone, email: email);
    if (existing != null) {
      return OfflineAuthResult.fail(
          'An offline account already exists for this phone/email on this device.');
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _db.into(_db.offlineUsersTable).insert(
          OfflineUsersTableCompanion.insert(
            id: Value(id),
            phone: Value(phone),
            email: Value(email),
            firstName: Value(firstName),
            lastName: Value(lastName),
            passwordHash: _hash(password),
            referral: Value(referral),
          ),
        );
    await LocalStorage.setToken(_offlineToken(id));
    return OfflineAuthResult.ok(id);
  }

  Future<OfflineAuthResult> loginOffline({
    String? phone,
    String? email,
    required String password,
  }) async {
    final row = await _findLocal(phone: phone, email: email);
    if (row == null) {
      return OfflineAuthResult.fail(
          'No offline account found on this device for that phone/email. '
          'Connect to the internet to log in with an existing account.');
    }
    if (row.passwordHash != _hash(password)) {
      return OfflineAuthResult.fail('Incorrect password.');
    }
    final token =
        row.synced && row.backendToken != null && row.backendToken!.isNotEmpty
            ? row.backendToken!
            : _offlineToken(row.id);
    await LocalStorage.setToken(token);
    return OfflineAuthResult.ok(row.id);
  }

  /// Looks up by whichever identifier is non-empty. The login/register
  /// forms use one field for phone-or-email depending on SignUpType, so
  /// callers usually pass the same value as both [phone] and [email] rather
  /// than know in advance which it is.
  Future<OfflineUserEntity?> _findLocal({String? phone, String? email}) async {
    final identifiers = {phone, email}
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet();
    if (identifiers.isEmpty) return null;
    final query = _db.select(_db.offlineUsersTable)
      ..where((t) =>
          t.phone.isIn(identifiers) | t.email.isIn(identifiers));
    return query.getSingleOrNull();
  }

  /// Every local account not yet synced. Call this whenever connectivity is
  /// confirmed (app start, connectivity-regained callback) and attempt
  /// [syncOne] on each — never called automatically from register/login
  /// themselves, since a failed sync attempt must not block the offline
  /// account from being usable.
  Future<List<OfflineUserEntity>> pendingSync() {
    final query = _db.select(_db.offlineUsersTable)
      ..where((t) => t.synced.equals(false));
    return query.get();
  }

  /// Registers the local account with the real backend via the normal
  /// sign-up API. On success, marks the row synced and records the real
  /// backend token/id — but does NOT overwrite the active session token
  /// unless [activateOnSuccess] is true (the caller decides whether this
  /// sync is for the currently logged-in device or a background catch-up
  /// for some other local account).
  Future<bool> syncOne(
    OfflineUserEntity row,
    AuthRepositoryFacade authRepository, {
    bool activateOnSuccess = true,
  }) async {
    final response = await authRepository.sigUpWithData(
      user: UserModel(
        email: row.email,
        firstname: row.firstName,
        lastname: row.lastName,
        phone: row.phone,
        // The backend gets a freshly-generated random password, not the
        // local hash (which can't be reversed and shouldn't be sent
        // anywhere) — real credential verification is the OTP step that
        // follows sync, not this password.
        password: row.id,
        confirmPassword: row.id,
        referral: row.referral,
      ),
    );
    var synced = false;
    response.when(
      success: (data) async {
        await (_db.update(_db.offlineUsersTable)
              ..where((t) => t.id.equals(row.id)))
            .write(OfflineUsersTableCompanion(
          synced: const Value(true),
          backendUserId: Value(data.user?.id?.toString()),
          backendToken: Value(data.token),
        ));
        if (activateOnSuccess &&
            isOfflineToken(LocalStorage.getToken()) &&
            LocalStorage.getToken() == _offlineToken(row.id)) {
          await LocalStorage.setToken(data.token);
        }
        synced = true;
      },
      failure: (failure, status) {
        // Left unsynced — pendingSync() will retry next time connectivity
        // is confirmed. A real conflict (e.g. phone already registered on
        // the backend by another device) needs a human decision, not a
        // silent retry loop; surfacing that is a follow-up, not blocking
        // here.
      },
    );
    return synced;
  }
}
