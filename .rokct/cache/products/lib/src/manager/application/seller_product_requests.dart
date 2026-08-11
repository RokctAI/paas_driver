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
}) {
  final String locale = LocalStorage.getLanguage()?.locale ?? 'en';
  return {
    'title': {locale: title},
    'description': {locale: description},
    'tax': num.tryParse(tax),
    'interval': num.tryParse(interval),
    'min_qty': num.tryParse(minQty),
    'max_qty': num.tryParse(maxQty),
    'active': active ? 1 : 0,
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
      'interval': num.tryParse(interval),
      'min_qty': int.tryParse(minQty),
      'max_qty': int.tryParse(maxQty),
      'active': active ? 1 : 0,
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
