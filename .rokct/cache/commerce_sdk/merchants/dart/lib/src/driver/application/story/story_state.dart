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

/// Plain immutable state rather than a `freezed` union (merchants_sdk
/// convention — see `src/manager/application/main/main_state.dart`).
///
/// The legacy slice (paas_driver `lib/application/story/story_state.dart`)
/// was a single-field `@freezed` class; a hand-written `copyWith` is
/// behavior-identical and keeps merchants_sdk analyzable without a
/// `build_runner` pass (and ships no `.freezed.dart`).
class StoryState {
  const StoryState({this.currentIndex = 0});

  final int currentIndex;

  StoryState copyWith({int? currentIndex}) =>
      StoryState(currentIndex: currentIndex ?? this.currentIndex);
}
