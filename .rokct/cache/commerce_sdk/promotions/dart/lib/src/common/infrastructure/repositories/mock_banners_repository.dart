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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/banners.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/models/response/banners_paginate_response.dart';

class MockBannersRepository implements BannersRepositoryFacade {
  final BannerData _demoBanner = BannerData(
    id: '1',
    shops: [
      ShopData(
        id: "demo_shop_1",
        translation: Translation(title: "Demo Pizza Shop"),
      ),
    ],
    img: "https://via.placeholder.com/800x400",
    active: true,
    translation: Translation(
      title: "Demo Offer",
      description: "Get 50% off on all items!",
      locale: "en",
    ),
    createdAt: DateTime.now().toString(),
    updatedAt: DateTime.now().toString(),
  );

  @override
  Future<ApiResult<BannerData>> getAdsById(String bannerId) async {
    return ApiResult.success(data: _demoBanner);
  }

  @override
  Future<ApiResult<BannersPaginateResponse>> getAdsPaginate({
    required int page,
  }) async {
    return ApiResult.success(
      data: BannersPaginateResponse(data: [_demoBanner]),
    );
  }

  @override
  Future<ApiResult<BannerData>> getBannerById(String bannerId) async {
    return ApiResult.success(data: _demoBanner);
  }

  @override
  Future<ApiResult<BannersPaginateResponse>> getBannersPaginate({
    required int page,
  }) async {
    return ApiResult.success(
      data: BannersPaginateResponse(
        data: [
          _demoBanner,
          _demoBanner.copyWith(
            id: '2',
            translation: Translation(title: "New Arrivals"),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<void>> likeBanner(String bannerId) async {
    return ApiResult.success(data: null);
  }
}
