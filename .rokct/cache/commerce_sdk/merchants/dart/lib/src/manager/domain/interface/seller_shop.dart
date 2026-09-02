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
import 'package:merchants_sdk/src/manager/infrastructure/models/response/my_shop_response.dart';

/// Contract of `paas_manager`'s shop-management half of `UsersInterface`
/// (`getMyShop` / `updateShop` / `setOnlineOffline` /
/// `updateShopWorkingDays`), carved out of that grab-bag interface and owned
/// by merchants_sdk — restaurant management is this SDK's manager vertical
/// (fork plan S-11). The profile half of the legacy interface stays with
/// users_sdk (S-2); statistics went to revenue_sdk; delivery zones to
/// zones_sdk.
///
/// Models are base_sdk's ([ShopData]/[ShopWorkingDay]/[Translation]) — the
/// legacy 939-line manager `ShopData` twin is not carried over
/// (BASE_SDK_OVERLAP dedup rule). The one field base's model lacks,
/// `order_payment`, rides on [MyShopResponse].
abstract class SellerShopRepositoryFacade {
  /// Registration-time shop create (the retired host "become a seller"
  /// funnel's surviving core): `shop.create_shop` requires only the shop
  /// name — phone and address are the optional identity extras the step also
  /// collects. Everything else the legacy page gathered (images, tax,
  /// delivery settings, prices, documents) is post-create management via
  /// [updateShop]. Backs the shop-setup registration step
  /// (`ShopSetupSlide`); endpoint state in docs/frappe-endpoint-contract.md.
  Future<ApiResult<void>> createShop({
    required String name,
    String? phone,
    String? address,
  });

  Future<ApiResult<MyShopResponse>> getMyShop();

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
  });

  /// Explicit-status replacement for the legacy no-body
  /// `setOnlineOffline()` toggle: `seller_shop.set_shop_working_status`
  /// takes the desired state, so the caller passes it (computed from current
  /// state) instead of relying on a server-side flip.
  Future<ApiResult<void>> setWorkingStatus({required bool open});

  /// `get_shop` does not return working days, so they are fetched separately
  /// from `seller_shop_settings.get_seller_shop_working_days` and merged
  /// into [ShopData.shopWorkingDays] by the notifier.
  Future<ApiResult<List<ShopWorkingDay>>> getShopWorkingDays();

  Future<ApiResult<void>> updateShopWorkingDays({
    required List<ShopWorkingDay> workingDays,
    String? uuid,
  });
}
