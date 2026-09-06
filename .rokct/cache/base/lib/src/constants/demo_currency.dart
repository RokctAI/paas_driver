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


import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/services/local_storage.dart';

/// The currency every demo (`--dart-define=IS_DEMO=true`) amount prints in:
/// South African rand, symbol before the amount ("R1,500.00").
///
/// Every money string in the fleet goes through [AppHelpers.numberFormat],
/// which reads `LocalStorage.getSelectedCurrency()`. A real build fills that
/// from the backend's currency list (`CurrencyNotifier.fetchCurrency`); a
/// demo build talks to no backend, so nothing ever selected one and intl fell
/// through to its locale default - the ISO code as a suffix, "42.50USD" -
/// while every seed fixture in the fleet trades in rand (the demo account is
/// in Sandton with a +27 number, the wallet ledger cashes out to a South
/// African bank, the seeded shops and orders carry ZAR). The seller-side
/// SDKs each seeded this same currency from their own DI; this is the one
/// copy the kernel owns so every composed shell - customer, seller, driver -
/// prints the same money from boot, without each feature SDK repeating it.
///
/// Two seams, both inert outside a demo build:
///
/// * [seed] stores [rand] as the selected currency once, from
///   `BaseSdkDependencies.register`, only where nothing is selected - so a
///   real currency, or a test harness's own seed, is never overwritten. The
///   request bodies that send `currency_id` / `rate` read the same store.
/// * [fallback] is what [AppHelpers.numberFormat] consults when the store is
///   still empty, so a demo build can never print the ISO-code suffix even
///   if the store is cleared under it.
abstract class DemoCurrency {
  DemoCurrency._();

  /// Test-only stand-in for [AppConstants.isDemo], which is a compile-time
  /// constant. `null` (the default) reads the constant.
  @visibleForTesting
  static bool? isDemoOverride;

  static bool get _isDemo => isDemoOverride ?? AppConstants.isDemo;

  /// South African rand, id `ZAR`, symbol `R`, rate 1, position `before` -
  /// field for field the currency the seller-side demo fixtures already
  /// carry. Not a const: `CurrencyData` has no const constructor.
  static final CurrencyData rand = CurrencyData(
    id: 'ZAR',
    symbol: 'R',
    title: 'South African Rand',
    rate: 1,
    isDefault: true,
    active: true,
    position: 'before',
  );

  /// [rand] in a demo build, `null` otherwise. A real build keeps intl's
  /// own behaviour when no currency is selected.
  static CurrencyData? get fallback => _isDemo ? rand : null;

  /// Stores [rand] as the selected currency in a demo build when nothing is
  /// selected yet. Requires [LocalStorage.init] to have completed;
  /// SharedPreferences writes its in-memory cache synchronously, so the
  /// first read after this call already sees it - nothing awaits.
  static void seed() {
    if (!_isDemo) return;
    if (LocalStorage.getSelectedCurrency() != null) return;
    unawaited(LocalStorage.setSelectedCurrency(rand));
  }
}
