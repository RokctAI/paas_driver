library auth_sdk;

// Import concrete files via package:auth_sdk/src/common/...
export 'src/common/di/auth_di.dart';
// Referenced by the composed app's generated main() via this SDK's
// manifest boot_hooks entry (PendingOtpGate.install();) — main.dart already
// imports package:auth_sdk/auth_sdk.dart for AuthSdkDependencies, so the
// hook needs no wiring import of its own.
export 'src/common/presentation/services/pending_otp_gate.dart';
