import 'package:flutter/material.dart';
import 'package:base_sdk/src/domain/interface/currencies.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

class CurrenciesRepository implements CurrenciesRepositoryFacade {
  static const _gateway = PlatformGateway();

  @override
  Future<ApiResult<CurrenciesResponse>> getCurrencies() async {
    try {
      final data = await _gateway.call(
        'api.system.get_currencies',
        requireAuth: false,
      );
      return ApiResult.success(
        data: CurrenciesResponse.fromJson(data),
      );
    } catch (e) {
      debugPrint('==> get currencies failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}
