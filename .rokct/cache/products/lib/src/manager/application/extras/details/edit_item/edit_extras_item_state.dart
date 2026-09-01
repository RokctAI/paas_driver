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
class EditExtrasItemState {
  const EditExtrasItemState({this.isLoading = false, this.error});

  final bool isLoading;

  /// Set on a failed update; the page decides how to show it.
  final String? error;

  EditExtrasItemState copyWith({bool? isLoading, String? error}) =>
      EditExtrasItemState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}
