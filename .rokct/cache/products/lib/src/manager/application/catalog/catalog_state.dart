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

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
///
/// Selection state for the approved catalog workspace (frame 35a): which
/// product's READ detail holds the last plane on wide windows, and whether
/// the counts-only quick-adjust surface (approved 35e) is open as a plane
/// pane. Phones never write this state — there a tap pushes a real route
/// (approved 35c/35d keep the shipped tap-straight-to-edit).
class CatalogState {
  const CatalogState({this.selectedId, this.quickAdjustOpen = false});

  /// Id of the product whose read-only detail pane is open (wide only).
  final String? selectedId;

  /// The 35e quick-adjust surface as a pushed plane pane (wide widths; on
  /// phones the same surface is a bottom sheet per the 12:02Z sheet fork).
  final bool quickAdjustOpen;

  CatalogState copyWith({
    String? selectedId,
    bool clearSelection = false,
    bool? quickAdjustOpen,
  }) =>
      CatalogState(
        selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
        quickAdjustOpen: quickAdjustOpen ?? this.quickAdjustOpen,
      );
}
