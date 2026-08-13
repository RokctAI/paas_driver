import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
