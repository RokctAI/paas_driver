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
    img: "https://via.placeholder.com/150",
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
