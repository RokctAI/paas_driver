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
class EditAddonState {
  const EditAddonState({
    this.isLoading = false,
    this.mapOfDesc = const {},
    this.error,
  });

  final bool isLoading;

  /// Locale -> `[title, description]`, one entry per authored language.
  final Map<String, List<String>> mapOfDesc;

  /// Set on a failed update; the page decides how to show it.
  final String? error;

  EditAddonState copyWith({
    bool? isLoading,
    Map<String, List<String>>? mapOfDesc,
    String? error,
  }) =>
      EditAddonState(
        isLoading: isLoading ?? this.isLoading,
        mapOfDesc: mapOfDesc ?? this.mapOfDesc,
        error: error,
      );
}
