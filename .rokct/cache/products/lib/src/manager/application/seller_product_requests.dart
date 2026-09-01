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

/// Request-shaping helpers for the seller product-authoring flows.
///
/// The app's `products_repository` built these bodies from typed parameters;
/// the SDK facade takes ready maps instead, so the shaping moved here into the
/// application layer where the create/edit, addon and stock notifiers share it.
/// Wire keys are kept exactly as the legacy client sent them (including the
/// create/update asymmetry of `sku` vs `bar_code`).
library;

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';

/// Body for `createProduct`. Titles/descriptions are keyed on the display
/// locale — the app keyed on `LocalStorage.getSystemLanguage()`, which base_sdk
/// has no accessor for; same documented departure as stage 2's
/// `createCategory`.
Map<String, dynamic> buildCreateProductRequest({
  required String title,
  required String description,
  required String tax,
  required String interval,
  required String minQty,
  required String maxQty,
  required String qrcode,
  required bool active,
  String? categoryId,
  String? kitchenId,
  String? unitId,
  List<String>? images,
  bool isAddon = false,
  bool isAdult = false,
  String costPrice = '',
}) {
  final String locale = LocalStorage.getLanguage()?.locale ?? 'en';
  return {
    'title': {locale: title},
    'description': {locale: description},
    'tax': num.tryParse(tax),
    // Manager-only cost price ('cost' on the Product doctype). Sent only when
    // the form actually holds a value so flows that don't surface the field
    // (addon create/edit) never touch it server-side.
    if (num.tryParse(costPrice) != null) 'cost': num.tryParse(costPrice),
    'interval': num.tryParse(interval),
    'min_qty': num.tryParse(minQty),
    'max_qty': num.tryParse(maxQty),
    'active': active ? 1 : 0,
    'is_adult': isAdult ? 1 : 0,
    if (qrcode.isNotEmpty) 'sku': qrcode,
    if (kitchenId != null) 'kitchen_id': kitchenId,
    if (categoryId != null) 'category_id': categoryId,
    if (unitId != null) 'unit_id': unitId,
    if (images != null) 'images': images,
    if (isAddon) 'addon': 1,
  };
}

/// Body for `updateProduct`. [titlesAndDescriptions] maps a locale to a
/// two-element `[title, description]` list — the shape the app's edit state
/// (`mapOfDesc`) already keeps per language.
Map<String, dynamic> buildUpdateProductRequest({
  required Map<String, List<String>> titlesAndDescriptions,
  required String tax,
  required String interval,
  required String minQty,
  required String maxQty,
  required bool active,
  String? qrcode,
  String? categoryId,
  String? kitchenId,
  String? unitId,
  List<String>? images,
  bool needAddons = false,
  bool isAdult = false,
  String costPrice = '',
}) =>
    {
      'title': {
        for (final entry in titlesAndDescriptions.entries)
          entry.key: entry.value.isNotEmpty ? entry.value.first : '',
      },
      'description': {
        for (final entry in titlesAndDescriptions.entries)
          entry.key: entry.value.isNotEmpty ? entry.value.last : '',
      },
      'tax': num.tryParse(tax),
      // Same omit-when-empty contract as buildCreateProductRequest: a blank
      // field leaves the stored cost untouched rather than nulling it.
      if (num.tryParse(costPrice) != null) 'cost': num.tryParse(costPrice),
      'interval': num.tryParse(interval),
      'min_qty': int.tryParse(minQty),
      'max_qty': int.tryParse(maxQty),
      'active': active ? 1 : 0,
      'is_adult': isAdult ? 1 : 0,
      if (qrcode != null) 'bar_code': qrcode,
      if (categoryId != null) 'category_id': categoryId,
      if (kitchenId != null) 'kitchen_id': kitchenId,
      if (unitId != null) 'unit_id': unitId,
      if (images != null) 'images': images,
      if (needAddons) 'addon': 1,
    };

/// Per-stock entries for `updateStocks` — extra-value ids deduplicated, addon
/// product ids deduplicated, `stock_id` only for stocks that exist server-side.
///
/// Ids are Frappe docname strings. An entry without an id cannot be
/// referenced server-side, so it is dropped (with a debug log) rather than
/// replaced by a sentinel the backend would silently no-op on.
List<Map<String, dynamic>> buildStocksRequest(List<SellerStock> stocks) {
  final List<Map<String, dynamic>> request = [];
  for (final stock in stocks) {
    List<String> ids = [
      for (final extras in stock.extras ?? <SellerExtras>[])
        if (extras.id != null) extras.id!,
    ];
    if (ids.length != (stock.extras?.length ?? 0)) {
      debugPrint('==> stocks request: dropped extra value(s) without an id');
    }
    ids = ids.toSet().toList();
    List<String> addonIds = [
      for (final addon in stock.localAddons ?? <SellerAddonData>[])
        if (addon.product?.id != null) addon.product!.id!,
    ];
    if (addonIds.length != (stock.localAddons?.length ?? 0)) {
      debugPrint('==> stocks request: dropped addon(s) without a product id');
    }
    addonIds = addonIds.toSet().toList();
    request.add({
      'price': stock.price,
      if (stock.sku?.isNotEmpty ?? false) 'sku': stock.sku,
      'quantity': stock.quantity,
      // '-1' is the legacy local-only sentinel for a stock that does not
      // exist server-side yet.
      if (stock.id != null && stock.id != '-1') 'stock_id': stock.id,
      'ids': ids,
      if (addonIds.isNotEmpty) 'addons': addonIds,
    });
  }
  return request;
}

/// Cartesian product of the selected extra values, one list per group — every
/// combination becomes a stock variant. Port of the app's
/// `AppHelpers.cartesian`, typed on the SDK's [SellerExtras]; base_sdk has no
/// equivalent and this is products_sdk-specific, so it lives here.
List<List<SellerExtras>> cartesianExtras(List<List<SellerExtras?>> args) {
  final List<List<SellerExtras>> result = [];
  final int max = args.length - 1;

  void helper(List<SellerExtras> arr, int i) {
    for (final SellerExtras? item in args[i]) {
      if (item == null) continue;
      final List<SellerExtras> a = List.from(arr)..add(item);
      if (i == max) {
        result.add(a);
      } else {
        helper(a, i + 1);
      }
    }
  }

  if (args.isNotEmpty) helper([], 0);
  return result;
}
