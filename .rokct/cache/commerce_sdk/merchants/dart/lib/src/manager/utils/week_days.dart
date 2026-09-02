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

/// Weekday wire names in the order the working-days UI renders them.
/// Ported from paas_manager's `WeekDays` enum (`infrastructure/services/
/// enums.dart`); `WeekDays.values[DateTime.now().weekday - 1]` is today,
/// since Dart's `DateTime.weekday` is 1 (monday) .. 7 (sunday).
enum WeekDays { monday, tuesday, wednesday, thursday, friday, saturday, sunday }
