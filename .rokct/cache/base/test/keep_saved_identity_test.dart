import 'package:flutter_test/flutter_test.dart';
import 'package:base_sdk/src/application/profile/profile_notifier.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';

void main() {
  test('a thin server answer keeps the saved names and contacts', () {
    final saved = ProfileData(
        firstname: 'Ray', lastname: 'S', email: 'r@x.co', phone: '082');
    final fetched = ProfileData(firstname: '', email: 'new@x.co');
    final kept = keepSavedIdentity(fetched, saved)!;
    expect(kept.firstname, 'Ray');
    expect(kept.lastname, 'S');
    expect(kept.email, 'new@x.co');
    expect(kept.phone, '082');
  });

  test('nothing saved keeps the answer; no answer keeps the saved', () {
    final p = ProfileData(firstname: 'A');
    expect(keepSavedIdentity(p, null), same(p));
    expect(keepSavedIdentity(null, p), same(p));
  });
}
