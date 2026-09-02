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

// ApiResult's `when` lives in the freezed extension declared by this
// library, so the import is load-bearing even though no type is named.
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:merchants_sdk/src/manager/application/quick_flow/quick_flow_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/quick_flow.dart';

/// Quick flow settings (design strip section 42).
///
/// Every switch here writes THROUGH to the shop: the surface has no local
/// draft and no Save button, because two of the three switches change what
/// the till does the moment they move and a half-saved automation setting
/// is worse than none. Each write is optimistic — the row flips at once and
/// REVERTS if the server refuses, so the switch can never sit on a state
/// the shop does not actually hold.
class QuickFlowNotifier extends StateNotifier<QuickFlowState> {
  QuickFlowNotifier(this._repository) : super(const QuickFlowState());

  final QuickFlowRepositoryFacade _repository;

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getQuickFlowSettings();
    if (!mounted) return;
    result.when(
      success: (data) => state = state.copyWith(
        settings: data,
        isLoading: false,
        loaded: true,
      ),
      failure: (error, statusCode) => state = state.copyWith(
        isLoading: false,
        loaded: true,
        error: error,
      ),
    );
  }

  Future<void> setAutoAcceptOrders(bool value) =>
      _write(state.settings.copyWith(autoAcceptOrders: value),
          autoAcceptOrders: value);

  Future<void> setAutoCompleteAtReady(bool value) =>
      _write(state.settings.copyWith(autoCompleteAtReady: value),
          autoCompleteAtReady: value);

  Future<void> setKeypadAutodial(bool value) =>
      _write(state.settings.copyWith(keypadAutodial: value),
          keypadAutodial: value);

  /// Maps [digit] (1–9) to [preset]'s product, replacing whatever that key
  /// held. The whole map goes up, because the grid is owned as a unit.
  Future<void> setPreset(QuickFlowPreset preset) {
    final presets = [
      ...state.settings.presets.where((p) => p.digit != preset.digit),
      preset,
    ]..sort((a, b) => a.digit.compareTo(b.digit));
    return _write(state.settings.copyWith(presets: presets), presets: presets);
  }

  /// Clears [digit] — the key goes back to inert, which is a real state and
  /// not an error (design chip 805).
  Future<void> clearPreset(int digit) {
    final presets =
        state.settings.presets.where((p) => p.digit != digit).toList();
    return _write(state.settings.copyWith(presets: presets), presets: presets);
  }

  Future<void> _write(
    QuickFlowSettings optimistic, {
    bool? autoAcceptOrders,
    bool? autoCompleteAtReady,
    bool? keypadAutodial,
    List<QuickFlowPreset>? presets,
  }) async {
    final previous = state.settings;
    state = state.copyWith(
      settings: optimistic,
      saving: true,
      clearError: true,
    );
    final result = await _repository.updateQuickFlowSettings(
      autoAcceptOrders: autoAcceptOrders,
      autoCompleteAtReady: autoCompleteAtReady,
      keypadAutodial: keypadAutodial,
      presets: presets,
    );
    if (!mounted) return;
    result.when(
      success: (data) =>
          state = state.copyWith(settings: data, saving: false, loaded: true),
      failure: (error, statusCode) => state = state.copyWith(
        // Revert: the shop does not hold what the row is showing.
        settings: previous,
        saving: false,
        error: error,
      ),
    );
  }
}
