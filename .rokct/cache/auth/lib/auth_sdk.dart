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
