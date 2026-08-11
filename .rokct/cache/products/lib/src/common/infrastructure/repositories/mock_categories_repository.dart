import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/categories.dart';
// import 'package:foodyman/infrastructure/models/data/category_data.dart'; // Removed invalid import
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
