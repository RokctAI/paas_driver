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

import 'package:flutter/material.dart';
import 'package:kitchen_sdk/src/common/infrastructure/models/data/kitchen_data.dart';

/// Plain immutable state rather than a `freezed` union — keeps `kitchen_sdk`
/// analyzable without a `build_runner` pass. (Sibling SDKs are split on this:
/// `orders_sdk`/`auth_sdk` commit their generated files, `products_sdk` does
/// not.)
class KitchenPickerState {
  const KitchenPickerState({
    this.isLoading = false,
    this.kitchens = const [],
    this.activeIndex = 0,
    this.selected,
    this.error,
    this.kitchenController,
  });

  final bool isLoading;
  final List<KitchenModel> kitchens;
  final int activeIndex;
  final KitchenModel? selected;

  /// Set on a failed fetch. The app's two variants disagreed here — the create
  /// notifier took a `BuildContext` and raised a snackbar itself, the edit one
  /// swallowed the failure. Neither belongs in the application layer, so the
  /// failure is surfaced as state and the presentation layer decides.
  final String? error;

  final TextEditingController? kitchenController;

  KitchenPickerState copyWith({
    bool? isLoading,
    List<KitchenModel>? kitchens,
    int? activeIndex,
    KitchenModel? selected,
    String? error,
    TextEditingController? kitchenController,
  }) =>
      KitchenPickerState(
        isLoading: isLoading ?? this.isLoading,
        kitchens: kitchens ?? this.kitchens,
        activeIndex: activeIndex ?? this.activeIndex,
        selected: selected ?? this.selected,
        error: error,
        kitchenController: kitchenController ?? this.kitchenController,
      );
}
