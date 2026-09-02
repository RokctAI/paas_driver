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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:merchants_sdk/src/common/infrastructure/repositories/mock_shops_repository.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';
import 'package:merchants_sdk/src/manager/infrastructure/models/response/my_shop_response.dart';

/// Demo-only [SellerShopRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// gives the demo manager a shop identity, so the restaurant hub's header,
/// the shop-edit flow and the open/closed switch all render against a real
/// shop instead of a blank header. Selected in place of
/// [SellerShopRepository] by `ManagerMerchantsDependencies` — the same
/// `AppConstants.isDemo` split this SDK already applies to the POS catalog,
/// POS orders and quick-flow seams.
///
/// The shop served is [MockShopsRepository.demoShop] itself, NOT a second
/// invention: `MerchantsSdkDependencies` already serves that identity to the
/// customer-facing [ShopsRepositoryFacade] in demo builds, and a manager who
/// renames or closes the shop here should be renaming or closing the shop a
/// demo customer browses. Same SDK, so no cross-SDK import is involved
/// (ADR-005).
///
/// Never used in production: no HTTP client is constructed, every write
/// mutates the in-memory demo shop and nothing leaves the device. Working
/// days are session-local and reset on the next launch.
class DemoSellerShopRepository implements SellerShopRepositoryFacade {
  /// The shared demo shop. Deliberately the same object the customer-facing
  /// mock serves, so an edit made in the manager hub is the edit a demo
  /// browse sees.
  static ShopData get _shop => MockShopsRepository.demoShop;

  /// A plausible trading week for the seeded shop: open every day, late on
  /// Friday and Saturday, closed Sunday.
  static List<ShopWorkingDay> _seedWorkingDays() => <ShopWorkingDay>[
        ShopWorkingDay(id: 1, day: 'monday', from: '09:00', to: '21:00'),
        ShopWorkingDay(id: 2, day: 'tuesday', from: '09:00', to: '21:00'),
        ShopWorkingDay(id: 3, day: 'wednesday', from: '09:00', to: '21:00'),
        ShopWorkingDay(id: 4, day: 'thursday', from: '09:00', to: '21:00'),
        ShopWorkingDay(id: 5, day: 'friday', from: '09:00', to: '23:00'),
        ShopWorkingDay(id: 6, day: 'saturday', from: '10:00', to: '23:00'),
        ShopWorkingDay(
          id: 7,
          day: 'sunday',
          from: '10:00',
          to: '16:00',
          disabled: true,
        ),
      ];

  /// Session-local overlay, seeded lazily on first read and replaced by
  /// [updateShopWorkingDays] so an edit sticks for the rest of the session.
  static List<ShopWorkingDay>? _workingDays;

  /// The `order_payment` setting the real endpoint does not return yet; the
  /// UI defaults to 'before' when it is null, so the demo says so explicitly.
  static String _orderPayment = 'before';

  /// Drops the session overlay so the next read re-seeds; used by tests.
  static void reset() {
    _workingDays = null;
    _orderPayment = 'before';
  }

  @override
  Future<ApiResult<void>> createShop({
    required String name,
    String? phone,
    String? address,
  }) async {
    _shop.translation = Translation(
      title: name,
      description: _shop.translation?.description,
      address: address ?? _shop.translation?.address,
      locale: 'en',
    );
    if (phone != null) _shop.phone = phone;
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<MyShopResponse>> getMyShop() async {
    return ApiResult<MyShopResponse>.success(
      data: MyShopResponse(data: _shop, orderPayment: _orderPayment),
    );
  }

  @override
  Future<ApiResult<MyShopResponse>> updateShop({
    String? backImg,
    String? logoImg,
    String? phone,
    String? tax,
    String? minAmount,
    Translation? translation,
    String? deliveryTimeType,
    String? deliveryTimeFrom,
    String? deliveryTimeTo,
    String? orderPayment,
  }) async {
    // Acknowledged locally: the edit lands on the in-memory demo shop so the
    // hub re-renders with it, and nothing is sent anywhere.
    if (backImg != null) _shop.backgroundImg = backImg;
    if (logoImg != null) _shop.logoImg = logoImg;
    if (phone != null) _shop.phone = phone;
    if (tax != null) _shop.tax = num.tryParse(tax) ?? _shop.tax;
    if (minAmount != null) {
      _shop.minAmount = num.tryParse(minAmount) ?? _shop.minAmount;
    }
    if (translation != null) _shop.translation = translation;
    if (deliveryTimeType != null ||
        deliveryTimeFrom != null ||
        deliveryTimeTo != null) {
      _shop.deliveryTime = DeliveryTime(
        type: deliveryTimeType ?? _shop.deliveryTime?.type,
        from: deliveryTimeFrom ?? _shop.deliveryTime?.from,
        to: deliveryTimeTo ?? _shop.deliveryTime?.to,
      );
    }
    if (orderPayment != null) _orderPayment = orderPayment;
    return getMyShop();
  }

  @override
  Future<ApiResult<void>> setWorkingStatus({required bool open}) async {
    _shop.open = open;
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<List<ShopWorkingDay>>> getShopWorkingDays() async {
    return ApiResult<List<ShopWorkingDay>>.success(
      data: _workingDays ??= _seedWorkingDays(),
    );
  }

  @override
  Future<ApiResult<void>> updateShopWorkingDays({
    required List<ShopWorkingDay> workingDays,
    String? uuid,
  }) async {
    _workingDays = List<ShopWorkingDay>.from(workingDays);
    return const ApiResult.success(data: null);
  }
}
