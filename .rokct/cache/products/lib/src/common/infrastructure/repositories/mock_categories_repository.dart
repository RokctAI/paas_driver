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

import 'package:base_sdk/src/constants/demo_images.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/categories.dart';
import 'package:base_sdk/src/models/response/categories_paginate_response.dart';
import 'package:base_sdk/src/models/data/translation.dart';

class MockCategoriesRepository implements CategoriesRepositoryFacade {
  final CategoryData _demoCategory = CategoryData(
    id: "1",
    uuid: "demo_cat_1",
    keywords: "burger, fast food",
    parentId: "0",
    type: "main",
    img: DemoImages.category,
    active: true,
    translation: Translation(
      title: "Burgers",
      description: "Delicious burgers",
      locale: "en",
    ),
  );

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getAllCategories({
    required int page,
  }) async {
    return ApiResult.success(
      data: CategoriesPaginateResponse(
        data: [
          _demoCategory,
          _demoCategory.copyWith(
            id: "2",
            uuid: "demo_cat_2",
            translation: Translation(title: "Pizza"),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getCategoriesByShop({
    required String shopId,
  }) async {
    return ApiResult.success(
      data: CategoriesPaginateResponse(
        data: [
          _demoCategory,
          _demoCategory.copyWith(
            id: "2",
            uuid: "demo_cat_2",
            translation: Translation(title: "Drinks"),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> searchCategories({
    required String text,
  }) async {
    return ApiResult.success(
      data: CategoriesPaginateResponse(data: [_demoCategory]),
    );
  }
}
