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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/domain/interface/auth.dart';
// Brings ApiResult's freezed-v3 pattern-match extension (`when`) into
// scope — since base_sdk's freezed 3 migration it is an extension on the
// sealed class, not a mixin method, so it must be imported explicitly.
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import '../../domain/interface/session_password_rotation.dart';
import '../../services/secure_password.dart';
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

/// Outcome of one backend sync attempt for a local account. Unlike a bare
/// bool this keeps the failure's HTTP status, which is what lets the sync
/// handler tell a retryable outage (5xx/timeout) from a definitive backend
/// rejection (4xx, e.g. phone already registered).
class OfflineSyncOutcome {
  final bool success;
  final String? backendUserId;
  final String? error;
  final int? statusCode;

  const OfflineSyncOutcome._(
    this.success,
    this.backendUserId,
    this.error,
    this.statusCode,
  );

  factory OfflineSyncOutcome.ok(String? backendUserId) =>
      OfflineSyncOutcome._(true, backendUserId, null, null);
  factory OfflineSyncOutcome.fail(String error, int? statusCode) =>
      OfflineSyncOutcome._(false, null, error, statusCode);
}

/// Offline registration/login: write the account locally first (so a
/// student with no signal isn't blocked from using the app at all), then
/// sync it to the real backend whenever connectivity returns. OTP/phone
/// verification happens AFTER the sync succeeds, never before — an offline
/// account is real and usable the moment it's created.
class OfflineAuthService {
  AppDatabase get _db => AppDatabase();

  /// KeyValueTable box for auth-owned flags (no schema migration needed).
  static const String authFlagsBox = 'auth_flags';

  /// Key under [authFlagsBox]: set when a deferred-registration account has
  /// synced to the backend but the user has not completed OTP verification
  /// yet. PendingOtpGate (installed into the composed app's main() via
  /// auth_sdk's manifest boot_hooks entry) reads this and routes the active
  /// user into the existing OTP confirmation sheet; the backend treats the
  /// account as limited until OTP completes.
  static const String pendingOtpKey = 'pending_otp_verification';

  /// Key under [authFlagsBox]: map of localUserId -> ISO timestamp for
  /// synced offline accounts whose backend password still needs a forced
  /// rotation (see [onDeferredVerificationCompleted]). Entries are only
  /// removed when the rotation call succeeds, so a failed attempt is
  /// retried on the next boot/resume/verify trigger — never blocking
  /// login or verification.
  static const String pendingPasswordRotationKey =
      'pending_password_rotations';

  /// Random backend password for each row's sync push, generated ONCE per
  /// row per app run and held in memory until the sync succeeds. A retry
  /// after an ambiguous network failure therefore re-sends the SAME
  /// password: whether the server replays a stored idempotent response or
  /// rejects the duplicate registration outright, the account never ends
  /// up with a password the client can't reason about mid-lifecycle. The
  /// map is deliberately not persisted — after sync the account is
  /// accessed via OTP verification (which mints the session token), and
  /// password login remains recoverable through the forgot-password flow.
  static final Map<String, String> _syncPasswords = {};

  /// Invoked right after [syncOne] records [pendingOtpKey], so the UX layer
  /// can react to a sync that completes mid-session instead of waiting for
  /// the next boot/resume. PendingOtpGate.install() assigns this; kept as a
  /// bare callback (not an import of the gate) so this infrastructure
  /// service stays presentation-free.
  static void Function()? onPendingOtpFlagged;

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
      if (existing.synced) {
        return OfflineAuthResult.fail(
            'An offline account already exists for this phone/email on this device.');
      }
      // Unsynced row: a pending local-first registration for this
      // identifier (a previous Register press while the backend was
      // unreachable). Failing here dead-ends every retry — the caller's
      // offline fallback is skipped and the user loops on an error toast
      // (driver Windows, backend down). Resume the row instead: refresh
      // its details with the freshly submitted form values and hand back
      // the SAME row id, so the sync push keeps its idempotency key and a
      // later online retry still dedupes.
      await (_db.update(_db.offlineUsersTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(OfflineUsersTableCompanion(
        phone: Value(phone),
        email: Value(email),
        firstName: Value(firstName),
        lastName: Value(lastName),
        passwordHash: Value(_hash(password)),
        referral: Value(referral),
      ));
      final current = LocalStorage.getToken();
      if (current.isEmpty || isOfflineToken(current)) {
        await LocalStorage.setToken(_offlineToken(existing.id));
      }
      return OfflineAuthResult.ok(existing.id);
    }

    // Local-only row identifier. Predictable (epoch-derived) and therefore
    // NEVER usable as a credential — the sync push sends a random secret
    // instead (see [syncOne]); this id only keys the row on this device.
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
    // Never clobber a real backend session (e.g. registerWithPhone runs
    // after phone-OTP verification already stored a real token); only
    // activate the offline session when there is no better one.
    final current = LocalStorage.getToken();
    if (current.isEmpty || isOfflineToken(current)) {
      await LocalStorage.setToken(_offlineToken(id));
    }
    return OfflineAuthResult.ok(id);
  }

  /// Stable idempotency key for registering the local account
  /// [localUserId] with the backend, sent as `X-Idempotency-Key` so the
  /// @idempotent `register_user` endpoint replays instead of
  /// double-registering on a retried upload. The same key is used by the
  /// inline online register path and the sync path (both act on the same
  /// local row), so a retry through either flow dedupes. The identifier is
  /// mixed in because [registerOffline]'s row ids are epoch-derived, not
  /// UUIDs, and registration runs as Guest server-side — the key must not
  /// collide across devices. Well under the backend's 140-char key cap.
  static String registrationIdempotencyKey(
    String localUserId, {
    String? email,
    String? phone,
  }) {
    final identifier = (email?.isNotEmpty ?? false) ? email : phone;
    return 'auth.register:$localUserId:${identifier ?? ''}';
  }

  /// The local account row for [localUserId], or null when absent.
  Future<OfflineUserEntity?> findById(String localUserId) {
    final query = _db.select(_db.offlineUsersTable)
      ..where((t) => t.id.equals(localUserId));
    return query.getSingleOrNull();
  }

  /// Reconcile a local-first row with a registration that succeeded inline
  /// (the online path of the register flow): the backend account exists, so
  /// the row is done and the sync path must not push it again.
  Future<void> markSynced(
    String localUserId, {
    String? backendUserId,
    String? backendToken,
  }) async {
    await (_db.update(_db.offlineUsersTable)
          ..where((t) => t.id.equals(localUserId)))
        .write(OfflineUsersTableCompanion(
      synced: const Value(true),
      backendUserId: Value(backendUserId),
      backendToken: Value(backendToken),
    ));
  }

  /// Roll back a local-first registration the backend definitively rejected
  /// (4xx), so a corrected retry isn't blocked by "an offline account
  /// already exists". Clears the active session only when it is this row's
  /// own offline token.
  Future<void> discardLocal(String localUserId) async {
    await (_db.delete(_db.offlineUsersTable)
          ..where((t) => t.id.equals(localUserId)))
        .go();
    if (LocalStorage.getToken() == _offlineToken(localUserId)) {
      await LocalStorage.setToken('');
    }
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
  Future<OfflineSyncOutcome> syncOne(
    OfflineUserEntity row,
    AuthRepositoryFacade authRepository, {
    bool activateOnSuccess = true,
  }) async {
    // The backend gets a freshly-generated cryptographically random
    // password (256 bits via Random.secure, see generateSecurePassword) —
    // NOT the local row id (predictable) and not the local hash (which
    // can't be reversed and shouldn't be sent anywhere). It becomes the
    // account's durable login password server-side, so it must be
    // unguessable; the client then discards it on sync success — real
    // credential verification is the OTP step that follows sync, and
    // password login stays recoverable via the forgot-password flow.
    // Held in [_syncPasswords] until success so a retried push re-sends
    // the same value (see the field comment for why).
    final syncPassword =
        _syncPasswords.putIfAbsent(row.id, generateSecurePassword);
    final response = await authRepository.sigUpWithData(
      user: UserModel(
        email: row.email,
        firstname: row.firstName,
        lastname: row.lastName,
        phone: row.phone,
        password: syncPassword,
        confirmPassword: syncPassword,
        referral: row.referral,
      ),
      // Stable per local row, so a re-push after an ambiguous failure
      // replays the stored backend response instead of double-registering.
      idempotencyKey: registrationIdempotencyKey(
        row.id,
        email: row.email,
        phone: row.phone,
      ),
    );
    return response.when<Future<OfflineSyncOutcome>>(
      success: (data) async {
        // The random password did its job (the account exists); discard it.
        _syncPasswords.remove(row.id);
        final backendUserId = data.user?.id?.toString();
        await (_db.update(_db.offlineUsersTable)
              ..where((t) => t.id.equals(row.id)))
            .write(OfflineUsersTableCompanion(
          synced: const Value(true),
          backendUserId: Value(backendUserId),
          backendToken: Value(data.token),
        ));
        if (activateOnSuccess &&
            isOfflineToken(LocalStorage.getToken()) &&
            LocalStorage.getToken() == _offlineToken(row.id)) {
          await LocalStorage.setToken(data.token);
        }
        // Ray's deferred-OTP flow: the account is now synced but NOT
        // verified — the backend limits it until OTP completes. Flag it so
        // the app can route the user into the OTP flow when next active.
        // Sync runs with no BuildContext, so this only records the flag and
        // pokes [onPendingOtpFlagged]; PendingOtpGate (wired in by the
        // manifest boot_hooks entry) does the actual routing into the OTP
        // confirmation sheet (sendOtp + verifyPhone / verifyEmail).
        await _db.putItem(authFlagsBox, pendingOtpKey, {
          'localUserId': row.id,
          'backendUserId': backendUserId,
          'phone': row.phone,
          'email': row.email,
          'syncedAt': DateTime.now().toIso8601String(),
        });
        onPendingOtpFlagged?.call();
        return OfflineSyncOutcome.ok(backendUserId);
      },
      failure: (failure, status) async {
        // Left unsynced. The caller (AuthSyncHandler) classifies: 5xx and
        // timeouts retry with backoff; a real conflict (e.g. phone already
        // registered on the backend by another device) parks the op for a
        // human decision instead of a silent retry loop.
        return OfflineSyncOutcome.fail(failure.toString(), status);
      },
    );
  }

  /// The deferred-OTP flag written when a background sync succeeds, or null
  /// when no verification is pending. Map keys: localUserId, backendUserId,
  /// phone, email, syncedAt.
  Future<Map<String, dynamic>?> pendingOtpVerification() =>
      _db.getItem(authFlagsBox, pendingOtpKey);

  /// Clear the deferred-OTP flag once the user completes verification.
  Future<void> clearPendingOtpVerification() =>
      _db.deleteItem(authFlagsBox, pendingOtpKey);

  /// Called by the confirmation notifier when a deferred (offline-
  /// registered, background-synced) account completes OTP verification and
  /// receives its first real session token. Two jobs:
  ///
  ///  1. refresh the local row with the verified session's token/id (the
  ///     verify endpoints re-mint api_key/api_secret, so any token the
  ///     sync recorded is stale from here on) — this is also what lets
  ///     [retryPendingPasswordRotations] match the row to the active
  ///     session later;
  ///  2. flag the account for forced password rotation and attempt it
  ///     immediately. Accounts synced by OLD app versions were registered
  ///     with a guessable backend password (the epoch-derived row id);
  ///     rotating to a fresh random secret here kills that credential.
  ///     For accounts synced by current code the password is already
  ///     random-and-discarded, so the extra rotation is harmless
  ///     defense-in-depth — cheaper than trying to tell the two apart.
  ///
  /// Never throws: rotation is strictly best-effort. On failure the
  /// pending flag survives and [retryPendingPasswordRotations] retries on
  /// a later trigger; verification/login are never blocked.
  Future<void> onDeferredVerificationCompleted({
    required String localUserId,
    String? backendUserId,
    String? freshToken,
    required AuthRepositoryFacade authRepository,
  }) async {
    try {
      if (localUserId.isEmpty) return;
      final row = await findById(localUserId);
      if (row == null) return;
      await markSynced(
        localUserId,
        backendUserId: backendUserId ?? row.backendUserId,
        backendToken: (freshToken != null && freshToken.isNotEmpty)
            ? freshToken
            : row.backendToken,
      );
      await _addPendingRotation(localUserId);
      await retryPendingPasswordRotations(authRepository);
    } catch (_) {
      // Best-effort by contract; a persisted pending flag (or none, if we
      // failed before writing it) is retried/recreated on later triggers.
    }
  }

  /// Best-effort forced credential rotation for every account still
  /// flagged under [pendingPasswordRotationKey]. Safe to call from any
  /// trigger (PendingOtpGate calls it post-frame on boot and app resume):
  ///
  ///  * requires [authRepository] to implement [SessionPasswordRotation]
  ///    (auth_sdk's own repositories do; a third-party facade that
  ///    doesn't simply leaves the flag set);
  ///  * only ever rotates the account whose OWN session is active — the
  ///    backend endpoint operates on the session user, so the row's
  ///    recorded backendToken must exactly match the live token (never
  ///    an `offline:` placeholder);
  ///  * the fresh random password is discarded on success (recovery is
  ///    the forgot-password flow); the flag is only cleared on success,
  ///    so failures retry on the next trigger and never block anything.
  Future<void> retryPendingPasswordRotations(
    AuthRepositoryFacade authRepository,
  ) async {
    if (authRepository is! SessionPasswordRotation) return;
    // Explicit cast: SessionPasswordRotation is unrelated to the facade
    // type, so the `is` check can't promote `authRepository`.
    final rotator = authRepository as SessionPasswordRotation;
    final pending = await _db.getItem(authFlagsBox, pendingPasswordRotationKey);
    if (pending == null || pending.isEmpty) return;
    final activeToken = LocalStorage.getToken();
    if (activeToken.isEmpty || isOfflineToken(activeToken)) return;
    for (final localUserId in pending.keys.toList()) {
      final row = await findById(localUserId);
      if (row == null) {
        // Row discarded; the flag can never be actioned, drop it.
        await _removePendingRotation(localUserId);
        continue;
      }
      final rowToken = row.backendToken ?? '';
      if (rowToken.isEmpty || rowToken != activeToken) {
        // Not this session's account (or the row has no verified token
        // yet); leave the flag for a later trigger.
        continue;
      }
      final newPassword = generateSecurePassword();
      final result = await rotator.updateSessionPassword(
        password: newPassword,
        passwordConfirmation: newPassword,
      );
      var rotated = false;
      result.when(
        success: (_) => rotated = true,
        failure: (_, __) => rotated = false,
      );
      if (rotated) {
        await _removePendingRotation(localUserId);
      }
      // newPassword goes out of scope here in both cases: discarded by
      // design (see class docs) — the account is used via its session
      // token, and password login is recoverable via forgot-password.
    }
  }

  Future<void> _addPendingRotation(String localUserId) async {
    final current =
        await _db.getItem(authFlagsBox, pendingPasswordRotationKey) ??
            <String, dynamic>{};
    current[localUserId] = DateTime.now().toIso8601String();
    await _db.putItem(authFlagsBox, pendingPasswordRotationKey, current);
  }

  Future<void> _removePendingRotation(String localUserId) async {
    final current =
        await _db.getItem(authFlagsBox, pendingPasswordRotationKey);
    if (current == null) return;
    current.remove(localUserId);
    if (current.isEmpty) {
      await _db.deleteItem(authFlagsBox, pendingPasswordRotationKey);
    } else {
      await _db.putItem(authFlagsBox, pendingPasswordRotationKey, current);
    }
  }
}
