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


// RouteMemory keeps the page a person was on so a cold start (Android closed
// the app in the background) reopens it; start-up and sign-in pages never.

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/base_sdk.dart';
import 'package:base_sdk/src/services/secure_storage.dart' show SecureStore, SecureStorage;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    RouteMemory.reset();
  });

  test('start-up and sign-in pages are never kept', () {
    for (final u in ['/', '', '/no-connection', '/maintenance', '/login', '/auth/sign-up', '/otp?x=1', '/splash']) {
      expect(RouteMemory.skip(u), isTrue, reason: u);
    }
    for (final u in ['/sticks/inbox?for=b1', '/orders', '/chat', '/design', '/assignments', '/settings/signature']) {
      expect(RouteMemory.skip(u), isFalse, reason: u);
    }
  });

  test('a kept page is offered back only while it is recent', () async {
    final at = DateTime(2026, 11, 6, 21);
    await LocalStorage.setJson(RouteMemory.storageKey, {'url': '/sticks/inbox?for=b1', 'at': at.toIso8601String()});
    expect(RouteMemory.recent(now: at.add(const Duration(hours: 1))), '/sticks/inbox?for=b1');
    expect(RouteMemory.recent(now: at.add(const Duration(hours: 13))), isNull);
    await LocalStorage.setJson(RouteMemory.storageKey, {'url': '/login', 'at': at.toIso8601String()});
    expect(RouteMemory.recent(now: at), isNull);
  });

  test('signing out forgets the kept page', () async {
    SecureStorage.store = _MemorySecureStore();
    await LocalStorage.setJson(RouteMemory.storageKey, {'url': '/orders', 'at': DateTime.now().toIso8601String()});
    expect(RouteMemory.recent(), '/orders');
    LocalStorage.logout();
    await Future<void>.delayed(Duration.zero);
    expect(RouteMemory.recent(), isNull);
  });

  test('a page that needs data handed over in code is not reopened', () {
    final r = _TestRouter();
    expect(RouteMemory.rebuildable(r, '/plain'), isTrue);
    expect(RouteMemory.rebuildable(r, '/item/7'), isTrue);
    expect(RouteMemory.rebuildable(r, '/needs-args'), isFalse);
    expect(RouteMemory.rebuildable(r, '/nowhere'), isFalse);
  });
}

class _TestRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: '/plain', page: PageInfo('Plain', builder: (_) => const SizedBox())),
        AutoRoute(
          path: '/item/:id',
          page: PageInfo('Item', builder: (d) => Text(d.inheritedPathParams.getString('id'))),
        ),
        AutoRoute(
          path: '/needs-args',
          page: PageInfo('NeedsArgs', builder: (d) => Text(d.argsAs<String>())),
        ),
      ];
}

class _MemorySecureStore implements SecureStore {
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}
