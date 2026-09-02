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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:merchants_sdk/src/manager/domain/interface/quick_flow.dart';

/// Demo-mode Quick flow (`--dart-define=IS_DEMO=true`, registered by
/// `ManagerMerchantsDependencies.register`): the section-42 seed content —
/// a water-refill station with five of nine digits set — held in memory so
/// headless tours and the standalone test harness drive the whole surface,
/// and the till's autodial, with zero backend contact.
///
/// Auto-accept starts ON (it is the LIVE field, and the seed shop uses it),
/// auto-complete at Ready starts OFF — the correct default for a switch
/// that completes orders with nobody handing them over.
class MockQuickFlowRepository implements QuickFlowRepositoryFacade {
  MockQuickFlowRepository() : _settings = seed;

  QuickFlowSettings _settings;

  static ProductData _product(String id, String title, num price) =>
      ProductData(
        id: id,
        shopId: '1',
        active: true,
        translation: Translation(title: title, locale: 'en'),
        stocks: [
          Stocks(id: id, price: price, quantity: 100, totalPrice: price),
        ],
      );

  static QuickFlowSettings get seed => QuickFlowSettings(
        shopName: 'Blue Tap Water Refill',
        autoAcceptOrders: true,
        platformAutoApprove: true,
        autoCompleteAtReady: false,
        keypadAutodial: true,
        presets: [
          QuickFlowPreset(digit: 1, product: _product('1', '5 L refill', 12)),
          QuickFlowPreset(digit: 2, product: _product('2', '10 L refill', 20)),
          QuickFlowPreset(digit: 3, product: _product('3', '20 L refill', 35)),
          QuickFlowPreset(
            digit: 4,
            product: _product('4', '25 L bottle swap', 45),
          ),
          QuickFlowPreset(digit: 5, product: _product('5', 'Ice · 2 kg', 28)),
        ],
      );

  @override
  Future<ApiResult<QuickFlowSettings>> getQuickFlowSettings() async =>
      ApiResult.success(data: _settings);

  @override
  Future<ApiResult<QuickFlowSettings>> updateQuickFlowSettings({
    bool? autoAcceptOrders,
    bool? autoCompleteAtReady,
    bool? keypadAutodial,
    List<QuickFlowPreset>? presets,
  }) async {
    _settings = _settings.copyWith(
      autoAcceptOrders: autoAcceptOrders,
      autoCompleteAtReady: autoCompleteAtReady,
      keypadAutodial: keypadAutodial,
      presets: presets,
    );
    return ApiResult.success(data: _settings);
  }
}
