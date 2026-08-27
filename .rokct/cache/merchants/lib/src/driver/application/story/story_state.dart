// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
