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

// FRAME 49d of design strip section 49 — the "TODAY · SHIFT ENDED 17:04"
// stamp on the day strip (chip 931) when the driver is off duty.
//
// THE FRAME FLAGGED THE TIME AS NOT SOURCED, and it was right: nothing
// in the driver path recorded when duty was toggled — `setOnline` flips
// a boolean on the server and in CourierStorage and stored no timestamp.
// The frame's own remedy was "either a client-side local timestamp or a
// server field". This is the client-side one: the moment the driver
// toggles OFF duty the phone notes the time (CourierStorage), and the
// strip reads it back. Nothing is invented — a shift that ended on this
// phone is stamped with the minute it ended on this phone.
//
// WHAT THE STAMP WILL NOT DO. It never guesses. No timestamp (the app
// was installed while already off duty, or storage was cleared) means
// the strip says TODAY and nothing more. A timestamp from an EARLIER day
// is not today's shift, so it is ignored rather than shown as if the
// shift had just ended: the strip's figures are today's, and the stamp
// must be too. Going on duty clears it, so a driver who works and stops
// twice in one day sees the SECOND end, never the first.
//
// A server field (a duty-toggle timestamp beside the boolean) would make
// this stamp survive a reinstall and agree across devices; wire it and
// the reading here is where it lands.

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:intl/intl.dart';

/// Whether [endedAt] belongs to the calendar day of [now].
bool shiftEndedToday(DateTime? endedAt, DateTime now) =>
    endedAt != null &&
    endedAt.year == now.year &&
    endedAt.month == now.month &&
    endedAt.day == now.day;

/// The day strip's heading, exactly as frame 49d draws it.
///
/// Pure: the caller hands over the already-translated words so this can
/// be pinned in a test without a translation table. Returns [today]
/// upper-cased when there is nothing to stamp, and
/// `TODAY · SHIFT ENDED 17:04` when the shift ended on [now]'s day.
String shiftStampHeading({
  required String today,
  required String shiftEnded,
  required DateTime? endedAt,
  required DateTime now,
}) {
  final head = today.toUpperCase();
  if (!shiftEndedToday(endedAt, now)) return head;
  // 24-hour clock, as drawn; a driver's day is told in the time the
  // dispatch board uses, not in am/pm.
  final clock = DateFormat('HH:mm').format(endedAt!);
  return '$head · ${shiftEnded.toUpperCase()} $clock';
}

/// [shiftStampHeading] with the fleet's translations filled in — what the
/// home sheet passes to `DriverDayStrip.heading` while off duty.
String driverShiftStampHeading(DateTime? endedAt, {DateTime? now}) =>
    shiftStampHeading(
      today: AppHelpers.getTranslation(TrKeys.today),
      shiftEnded: AppHelpers.getTranslation(TrKeys.shiftEnded),
      endedAt: endedAt,
      now: now ?? DateTime.now(),
    );
