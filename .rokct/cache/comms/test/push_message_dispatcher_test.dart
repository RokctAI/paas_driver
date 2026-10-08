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

import 'package:base_sdk/base_sdk.dart' show PushMessages;
import 'package:comms_sdk/src/common/services/push_message_dispatcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a background message is queued and replayed once', () async {
    final pm = PushMessages();
    final seen = <Map<String, dynamic>>[];
    pm.register('order_status', seen.add);
    final d = PushMessageDispatcher(messages: pm);

    await PushMessageDispatcher.queueBackground(
        {'type': 'order_status', 'order_id': 'ORD-1', 'status': 'on_a_way'});
    await PushMessageDispatcher.queueBackground({'no_type': 'x'});
    await d.replayQueued();
    await d.replayQueued();

    expect(seen, [
      {'type': 'order_status', 'order_id': 'ORD-1', 'status': 'on_a_way'},
    ]);
  });

  test('the queue keeps the newest maxQueued', () async {
    for (var i = 0; i < PushMessageDispatcher.maxQueued + 5; i++) {
      await PushMessageDispatcher.queueBackground({'type': 't', 'i': '$i'});
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(PushMessageDispatcher.queueKey)!;
    expect(list.length, PushMessageDispatcher.maxQueued);
    expect(list.last, contains('"i":"24"'));
  });

  test('dispatch forwards foreground data', () async {
    final pm = PushMessages();
    final seen = <String?>[];
    pm.register('order_status', (d) => seen.add(d['order_id'] as String?));
    await PushMessageDispatcher(messages: pm)
        .dispatch({'type': 'order_status', 'order_id': 'A'});
    expect(seen, ['A']);
  });
}
