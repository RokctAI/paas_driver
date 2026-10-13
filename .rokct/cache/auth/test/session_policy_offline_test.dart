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

// The session policy's sign-up role and offline accounts (auth_sdk 1.x,
// "Becoming a seller or driver"): the manager app asks for seller and lets
// in an account signed up offline on the phone; the driver app lets in
// approved drivers only, never offline.

import 'package:auth_sdk/src/common/domain/interface/auth_session_policy.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRouter extends Fake implements StackRouter {
  final List<String> replaced = <String>[];

  @override
  Future<T?> replaceNamed<T extends Object?>(
    String path, {
    bool includePrefixMatches = false,
    OnNavigationFailure? onFailure,
  }) async {
    replaced.add(path);
    return null;
  }
}

/// Records rejections instead of touching storage and snackbars.
class _Recording extends DeclaredSessionPolicy {
  const _Recording({
    required super.roleLandings,
    super.appRole,
    this.onReject,
  });

  final VoidCallback? onReject;

  @override
  void onRejected(BuildContext context, {String? role}) => onReject?.call();
}

Widget _withRouter(StackRouter router, void Function(BuildContext) run) {
  return MaterialApp(
    home: StackRouterScope(
      controller: router,
      stateHash: 0,
      child: Builder(
        builder: (context) {
          run(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
}

void main() {
  const manager = DeclaredSessionPolicy(
    roleLandings: {'seller': '/main'},
    appRole: 'seller',
    allowOfflineAccounts: true,
  );
  const driver = DeclaredSessionPolicy(
    roleLandings: {'deliveryman': '/home'},
  );

  test('the default policy asks for no role and admits offline accounts', () {
    const policy = AuthSessionPolicy();
    expect(policy.signUpAppRole, isNull);
    expect(policy.allowsOfflineAccount(), isTrue);
  });

  test('manager: sign-up asks for seller; offline accounts are let in', () {
    expect(manager.signUpAppRole, 'seller');
    expect(manager.allowsOfflineAccount(), isTrue);
    // An online sign-in still needs the verified role.
    expect(manager.allows(null), isFalse);
    expect(manager.allows('user'), isFalse);
    expect(manager.allows('seller'), isTrue);
  });

  test('driver: no offline accounts, approved drivers only', () {
    expect(driver.signUpAppRole, isNull);
    expect(driver.allowsOfflineAccount(), isFalse);
    expect(driver.allows('user'), isFalse);
    expect(driver.allows('deliveryman'), isTrue);
  });

  test('the setting needs a landing for the app role', () {
    const misdeclared = DeclaredSessionPolicy(
      roleLandings: {'seller': '/main'},
      appRole: 'nobody',
      allowOfflineAccounts: true,
    );
    expect(misdeclared.allowsOfflineAccount(), isFalse);
  });

  testWidgets('after sign-up the manager lands its seller at /main',
      (tester) async {
    final router = _RecordingRouter();
    await tester.pumpWidget(_withRouter(router, (context) {
      const _Recording(
        roleLandings: {'seller': '/main'},
        appRole: 'seller',
      ).onSignedUp(context);
    }));
    expect(router.replaced, ['/main']);
  });

  testWidgets('after sign-up the driver app turns the new account away',
      (tester) async {
    final router = _RecordingRouter();
    var rejected = 0;
    await tester.pumpWidget(_withRouter(router, (context) {
      _Recording(
        roleLandings: const {'deliveryman': '/home'},
        onReject: () => rejected++,
      ).onSignedUp(context);
    }));
    expect(router.replaced, isEmpty);
    expect(rejected, 1);
  });

  test("a '*' fallback still admits offline sessions, as before", () {
    const fallback = DeclaredSessionPolicy(
      roleLandings: {'deliveryman': '/home', '*': '/become-driver'},
    );
    expect(fallback.allowsOfflineAccount(), isTrue);
  });
}
