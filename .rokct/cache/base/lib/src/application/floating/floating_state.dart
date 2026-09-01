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


import 'package:freezed_annotation/freezed_annotation.dart';

part 'floating_state.freezed.dart';

/// Generic scroll-collapse state for floating chrome (the nav pill hides
/// while the content scrolls). Moved here from marketplace_sdk's
/// `floating_button/` — nothing marketplace-specific about it, and
/// [BottomNavigatorItem.shouldHide] reads exactly this signal.
@freezed
abstract class FloatingState with _$FloatingState {
  const factory FloatingState({@Default(false) bool isScrolling}) =
      _FloatingState;

  const FloatingState._();
}
