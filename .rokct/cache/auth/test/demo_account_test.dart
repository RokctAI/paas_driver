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

// Three things about the demo sign-in must hold together: the ADDRESS still
// decides the role (each shell's tour signs in with its own account), the
// account it hands back reads like a real person - the old fixture wording
// (a Demo name, a placeholder-host avatar, a Demo St address) reached the
// published tour stills - and the typed address never becomes that
// account's email: once LoginNotifier persisted the login user (1.10.3),
// "demo.student@example.com" was the profile header's contact line in the
// supacharge tour still.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/constants/demo_images.dart';

import 'support/auth_demo_fixtures.dart';

const List<String> _fixtureWords = ['demo', 'example', 'placeholder', 'sample'];

/// The string literals a Dart source renders or compares, with every
/// `//` comment stripped first - the login screen documents the REMOVED
/// demo hint in a comment, and a comment never reaches a screen.
Iterable<String> _stringLiteralsOf(String source) sync* {
  final code = _withoutLineComments(source);
  final literal = RegExp(r"'(?:[^'\\]|\\.)*'" '|' r'"(?:[^"\\]|\\.)*"');
  for (final m in literal.allMatches(code)) {
    final quoted = m.group(0)!;
    yield quoted.substring(1, quoted.length - 1);
  }
}

String _withoutLineComments(String source) =>
    source.replaceAll(RegExp(r'//[^\n]*'), '');

const _signIn = signInDemo;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(startAuthDemoSession);
  tearDown(endAuthDemoSession);

  test('the sign-in address still decides the role', () async {
    expect((await _signIn('manager@demo.rokct.ai')).role, 'seller');
    expect((await _signIn('driver@demo.rokct.ai')).role, 'deliveryman');
    expect((await _signIn('partner@demo.rokct.ai')).role, 'partner');
    expect((await _signIn('admin@demo.rokct.ai')).role, 'admin');
    expect((await _signIn('customer@demo.rokct.ai')).role, 'customer');
    // Any other address signs in the student account.
    expect((await _signIn('student@demo.rokct.ai')).role, 'student');
    expect((await _signIn('demo.student@example.com')).role, 'student');
  });

  test('each demo role signs in to its own account, so its own owner scope',
      () async {
    // base_sdk scopes local data to the signed-in user's id; the student,
    // partner and admin demo accounts used to share Thandi's id "1" and so
    // read one merged data set (Ray, 2026-09-23).
    final student = await _signIn('customer@demo.rokct.ai');
    final partner = await _signIn('partner@demo.rokct.ai');
    final admin = await _signIn('admin@demo.rokct.ai');
    expect(student.id, '1');
    expect(student.firstname, 'Thandi');
    expect({student.id, partner.id, admin.id}, hasLength(3));
    expect(partner.firstname, isNot('Thandi'));
    expect(admin.firstname, isNot('Thandi'));
    expect(partner.isDemoAccount, isTrue);
    expect(admin.isDemoAccount, isTrue);
  });

  test('login hands back the demo identity email, never the typed address',
      () async {
    // The typed address is a credential and a role selector; the account
    // it signs in - and the email every profile surface renders - is the
    // one demo identity, the same one users_sdk's profile fixture
    // serves.
    expect(
      (await _signIn('demo.student@example.com')).email,
      'thandi.mokoena@outlook.com',
    );
    expect(
      (await _signIn('manager@demo.rokct.ai')).email,
      'thandi.mokoena@outlook.com',
    );
  });

  test(
      'no field of the signed-in account reads as fixture, whatever the '
      'tour typed', () async {
    // Every address a shell's tour signs in with: the {demo_email} default
    // (supacharge) and the role-mapped ones (paas_manager, driver, partner
    // and admin shells).
    const addresses = [
      'demo.student@example.com',
      'manager@demo.rokct.ai',
      'driver@demo.rokct.ai',
      'partner@demo.rokct.ai',
      'admin@demo.rokct.ai',
    ];
    for (final address in addresses) {
      final user = await _signIn(address);
      final rendered = [
        user.firstname,
        user.lastname,
        user.email,
        user.phone,
        user.role,
        user.img,
        user.addresses?.first.address?.address,
      ].join(' ').toLowerCase();
      for (final word in _fixtureWords) {
        expect(
          rendered,
          isNot(contains(word)),
          reason: '"$word" reads as fixture after signing in as $address',
        );
      }
    }
  });

  test('the demo account reads like a real person', () async {
    final user = await _signIn('manager@demo.rokct.ai');
    expect(user.firstname, 'Thandi');
    expect(user.lastname, 'Mokoena');
    expect(user.phone, '+27 82 456 7890');
    expect(user.img, startsWith('data:image/svg+xml'));
    // The kernel-owned avatar, shared with users_sdk's profile fixture.
    expect(user.img, DemoImages.avatar);
    expect(user.addresses?.first.address?.address, contains('Sandton'));

    final rendered = [
      user.firstname,
      user.lastname,
      user.phone,
      user.img,
      user.addresses?.first.address?.address,
    ].join(' ').toLowerCase();
    for (final word in _fixtureWords) {
      expect(
        rendered,
        isNot(contains(word)),
        reason: '"$word" reads as fixture',
      );
    }
  });

  // Demo login in production (Ray 2026-09-08): nothing on screen,
  // including the auth login screen, may show demo details or say demo -
  // the demo accounts are real accounts on the production backend and
  // the app only reacts to the backend's marker. The 2026-08-22 removal of
  // the isDemo-gated credentials hint must stay removed.
  test('the login screen renders no demo hint and no fixture wording', () {
    final source = File(
      'lib/src/common/presentation/pages/auth/login/login_screen.dart',
    ).readAsStringSync();
    final literals = _stringLiteralsOf(source).toList();
    expect(literals, isNotEmpty);
    for (final literal in literals) {
      for (final word in _fixtureWords) {
        expect(literal.toLowerCase(), isNot(contains(word)),
            reason: 'login screen literal "$literal" reads "$word"');
      }
    }
    final code = _withoutLineComments(source);
    expect(code, isNot(contains('demoUserLogin')));
    expect(code, isNot(contains('demoUserPassword')));
    expect(code, isNot(contains('isDemo')));
    expect(code, isNot(contains('DemoSession')));
  });

  // Demo accounts sign in through the REAL AuthRepository in every build,
  // the tour included (Ray, 2026-09-25: the tour must not use mock repos
  // either); the demo interceptor answers the tour's sign-in.
  test('no mock repository: demo sign-ins go through AuthRepository', () {
    final di = _withoutLineComments(
      File('lib/src/common/di/auth_di.dart').readAsStringSync(),
    );
    expect(di, contains('AuthRepository()'));
    expect(di, contains('DemoFixtures.registerAssetDirectory'));
    expect(di, isNot(contains('Mock')));
    expect(di, isNot(contains('isTour')));

    final notifier = _withoutLineComments(File(
      'lib/src/common/application/auth/login/login_notifier.dart',
    ).readAsStringSync());
    expect(notifier, isNot(contains('Mock')));
    expect(notifier, isNot(contains('demoUserLogin')));
    expect(notifier, isNot(contains('demoUserPassword')));
    expect(
      Directory('lib').listSync(recursive: true).whereType<File>().where(
          (f) => f.path.split('/').last.startsWith('mock_')),
      isEmpty,
    );
  });
}
