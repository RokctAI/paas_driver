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
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:products_sdk/src/common/domain/interface/seller_catalog.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_categories_paginate_response.dart';
import 'package:products_sdk/src/common/infrastructure/models/response/seller_units_paginate_response.dart';

/// Demo-only [SellerCatalogRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// serves the fictional shop's categories and units from memory, so the
/// manager foods tab's category strip and the create-product form's unit
/// picker are populated in demo builds. Selected in place of
/// [SellerCatalogRepository] by `ProductsSdkDependencies`, the same
/// `AppConstants.isDemo` ternary this SDK already applies to its
/// customer-facing facades.
///
/// The categories deliberately match the ones
/// [DemoSellerProductsRepository]'s menu files its dishes under, so the strip
/// and the list agree. Never used in production; nothing leaves the device
/// and nothing is persisted — session-local edits reset on the next launch.
class DemoSellerCatalogRepository implements SellerCatalogRepositoryFacade {
  static Translation _t(String title) =>
      Translation(title: title, locale: 'en');

  static SellerCategoryData _category(
    String id,
    String title, {
    String type = 'main',
    bool active = true,
  }) =>
      SellerCategoryData(
        id: id,
        uuid: 'demo_category_$id',
        shopId: '1',
        type: type,
        active: active,
        status: 'published',
        translation: _t(title),
      );

  static List<SellerCategoryData> _seedCategories() => <SellerCategoryData>[
        _category('1', 'Mains'),
        _category('2', 'Sides'),
        _category('3', 'Drinks'),
      ];

  /// Sub-shop categories (`type: sub_shop`) — the second axis the shop's own
  /// management list offers.
  static List<SellerCategoryData> _seedSubCategories() =>
      <SellerCategoryData>[
        _category('4', 'Breakfast', type: 'sub_shop'),
        _category('5', 'Late night', type: 'sub_shop'),
      ];

  static List<SellerUnitData> _seedUnits() => <SellerUnitData>[
        SellerUnitData(
          id: '1',
          active: true,
          position: 'after',
          translation: _t('each'),
          locales: <String>['en'],
        ),
        SellerUnitData(
          id: '2',
          active: true,
          position: 'after',
          translation: _t('plate'),
          locales: <String>['en'],
        ),
        SellerUnitData(
          id: '3',
          active: true,
          position: 'after',
          translation: _t('kg'),
          locales: <String>['en'],
        ),
      ];

  /// Session-local overlays, seeded lazily on first read.
  static List<SellerCategoryData>? _categories;
  static List<SellerCategoryData>? _subCategories;
  static List<SellerUnitData>? _units;

  static List<SellerCategoryData> get _allCategories =>
      _categories ??= _seedCategories();

  static List<SellerCategoryData> get _allSubCategories =>
      _subCategories ??= _seedSubCategories();

  static List<SellerUnitData> get _allUnits => _units ??= _seedUnits();

  /// Drops the overlays so the next read re-seeds; used by tests.
  static void reset() {
    _categories = null;
    _subCategories = null;
    _units = null;
  }

  /// Ids handed to categories created during the session.
  static int _nextCategoryId = 6;

  static List<SellerCategoryData> _filter(
    List<SellerCategoryData> rows,
    int? page,
    String? query,
  ) {
    // Page 2 and beyond are empty: the whole seed fits on the first page, so
    // the list notifiers stop paging after it.
    if ((page ?? 1) > 1) return const <SellerCategoryData>[];
    if (query == null || query.trim().isEmpty) {
      return List<SellerCategoryData>.from(rows);
    }
    final String needle = query.trim().toLowerCase();
    return rows
        .where((SellerCategoryData category) =>
            (category.translation?.title ?? '')
                .toLowerCase()
                .contains(needle))
        .toList();
  }

  @override
  Future<ApiResult<SellerUnitsPaginateResponse>> getUnits() async {
    return ApiResult<SellerUnitsPaginateResponse>.success(
      data: SellerUnitsPaginateResponse(data: _allUnits),
    );
  }

  @override
  Future<ApiResult<SellerCategoriesPaginateResponse>> getCategories({
    int? page,
    String? query,
  }) async {
    // `type: main`, active only.
    return ApiResult<SellerCategoriesPaginateResponse>.success(
      data: SellerCategoriesPaginateResponse(
        data: _filter(
          _allCategories
              .where((SellerCategoryData c) => c.active ?? false)
              .toList(),
          page,
          query,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<SellerCategoriesPaginateResponse>> getShopCategories({
    int? page,
    String? query,
  }) async {
    // `type: main`, no active filter — the management list.
    return ApiResult<SellerCategoriesPaginateResponse>.success(
      data: SellerCategoriesPaginateResponse(
        data: _filter(_allCategories, page, query),
      ),
    );
  }

  @override
  Future<ApiResult<SellerCategoriesPaginateResponse>> getCategoriesSub({
    int? page,
    String? query,
  }) async {
    return ApiResult<SellerCategoriesPaginateResponse>.success(
      data: SellerCategoriesPaginateResponse(
        data: _filter(
          _allSubCategories
              .where((SellerCategoryData c) => c.active ?? false)
              .toList(),
          page,
          query,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<void>> createCategory({
    required String title,
    required String input,
  }) async {
    _allCategories.add(_category('${_nextCategoryId++}', title));
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<void>> deleteCategory({required String id}) async {
    bool matches(SellerCategoryData category) =>
        category.uuid == id || category.id == id;
    _allCategories.removeWhere(matches);
    _allSubCategories.removeWhere(matches);
    return const ApiResult.success(data: null);
  }
}
