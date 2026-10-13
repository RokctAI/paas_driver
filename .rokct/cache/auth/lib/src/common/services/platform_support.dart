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

import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/session_start_hooks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// Platform guards for the auth flows that lean on plugins without a
/// desktop implementation (google_sign_in, flutter_facebook_auth,
/// sign_in_with_apple's Firebase exchange, Firebase phone verification,
/// FirebaseMessaging). On Windows/Linux Firebase is (correctly) never
/// initialized, so an unguarded call throws [core/no-app] — or, for
/// verifyPhoneNumber, hangs a spinner before dying.

/// The platforms where the full mobile auth stack is available: Firebase
/// phone-OTP verification is Android/iOS only (firebase_auth's
/// verifyPhoneNumber has no desktop or web implementation).
bool get isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Android/iOS/web plus macOS: everywhere the Firebase plugin set
/// (firebase_core/auth/messaging) ships an implementation and the composed
/// apps initialize Firebase. Windows and Linux are excluded on both counts.
bool get isFirebaseSupportedPlatform =>
    kIsWeb || isMobilePlatform || defaultTargetPlatform == TargetPlatform.macOS;

/// Where the social sign-in plugin set works — the same platforms as
/// Firebase: google_sign_in ships a macOS implementation,
/// flutter_facebook_auth 7.x's darwin package covers macOS, and
/// sign_in_with_apple is macOS-native (the Apple button itself stays
/// iOS-gated in the pages, unchanged). Windows and Linux have no
/// implementation for any of them, so the buttons are hidden there instead
/// of throwing on tap.
bool get supportsSocialSignIn => isFirebaseSupportedPlatform;

/// TrKeys-style key for the fail-fast phone-OTP guard. Backend translations
/// can override it; AppHelpers.getTranslation's fallback renders it as
/// "Phone verification is not available on desktop".
const String trPhoneVerificationNotAvailableOnDesktop =
    'phone_verification_is_not_available_on_desktop';

/// Push the FirebaseMessaging token to the backend — the two-liner every
/// auth notifier used to inline. On platforms without a FirebaseMessaging
/// implementation or an initialized Firebase app (Windows, Linux) it
/// silently does nothing instead of throwing [core/no-app]; the try/catch
/// keeps any other messaging failure from breaking the auth flow it runs in.
Future<void> syncFcmToken(UserRepositoryFacade userRepository) async {
  if (!isFirebaseSupportedPlatform) return;
  try {
    final String? fcmToken = await FirebaseMessaging.instance.getToken();
    userRepository.updateFirebaseToken(fcmToken);
  } catch (e) {
    debugPrint('===> fcm token sync skipped: $e');
  }
}

/// Everything auth_sdk does once a session is established: fire base_sdk's
/// [SessionStartHooks] (for example comms_sdk's one-time notification
/// permission prompt), then push the FCM token.
///
/// The hooks are deliberately not awaited: an OS permission prompt waits
/// on the user, and the sign-in that fired it must never wait with it.
/// [SessionStartHooks.run] isolates and logs every hook failure itself.
Future<void> completeSessionStart(UserRepositoryFacade userRepository) async {
  unawaited(SessionStartHooks.run());
  await syncFcmToken(userRepository);
}

/// Social sign-in buttons that have a verified backend path. Facebook and
/// Apple sign-in both called `login_with_google` with Firebase user details,
/// which the backend refuses since 1.19.0 (it needs a verified Google ID
/// token). Their buttons stay hidden until each has a verified path of its
/// own; the code behind them is kept.
const bool appleAndFacebookSignInVerified = false;

/// Whether a backend session is active: a token the backend issued, not an
/// offline account's `offline:<id>` token, which no backend accepts.
bool get hasBackendSession {
  final String token = LocalStorage.getToken();
  return token.isNotEmpty && !token.startsWith('offline:');
}

/// Keeps the backend's copy of this device's FCM token current between
/// sign-ins. Before, the token was only sent at sign-in, so a token Firebase
/// rotated later (or a session restored at cold start) left the backend
/// pushing to a dead token.
///
/// Installed from auth_sdk's boot hook, which runs before LocalStorage and
/// DI are ready, so the work is deferred to the first frame: it re-sends
/// the token once if someone is already signed in, and from then on
/// re-sends every token FirebaseMessaging.onTokenRefresh hands out while
/// signed in. Fail-open like [syncFcmToken].
class FcmTokenSync {
  FcmTokenSync._();

  static StreamSubscription<String>? _subscription;
  static bool _scheduled = false;

  static UserRepositoryFacade? _repository() =>
      GetIt.instance.isRegistered<UserRepositoryFacade>()
          ? GetIt.instance<UserRepositoryFacade>()
          : null;

  static void install() {
    if (!isFirebaseSupportedPlatform || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => start());
  }

  /// The deferred half of [install]; [repository] and [tokenRefresh] are
  /// test seams.
  @visibleForTesting
  static Future<void> start({
    UserRepositoryFacade? Function()? repository,
    Stream<String>? tokenRefresh,
  }) async {
    final resolve = repository ?? _repository;
    try {
      _subscription ??= (tokenRefresh ?? FirebaseMessaging.instance.onTokenRefresh)
          .listen(
            (token) {
              if (!hasBackendSession) return;
              resolve()?.updateFirebaseToken(token);
            },
            onError: (Object e) {
              debugPrint('===> fcm token refresh stream error: $e');
            },
          );
    } catch (e) {
      debugPrint('===> fcm token refresh sync skipped: $e');
      return;
    }
    // Cold start with a session already in place: the sign-in that sent
    // the token may have been on an earlier install or token.
    if (hasBackendSession && tokenRefresh == null) {
      final repo = resolve();
      if (repo != null) await syncFcmToken(repo);
    }
  }

  @visibleForTesting
  static Future<void> reset() async {
    await _subscription?.cancel();
    _subscription = null;
    _scheduled = false;
  }
}
