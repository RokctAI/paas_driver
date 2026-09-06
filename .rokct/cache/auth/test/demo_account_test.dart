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

import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/constants/demo_images.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';

import 'package:auth_sdk/src/common/infrastructure/repositories/mock_auth_repository.dart';

const List<String> _fixtureWords = ['demo', 'example', 'placeholder', 'sample'];

Future<UserModel> _signIn(String email) async {
  final result = await MockAuthRepository().login(
    email: email,
    password: 'demo-learners-2026',
  );
  expect(result, isA<Success<LoginResponse>>());
  return (result as Success<LoginResponse>).data.data!.user!;
}

void main() {
  test('the sign-in address still decides the role', () async {
    expect((await _signIn('manager@demo.rokct.ai')).role, 'seller');
    expect((await _signIn('driver@demo.rokct.ai')).role, 'deliveryman');
    expect((await _signIn('partner@demo.rokct.ai')).role, 'partner');
    expect((await _signIn('admin@demo.rokct.ai')).role, 'admin');
    expect((await _signIn('demo.student@example.com')).role, 'customer');
  });

  test('login hands back the demo identity email, never the typed address',
      () async {
    // The typed address is a credential and a role selector; the account
    // it signs in - and the email every profile surface renders - is the
    // one demo identity, the same one users_sdk's MockUserRepository
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
    // The kernel-owned avatar, shared with users_sdk's MockUserRepository.
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
}
