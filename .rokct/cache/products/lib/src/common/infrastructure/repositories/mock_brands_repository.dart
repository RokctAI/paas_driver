import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/brands.dart';
import 'package:base_sdk/src/models/data/brand_data.dart';
import 'package:base_sdk/src/models/response/brands_paginate_response.dart';
import 'package:base_sdk/src/models/response/single_brand_response.dart';

class MockBrandsRepository implements BrandsRepositoryFacade {
  final BrandData _demoBrand = BrandData(
    id: "1",
    title: "Demo Brand",
    img: "https://via.placeholder.com/150",
    active: true,
    createdAt: DateTime.now().toString(),
    updatedAt: DateTime.now().toString(),
  );

  @override
  Future<ApiResult<BrandsPaginateResponse>> getAllBrands({
    String? categoryId,
    String? shopId,
  }) async {
    return ApiResult.success(
      data: BrandsPaginateResponse(
        data: [
          _demoBrand,
          _demoBrand.copyWith(id: "2", title: "Another Brand"),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<BrandsPaginateResponse>> getBrandsPaginate(int page) async {
    return ApiResult.success(data: BrandsPaginateResponse(data: [_demoBrand]));
  }

  @override
  Future<ApiResult<SingleBrandResponse>> getSingleBrand(String uuid) async {
    return ApiResult.success(data: SingleBrandResponse(data: _demoBrand));
  }

  @override
  Future<ApiResult<BrandsPaginateResponse>> searchBrands(String query) async {
    return ApiResult.success(data: BrandsPaginateResponse(data: [_demoBrand]));
  }
}
