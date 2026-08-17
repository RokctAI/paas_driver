import 'package:base_sdk/src/domain/interface/categories.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class CategoriesRepository implements CategoriesRepositoryFacade {
  /// Universal platform gateway (fleet rule 2026-08-15): category cmds are
  /// the products module's `manifest.json` whitelisted-method keys with the
  /// app segment dropped (`api.category.*`).
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getAllCategories({
    required int page,
    String? shopId,
  }) async {
    final params = {
      'limit_start': (page - 1) * 10,
      'limit_page_length': 10,
      if (shopId != null) 'shop_id': shopId,
    };

    try {
      final response = await _gateway.call(
        'api.category.get_categories',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> searchCategories({
    required String text,
  }) async {
    final params = {'search': text};
    try {
      final response = await _gateway.call(
        'api.category.search_categories',
        payload: params,
        requireAuth: false,
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getCategoriesByShop({
    required String shopId,
  }) async {
    return getAllCategories(page: 1, shopId: shopId);
  }
}
