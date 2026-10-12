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

// The restore-credential boot hook runs in main() BEFORE LocalStorage.init(),
// where every token read answers ''. It must not decide signed-in versus
// signed-out until the first frame, which main() only reaches after init.

import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/storage_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:auth_sdk/src/common/presentation/services/restore_credential_gate.dart';
import 'package:auth_sdk/src/common/services/restore_credential_service.dart';

class _RecordingService extends RestoreCredentialService {
  int restores = 0;
  int ensures = 0;

  @override
  Future<bool> attemptRestore({UserRepositoryFacade? userRepository}) async {
    restores++;
    return false;
  }

  @override
  Future<bool> ensureRestoreKey({bool force = false}) async {
    ensures++;
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'a signed-in launch is read as signed in, though the hook ran before '
      'LocalStorage was up', (WidgetTester tester) async {
    RestoreCredentialGate.resetForTest();
    final _RecordingService service = _RecordingService();
    RestoreCredentialGate.service = service;

    // main(): the boot hook first ...
    RestoreCredentialGate.install();
    expect(service.restores + service.ensures, 0,
        reason: 'nothing may run before LocalStorage is initialized');

    // ... then LocalStorage.init() on a device with a session ...
    SharedPreferences.setMockInitialValues(<String, Object>{
      StorageKeys.keyToken: 'session-token',
    });
    await LocalStorage.init();

    // ... then runApp and its first frame.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(service.ensures, 1);
    expect(service.restores, 0,
        reason: 'a signed-in user must not go down the restore path');
    RestoreCredentialGate.resetForTest();
  });
}
