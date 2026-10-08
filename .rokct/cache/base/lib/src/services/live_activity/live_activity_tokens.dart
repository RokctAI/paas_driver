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

import 'dart:ui' show Color;

/// Colour tokens for live activities (design section 6c). Device surfaces
/// use these literal values, not the app theme.
class LiveActivityTokens {
  LiveActivityTokens._();

  /// `live.segment.done`: passed and active segments, points.
  static const Color segmentDone = Color(0xFFFF6600);

  /// `live.segment.todo`: segments not reached yet.
  static const Color segmentTodoLight = Color(0xFFE4E4E9);
  static const Color segmentTodoDark = Color(0xFF4A4B52);

  /// `live.tracker`: the disc behind the white tracker glyph.
  static const Color tracker = Color(0xFFFF6600);
  static const Color trackerGlyph = Color(0xFFFFFFFF);

  /// `live.time`: end time and countdown text (#B34700 keeps 4.5:1 on
  /// white).
  static const Color timeLight = Color(0xFFB34700);
  static const Color timeDark = Color(0xFFFF8A3D);

  /// `live.ended`: delivered, class started.
  static const Color ended = Color(0xFF0E9F6E);

  /// `live.error`: cancelled, failed.
  static const Color error = Color(0xFFFF3D00);

  static Color segmentTodo({required bool dark}) =>
      dark ? segmentTodoDark : segmentTodoLight;

  static Color time({required bool dark}) => dark ? timeDark : timeLight;
}
