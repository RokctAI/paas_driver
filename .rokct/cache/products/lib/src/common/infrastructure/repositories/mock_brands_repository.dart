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
import 'package:base_sdk/src/domain/interface/brands.dart';
import 'package:base_sdk/src/models/data/brand_data.dart';
import 'package:base_sdk/src/models/response/brands_paginate_response.dart';
import 'package:base_sdk/src/models/response/single_brand_response.dart';

class MockBrandsRepository implements BrandsRepositoryFacade {
  final BrandData _demoBrand = BrandData(
    id: "1",
    title: "Karoo Grill Co.",
    img: DemoImages.shopMark,
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
          _demoBrand.copyWith(id: "2", title: "Highveld Dairy"),
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
