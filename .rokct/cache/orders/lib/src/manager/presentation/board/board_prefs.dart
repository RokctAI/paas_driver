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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Header state of the approved orders workspace (frames 33a/33b): the
/// board/list view toggle, the date-range filter, the sound-alert bell and
/// its orange activity dot, and which status tab the phone list mode shows.
class BoardPrefsState {
  /// The user's explicit board/list choice (the POS's
  /// `orderTableProvider.isListView`); null = untouched, and the window
  /// decides: phones default to LIST (approved frame 33b), wide windows
  /// to the BOARD (frame 33a). Resolve through [listView].
  final bool? listViewChoice;

  final DateTime? from;
  final DateTime? to;

  /// New-order chime on/off (bell tap toggles it).
  final bool soundEnabled;

  /// The orange dot on the bell — set when a new/accepted order landed
  /// since the user last looked, cleared on bell tap.
  final bool hasActivity;

  /// Active status tab of the list mode (index into the visible columns).
  final int listTabIndex;

  const BoardPrefsState({
    this.listViewChoice,
    this.from,
    this.to,
    this.soundEnabled = true,
    this.hasActivity = false,
    this.listTabIndex = 0,
  });

  /// The mode actually shown: the explicit choice, else the window's
  /// default (list on compact, board on wide).
  bool listView({required bool compact}) => listViewChoice ?? compact;

  static const _unset = Object();

  BoardPrefsState copyWith({
    bool? listViewChoice,
    Object? from = _unset,
    Object? to = _unset,
    bool? soundEnabled,
    bool? hasActivity,
    int? listTabIndex,
  }) => BoardPrefsState(
    listViewChoice: listViewChoice ?? this.listViewChoice,
    from: identical(from, _unset) ? this.from : from as DateTime?,
    to: identical(to, _unset) ? this.to : to as DateTime?,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    hasActivity: hasActivity ?? this.hasActivity,
    listTabIndex: listTabIndex ?? this.listTabIndex,
  );

  /// The repository's `from_date` wire format.
  String? get fromWire =>
      from == null ? null : DateFormat('yyyy-MM-dd').format(from!);

  String? get toWire =>
      to == null ? null : DateFormat('yyyy-MM-dd').format(to!);
}

class BoardPrefsNotifier extends StateNotifier<BoardPrefsState> {
  BoardPrefsNotifier() : super(const BoardPrefsState());

  void setListView(bool isListView) =>
      state = state.copyWith(listViewChoice: isListView);

  void setRange(DateTime? from, DateTime? to) =>
      state = state.copyWith(from: from, to: to);

  void toggleSound() => state = state.copyWith(
    soundEnabled: !state.soundEnabled,
    hasActivity: false,
  );

  void markActivity() => state = state.copyWith(hasActivity: true);

  void selectListTab(int index) => state = state.copyWith(listTabIndex: index);
}

final boardPrefsProvider =
    StateNotifierProvider<BoardPrefsNotifier, BoardPrefsState>(
      (ref) => BoardPrefsNotifier(),
    );
