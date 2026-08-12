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
    // Never clobber a real backend session (e.g. registerWithPhone runs
    // after phone-OTP verification already stored a real token); only
    // activate the offline session when there is no better one.
    final current = LocalStorage.getToken();
    if (current.isEmpty || isOfflineToken(current)) {
      await LocalStorage.setToken(_offlineToken(id));
    }
    return OfflineAuthResult.ok(id);
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
    return response.when<Future<OfflineSyncOutcome>>(
      success: (data) async {
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
}
