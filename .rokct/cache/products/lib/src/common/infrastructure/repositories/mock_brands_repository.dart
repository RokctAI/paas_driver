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
