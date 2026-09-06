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


// Every demo amount must print in rand. The wallet history in the guided
// tour read "42.50USD" / "1,500.00USD": nothing in a demo build selected a
// currency, so AppHelpers.numberFormat fell through to intl's locale default.
// The kernel now seeds ZAR at boot and falls back to it while the store is
// empty; a real build is untouched.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:base_sdk/src/constants/demo_currency.dart';
import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  tearDown(() {
    // The override is app-global; never let one test leak into the next.
    DemoCurrency.isDemoOverride = null;
  });

  test('the demo currency is South African rand, symbol before the amount',
      () {
    expect(DemoCurrency.rand.id, 'ZAR');
    expect(DemoCurrency.rand.symbol, 'R');
    expect(DemoCurrency.rand.position, 'before');
    expect(DemoCurrency.rand.rate, 1);
  });

  test('seed stores rand in a demo build with nothing selected', () async {
    DemoCurrency.isDemoOverride = true;
    expect(LocalStorage.getSelectedCurrency(), isNull);

    DemoCurrency.seed();

    expect(LocalStorage.getSelectedCurrency()?.id, 'ZAR');
    expect(LocalStorage.getSelectedCurrency()?.symbol, 'R');
    expect(LocalStorage.getSelectedCurrency()?.position, 'before');
  });

  test('seed never overwrites a currency that is already selected', () async {
    DemoCurrency.isDemoOverride = true;
    await LocalStorage.setSelectedCurrency(
      CurrencyData(id: 'EUR', symbol: '€', position: 'before', rate: 1),
    );

    DemoCurrency.seed();

    expect(LocalStorage.getSelectedCurrency()?.id, 'EUR');
  });

  test('seed is a no-op outside a demo build', () {
    DemoCurrency.isDemoOverride = false;

    DemoCurrency.seed();

    expect(LocalStorage.getSelectedCurrency(), isNull);
    expect(DemoCurrency.fallback, isNull);
  });

  test('numberFormat prints the wallet ledger amounts in rand once seeded',
      () {
    DemoCurrency.isDemoOverride = true;
    DemoCurrency.seed();

    expect(AppHelpers.numberFormat(number: 1500), 'R1,500.00');
    expect(AppHelpers.numberFormat(number: 42.5), 'R42.50');
    expect(AppHelpers.numberFormat(number: 264), 'R264.00');
    expect(AppHelpers.numberFormat(number: 0), 'R0.00');
  });

  test('numberFormat prints rand in a demo build even with an empty store',
      () {
    DemoCurrency.isDemoOverride = true;
    expect(LocalStorage.getSelectedCurrency(), isNull);

    final rendered = AppHelpers.numberFormat(number: 1500);

    expect(rendered, 'R1,500.00');
    expect(rendered, isNot(contains('USD')));
  });

  test('an explicit order symbol still wins over the demo currency', () {
    DemoCurrency.isDemoOverride = true;
    DemoCurrency.seed();

    expect(
      AppHelpers.numberFormat(number: 10, symbol: r'$', isOrder: true),
      r'$10.00',
    );
  });

  test('a real build with nothing selected keeps intl\'s own default', () {
    DemoCurrency.isDemoOverride = false;

    final rendered = AppHelpers.numberFormat(number: 1500);

    expect(rendered, isNot(startsWith('R')));
  });
}
