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
import 'package:base_sdk/src/models/data/meta.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/create_seller_extras_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_extras_groups_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_group_extras_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_products_paginate_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/single_seller_extras_group_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/single_seller_product_response.dart';

/// Demo-only [SellerProductsRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// serves a small fictional menu — products, add-ons and extras groups —
/// from memory, so the manager foods tab renders a stocked menu instead of
/// three empty tabs in demo builds. Selected in place of
/// [SellerProductsRepository] by `ProductsSdkDependencies` — the same
/// `AppConstants.isDemo` ternary this SDK already applies to its
/// customer-facing products/categories/brands facades.
///
/// Never used in production: no HTTP client is constructed, every write is
/// acknowledged locally and nothing leaves the device. The seed is obvious
/// fiction, priced in South African rand to match the demo shop's trade —
/// deliberately the same dishes orders_sdk's `DemoSellerOrdersRepository`
/// seeds onto the board, so the menu and the queue tell one coherent story.
/// (Duplicated rather than shared: ADR-005 keeps products_sdk free of a
/// cross-SDK import for eight dish names.)
///
/// Session-local by design: edits made during a tour stick for the rest of
/// the process and reset on the next launch. Nothing is persisted.
class DemoSellerProductsRepository implements SellerProductsRepositoryFacade {
  static Translation _t(String title, [String? description]) =>
      Translation(title: title, description: description, locale: 'en');

  static SellerCategoryData _category(String id, String title) =>
      SellerCategoryData(
        id: id,
        uuid: 'demo_category_$id',
        shopId: '1',
        type: 'main',
        active: true,
        status: 'published',
        translation: _t(title),
      );

  static final SellerCategoryData _mains = _category('1', 'Mains');
  static final SellerCategoryData _sides = _category('2', 'Sides');
  static final SellerCategoryData _drinks = _category('3', 'Drinks');

  static final SellerUnitData _each = SellerUnitData(
    id: '1',
    active: true,
    position: 'after',
    translation: _t('each'),
    locales: <String>['en'],
  );

  static SellerProductData _product({
    required String id,
    required String title,
    required String description,
    required num price,
    required int quantity,
    required SellerCategoryData category,
    bool addon = false,
  }) =>
      SellerProductData(
        id: id,
        uuid: 'demo_product_$id',
        shopId: '1',
        categoryId: category.id,
        category: category,
        unit: _each,
        unitId: _each.id,
        tax: 0,
        cost: (price * 0.4).roundToDouble(),
        active: true,
        addon: addon,
        status: 'published',
        minQty: 1,
        maxQty: 20,
        locales: <String>['en'],
        translation: _t(title, description),
        stocks: <SellerStock>[
          SellerStock(
            id: id,
            countableId: id,
            price: price,
            quantity: quantity,
            tax: 0,
            discount: 0,
            totalPrice: price,
            sku: 'SKU-$id',
          ),
        ],
      );

  /// The seeded menu: six sellable products across three categories, plus
  /// two add-ons. Enough for the foods tab to look like a real trading shop
  /// without spilling past one screen.
  static List<SellerProductData> _seedProducts() => <SellerProductData>[
        _product(
          id: '1',
          title: 'Peri-peri chicken wrap',
          description: 'Flame-grilled chicken, peri sauce, soft tortilla.',
          price: 89.00,
          quantity: 40,
          category: _mains,
        ),
        _product(
          id: '2',
          title: 'Chakalaka fries',
          description: 'Hand-cut fries under a spoon of chakalaka.',
          price: 45.50,
          quantity: 60,
          category: _sides,
        ),
        _product(
          id: '3',
          title: 'Bunny chow (quarter)',
          description: 'Quarter loaf, lamb curry, grated carrot salad.',
          price: 66.00,
          quantity: 25,
          category: _mains,
        ),
        _product(
          id: '4',
          title: 'Boerewors roll',
          description: 'Farm-style wors on a soft roll with onion relish.',
          price: 48.00,
          quantity: 35,
          category: _mains,
        ),
        _product(
          id: '5',
          title: 'Family braai platter',
          description: 'Wors, chops, wings and pap for four.',
          price: 390.75,
          quantity: 8,
          category: _mains,
        ),
        _product(
          id: '6',
          title: 'Rooibos iced tea',
          description: 'House-brewed rooibos over ice with lemon.',
          price: 29.00,
          quantity: 90,
          category: _drinks,
        ),
      ];

  static List<SellerProductData> _seedAddons() => <SellerProductData>[
        _product(
          id: '101',
          title: 'Extra peri sauce',
          description: 'A ramekin of the hot one.',
          price: 12.00,
          quantity: 200,
          category: _sides,
          addon: true,
        ),
        _product(
          id: '102',
          title: 'Grated cheddar',
          description: 'A generous handful.',
          price: 15.50,
          quantity: 150,
          category: _sides,
          addon: true,
        ),
      ];

  static SellerExtras _extra(String id, String groupId, String value) =>
      SellerExtras(
        id: id,
        extraGroupId: groupId,
        value: value,
        active: true,
      );

  static List<SellerExtrasGroup> _seedGroups() => <SellerExtrasGroup>[
        SellerExtrasGroup(
          id: '1',
          shopId: '1',
          type: 'text',
          translation: _t('Heat'),
          extraValues: <SellerExtras>[
            _extra('1', '1', 'Mild'),
            _extra('2', '1', 'Medium'),
            _extra('3', '1', 'Hot'),
          ],
        ),
        SellerExtrasGroup(
          id: '2',
          shopId: '1',
          type: 'text',
          translation: _t('Portion'),
          extraValues: <SellerExtras>[
            _extra('4', '2', 'Regular'),
            _extra('5', '2', 'Large'),
          ],
        ),
      ];

  /// Session-local overlays, seeded lazily on first read and mutated in place
  /// by the write methods below for the rest of the session.
  static List<SellerProductData>? _products;
  static List<SellerProductData>? _addons;
  static List<SellerExtrasGroup>? _groups;

  static List<SellerProductData> get _allProducts =>
      _products ??= _seedProducts();

  static List<SellerProductData> get _allAddons => _addons ??= _seedAddons();

  static List<SellerExtrasGroup> get _allGroups => _groups ??= _seedGroups();

  /// Drops the overlays so the next read re-seeds; used by tests.
  static void reset() {
    _products = null;
    _addons = null;
    _groups = null;
  }

  @override
  Future<ApiResult<SellerProductsPaginateResponse>> getProducts({
    int? page,
    String? query,
    String? categoryId,
    bool needAddons = false,
    String? status,
  }) async {
    // Page 2 and beyond are empty: the whole seed fits on the first page, so
    // the list notifiers stop paging after it.
    if ((page ?? 1) > 1) {
      return ApiResult<SellerProductsPaginateResponse>.success(
        data: SellerProductsPaginateResponse(
          data: const <SellerProductData>[],
          meta: Meta(total: 0),
        ),
      );
    }
    Iterable<SellerProductData> rows =
        needAddons ? _allAddons : _allProducts;
    if (categoryId != null && categoryId.isNotEmpty) {
      rows = rows.where(
        (SellerProductData product) => product.categoryId == categoryId,
      );
    }
    if (status != null && status.isNotEmpty) {
      rows = rows.where(
        (SellerProductData product) => product.status == status,
      );
    }
    if (query != null && query.trim().isNotEmpty) {
      final String needle = query.trim().toLowerCase();
      rows = rows.where(
        (SellerProductData product) =>
            (product.translation?.title ?? '').toLowerCase().contains(needle),
      );
    }
    final List<SellerProductData> matched = rows.toList();
    return ApiResult<SellerProductsPaginateResponse>.success(
      data: SellerProductsPaginateResponse(
        data: matched,
        meta: Meta(total: matched.length),
      ),
    );
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> getProductDetails(
    String uuid,
  ) async {
    for (final SellerProductData product in <SellerProductData>[
      ..._allProducts,
      ..._allAddons,
    ]) {
      if (product.uuid == uuid || product.id == uuid) {
        return ApiResult<SingleSellerProductResponse>.success(
          data: SingleSellerProductResponse(data: product),
        );
      }
    }
    // Unknown uuid: hand back the first seeded product rather than an error,
    // so a deep link taken during a tour can never dead-end on a failure.
    return ApiResult<SingleSellerProductResponse>.success(
      data: SingleSellerProductResponse(data: _allProducts.first),
    );
  }

  /// Builds a product row out of the create/update form's raw payload map,
  /// falling back to the seed's shape for anything the form did not carry.
  static SellerProductData _fromForm(
    Map<String, dynamic> product, {
    required String id,
    SellerProductData? existing,
  }) {
    // The form's translation maps come through as raw literals, whose
    // runtime type may be Map<String, String> rather than
    // Map<String, dynamic> - so read them as a plain Map.
    final Map<Object?, Object?> title =
        product['title'] is Map ? product['title'] as Map : const {};
    final Map<Object?, Object?> description = product['description'] is Map
        ? product['description'] as Map
        : const {};
    return SellerProductData(
      id: id,
      uuid: existing?.uuid ?? 'demo_product_$id',
      shopId: '1',
      categoryId: product['category_id']?.toString() ??
          existing?.categoryId ??
          _mains.id,
      category: existing?.category ?? _mains,
      unit: existing?.unit ?? _each,
      unitId: product['unit_id']?.toString() ?? existing?.unitId ?? _each.id,
      tax: existing?.tax ?? 0,
      active: true,
      addon: product['addon'] == true || (existing?.addon ?? false),
      status: 'published',
      minQty: existing?.minQty ?? 1,
      maxQty: existing?.maxQty ?? 20,
      locales: <String>['en'],
      translation: _t(
        (title['en'] ?? existing?.translation?.title ?? 'New product')
            .toString(),
        (description['en'] ?? existing?.translation?.description)?.toString(),
      ),
      stocks: existing?.stocks ??
          <SellerStock>[
            SellerStock(
              id: id,
              countableId: id,
              price: 0,
              quantity: 0,
              tax: 0,
              discount: 0,
              totalPrice: 0,
              sku: 'SKU-$id',
            ),
          ],
    );
  }

  /// Ids handed to rows created during the session, continuing the seed's run.
  static int _nextProductId = 7;

  @override
  Future<ApiResult<SingleSellerProductResponse>> createProduct({
    required Map<String, dynamic> product,
  }) async {
    final SellerProductData created =
        _fromForm(product, id: '${_nextProductId++}');
    if (created.addon ?? false) {
      _allAddons.insert(0, created);
    } else {
      _allProducts.insert(0, created);
    }
    return ApiResult<SingleSellerProductResponse>.success(
      data: SingleSellerProductResponse(data: created),
    );
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateProduct({
    required String uuid,
    required Map<String, dynamic> product,
  }) async {
    for (final List<SellerProductData> bucket in <List<SellerProductData>>[
      _allProducts,
      _allAddons,
    ]) {
      for (int i = 0; i < bucket.length; i++) {
        if (bucket[i].uuid == uuid || bucket[i].id == uuid) {
          final SellerProductData updated = _fromForm(
            product,
            id: bucket[i].id ?? uuid,
            existing: bucket[i],
          );
          bucket[i] = updated;
          return ApiResult<SingleSellerProductResponse>.success(
            data: SingleSellerProductResponse(data: updated),
          );
        }
      }
    }
    return getProductDetails(uuid);
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateStocks({
    required String uuid,
    required List<Map<String, dynamic>> stocks,
    List<String> deletedStockIds = const [],
    bool isAddon = false,
  }) async {
    final List<SellerStock> replacement = <SellerStock>[];
    for (int i = 0; i < stocks.length; i++) {
      final Map<String, dynamic> row = stocks[i];
      final num price = row['price'] is num
          ? row['price'] as num
          : num.tryParse('${row['price']}') ?? 0;
      final int quantity = row['quantity'] is int
          ? row['quantity'] as int
          : int.tryParse('${row['quantity']}') ?? 0;
      replacement.add(
        SellerStock(
          id: row['id']?.toString() ?? '${i + 1}',
          countableId: uuid,
          price: price,
          quantity: quantity,
          tax: 0,
          discount: 0,
          totalPrice: price,
          sku: row['sku']?.toString(),
        ),
      );
    }
    for (final List<SellerProductData> bucket in <List<SellerProductData>>[
      _allProducts,
      _allAddons,
    ]) {
      for (int i = 0; i < bucket.length; i++) {
        if (bucket[i].uuid == uuid || bucket[i].id == uuid) {
          bucket[i] = bucket[i].copyWith(stocks: replacement);
          return ApiResult<SingleSellerProductResponse>.success(
            data: SingleSellerProductResponse(data: bucket[i]),
          );
        }
      }
    }
    return getProductDetails(uuid);
  }

  @override
  Future<ApiResult<SingleSellerProductResponse>> updateExtras({
    required String productUuid,
    required List<Map<String, dynamic>> extras,
  }) async {
    // Extras ride on stocks in the real payload; the demo menu keeps its
    // seeded stocks and simply acknowledges the save.
    return getProductDetails(productUuid);
  }

  @override
  Future<ApiResult<SellerExtrasGroupsResponse>> getExtrasGroups({
    int? page,
    bool needOnlyValid = true,
  }) async {
    if ((page ?? 1) > 1) {
      return ApiResult<SellerExtrasGroupsResponse>.success(
        data: SellerExtrasGroupsResponse(data: const <SellerExtrasGroup>[]),
      );
    }
    final List<SellerExtrasGroup> rows = needOnlyValid
        ? _allGroups
            .where((SellerExtrasGroup group) =>
                (group.extraValues ?? <SellerExtras>[]).isNotEmpty)
            .toList()
        : List<SellerExtrasGroup>.from(_allGroups);
    return ApiResult<SellerExtrasGroupsResponse>.success(
      data: SellerExtrasGroupsResponse(data: rows),
    );
  }

  @override
  Future<ApiResult<SellerGroupExtrasResponse>> getExtras({
    required String groupId,
  }) async {
    for (final SellerExtrasGroup group in _allGroups) {
      if (group.id == groupId) {
        return ApiResult<SellerGroupExtrasResponse>.success(
          data: SellerGroupExtrasResponse(data: group),
        );
      }
    }
    return ApiResult<SellerGroupExtrasResponse>.success(
      data: SellerGroupExtrasResponse(data: _allGroups.first),
    );
  }

  /// Ids handed to groups and extras created during the session.
  static int _nextGroupId = 3;
  static int _nextExtraId = 6;

  static SellerExtrasGroup _groupFromForm(
    Map<String, dynamic> group, {
    required String id,
    SellerExtrasGroup? existing,
  }) {
    final Map<Object?, Object?> title =
        group['title'] is Map ? group['title'] as Map : const {};
    return SellerExtrasGroup(
      id: id,
      shopId: '1',
      type: group['type']?.toString() ?? existing?.type ?? 'text',
      translation: _t(
        (title['en'] ?? existing?.translation?.title ?? 'New group').toString(),
      ),
      extraValues: existing?.extraValues ?? <SellerExtras>[],
    );
  }

  @override
  Future<ApiResult<SingleSellerExtrasGroupResponse>> createExtrasGroup({
    required Map<String, dynamic> group,
  }) async {
    final SellerExtrasGroup created =
        _groupFromForm(group, id: '${_nextGroupId++}');
    _allGroups.add(created);
    return ApiResult<SingleSellerExtrasGroupResponse>.success(
      data: SingleSellerExtrasGroupResponse(data: created),
    );
  }

  @override
  Future<ApiResult<SingleSellerExtrasGroupResponse>> updateExtrasGroup({
    required String groupId,
    required Map<String, dynamic> group,
  }) async {
    for (int i = 0; i < _allGroups.length; i++) {
      if (_allGroups[i].id == groupId) {
        _allGroups[i] = _groupFromForm(
          group,
          id: groupId,
          existing: _allGroups[i],
        );
        return ApiResult<SingleSellerExtrasGroupResponse>.success(
          data: SingleSellerExtrasGroupResponse(data: _allGroups[i]),
        );
      }
    }
    return ApiResult<SingleSellerExtrasGroupResponse>.success(
      data: SingleSellerExtrasGroupResponse(data: _allGroups.first),
    );
  }

  @override
  Future<ApiResult<void>> deleteExtrasGroup({required String groupId}) async {
    _allGroups.removeWhere((SellerExtrasGroup group) => group.id == groupId);
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<CreateSellerExtrasResponse>> createExtrasItem({
    required Map<String, dynamic> item,
  }) async {
    final String groupId =
        item['extra_group_id']?.toString() ?? _allGroups.first.id ?? '1';
    final SellerExtras created = _extra(
      '${_nextExtraId++}',
      groupId,
      item['value']?.toString() ?? 'New value',
    );
    for (int i = 0; i < _allGroups.length; i++) {
      if (_allGroups[i].id == groupId) {
        _allGroups[i] = _allGroups[i].copyWith(
          extraValues: <SellerExtras>[
            ...?_allGroups[i].extraValues,
            created,
          ],
        );
        break;
      }
    }
    return ApiResult<CreateSellerExtrasResponse>.success(
      data: CreateSellerExtrasResponse(data: created),
    );
  }

  @override
  Future<ApiResult<CreateSellerExtrasResponse>> updateExtrasItem({
    required String extrasId,
    required Map<String, dynamic> item,
  }) async {
    SellerExtras? updated;
    for (int i = 0; i < _allGroups.length; i++) {
      final List<SellerExtras> values = List<SellerExtras>.from(
          _allGroups[i].extraValues ?? <SellerExtras>[]);
      for (int j = 0; j < values.length; j++) {
        if (values[j].id == extrasId) {
          updated = _extra(
            extrasId,
            _allGroups[i].id ?? '1',
            item['value']?.toString() ?? values[j].value ?? '',
          );
          values[j] = updated;
          _allGroups[i] = _allGroups[i].copyWith(extraValues: values);
          break;
        }
      }
      if (updated != null) break;
    }
    return ApiResult<CreateSellerExtrasResponse>.success(
      data: CreateSellerExtrasResponse(
        data: updated ?? _extra(extrasId, '1', 'New value'),
      ),
    );
  }

  @override
  Future<ApiResult<void>> deleteExtrasItem({
    required List<String> ids,
  }) async {
    for (int i = 0; i < _allGroups.length; i++) {
      final List<SellerExtras> values = List<SellerExtras>.from(
          _allGroups[i].extraValues ?? <SellerExtras>[]);
      values.removeWhere((SellerExtras extra) => ids.contains(extra.id));
      _allGroups[i] = _allGroups[i].copyWith(extraValues: values);
    }
    return const ApiResult.success(data: null);
  }
}
