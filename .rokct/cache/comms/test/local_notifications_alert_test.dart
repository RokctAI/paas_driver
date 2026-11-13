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


// Alerts slide down over the screen (heads-up) and use the app's own small
// icon from res/drawable, not the full-colour launcher icon.

import 'package:comms_sdk/comms_sdk.dart' show LocalNotifications;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alerts pop down with sound on their own channel', () {
    const d = LocalNotifications.alertDetails;
    expect(d.channelId, 'alerts');
    expect(d.importance, Importance.max);
    expect(d.priority, Priority.max);
    expect((d.playSound, d.enableVibration), (true, true));
  });

  test('the small icon is the shell notification_icon', () {
    expect(LocalNotifications.androidSmallIcon, '@drawable/notification_icon');
    expect(LocalNotifications.androidFallbackIcon, '@mipmap/ic_launcher');
  });

  test('a group stacks alerts under one silent heading', () {
    final m = LocalNotifications.groupedDetails('stick:nandi');
    final h = LocalNotifications.summaryDetails('stick:nandi');
    expect(m.groupKey, 'stick:nandi');
    expect(m.setAsGroupSummary, isNot(true));
    expect(h.groupKey, 'stick:nandi');
    expect(h.setAsGroupSummary, true);
    expect(LocalNotifications.summaryId('stick:nandi'),
        LocalNotifications.summaryId('stick:nandi'));
  });
}
