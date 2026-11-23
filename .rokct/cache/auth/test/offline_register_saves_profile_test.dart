// Ray, 2026-11-21: "If I register a user offline and I go to profile that
// data is not there can't even be edited" (every Dart app). The offline
// auth service compiles only inside a composed app (its table is merged
// into AppDatabase there), so this pins the wiring in its source.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String src = File(
          'lib/src/common/infrastructure/services/offline_auth_service.dart')
      .readAsStringSync();

  String body(String signature) {
    final int start = src.indexOf(signature);
    expect(start, isNonNegative, reason: '$signature is missing');
    final int next = src.indexOf('\n  Future<', start + signature.length);
    return src.substring(start, next < 0 ? src.length : next);
  }

  test('registering offline saves the profile the app shows', () {
    final String register = body('Future<OfflineAuthResult> registerOffline(');
    // Both the new-row path and the resumed-row path.
    expect('_saveLocalProfile('.allMatches(register).length, 2);
  });

  test('signing in offline saves the profile the app shows', () {
    expect(body('Future<OfflineAuthResult> loginOffline('),
        contains('_saveLocalProfile('));
  });

  test('the saved profile is only written for the signed-in local account',
      () {
    final String helper = body('static Future<void> _saveLocalProfile(');
    expect(helper, contains('LocalStorage.getToken() != _offlineToken('));
    expect(helper, contains('LocalStorage.setUser('));
  });

  test('names edited while local are the ones sent on sync', () {
    final String sync = body('Future<OfflineSyncOutcome> syncOne(');
    expect(sync, contains('_syncNames(row)'));
    expect(sync, contains('firstname: names.firstName'));
    expect(sync, contains('lastname: names.lastName'));
  });
}
