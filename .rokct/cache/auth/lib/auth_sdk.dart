// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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

library auth_sdk;

// Import concrete files via package:auth_sdk/src/common/...
export 'src/common/di/auth_di.dart';
// Referenced by the composed app's generated main() via this SDK's
// manifest boot_hooks entry (PendingOtpGate.install();) — main.dart already
// imports package:auth_sdk/auth_sdk.dart for AuthSdkDependencies, so the
// hook needs no wiring import of its own.
export 'src/common/presentation/services/pending_otp_gate.dart';
// Registration capability flags a composing app's home SDK may flip (see
// AuthRegistrationConfig — e.g. lms_sdk enabling date-of-birth capture).
export 'src/common/services/registration_config.dart';
// Android Restore Credentials. The platform seam is exported so a composed
// app can install core's channel implementation into
// RestoreCredentialPlatform.instance at startup; the service is exported so
// the app shell can drive the launch-time retrieval and the sign-out clear.
export 'src/common/domain/interface/restore_credential_platform.dart';
export 'src/common/infrastructure/repositories/restore_credential_repository.dart';
export 'src/common/services/restore_credential_service.dart';
// The boot-hook driver named by the manifest's auth_restore_credential_gate
// entry; also the re-entry point the Android BackupAgent calls after a
// data restore, and the sign-out clear an app shell reaches for.
export 'src/common/presentation/services/restore_credential_gate.dart';
