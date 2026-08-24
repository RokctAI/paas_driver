// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// Request-shaping helpers for the seller product-authoring flows.
///
/// The app's `products_repository` built these bodies from typed parameters;
/// the SDK facade takes ready maps instead, so the shaping moved here into the
/// application layer where the create/edit, addon and stock notifiers share it.
/// Wire keys are kept exactly as the legacy client sent them (including the
/// create/update asymmetry of `sku` vs `bar_code`).
library;

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
  int? categoryId,
  int? kitchenId,
  int? unitId,
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
  int? categoryId,
  int? kitchenId,
  int? unitId,
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
List<Map<String, dynamic>> buildStocksRequest(List<SellerStock> stocks) {
  final List<Map<String, dynamic>> request = [];
  for (final stock in stocks) {
    List<int> ids = [
      for (final extras in stock.extras ?? <SellerExtras>[]) extras.id ?? 0,
    ];
    ids = ids.toSet().toList();
    List<int> addonIds = [
      for (final addon in stock.localAddons ?? <SellerAddonData>[])
        addon.product?.id ?? 0,
    ];
    addonIds = addonIds.toSet().toList();
    request.add({
      'price': stock.price,
      if (stock.sku?.isNotEmpty ?? false) 'sku': stock.sku,
      'quantity': stock.quantity,
      if (stock.id != -1 && stock.id != null) 'stock_id': stock.id,
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
