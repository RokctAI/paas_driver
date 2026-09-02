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
