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
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/constants/demo_images.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/models/response/shops_paginate_response.dart';
import 'package:base_sdk/src/models/response/single_shop_response.dart';
import 'package:base_sdk/src/models/data/filter_model.dart';
import 'package:base_sdk/src/models/response/branches_response.dart';
import 'package:base_sdk/src/models/data/address_new_data.dart';
import 'package:base_sdk/src/models/data/story_data.dart';
import 'package:base_sdk/src/models/response/tag_response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MockShopsRepository implements ShopsRepositoryFacade {
  /// The fictional shop every demo surface shares - the demo tenant's own
  /// shop. Public and static so the manager side can serve the SAME
  /// identity: merchants_sdk's own `DemoSellerShopRepository` (this SDK,
  /// `manager/`) hands it to the restaurant hub, so the shop a demo build
  /// browses and the shop a demo manager runs are one shop rather than two
  /// inventions. [demoShopSecond] below exists only to populate the lists;
  /// nothing serves it as "the" demo shop.
  static final ShopData demoShop = _seedShop(
    id: "1",
    title: "Corner Kitchen",
    description: "Flame-grilled favourites, ready in minutes",
    address: "42 Marula Avenue, Sandton",
    backgroundImg: DemoImages.shopCover,
    logoImg: DemoImages.shopMark,
    sellerFirstName: "Thandi",
    sellerLastName: "Mokoena",
    avgRate: "4.5",
    rateCount: "120",
  );

  /// A second fictional shop, so every screen that lists more than one shop
  /// (browse-all, category filter, search) shows a list rather than the same
  /// card twice - which is exactly how the marketing captures used to read.
  static final ShopData demoShopSecond = _seedShop(
    id: "2",
    title: "Nonna's Pizzeria",
    description: "Wood-fired pizza, hand-stretched every morning",
    address: "8 Oak Lane, Parkhurst",
    backgroundImg: DemoImages.promoBanner,
    logoImg: DemoImages.category,
    sellerFirstName: "Marco",
    sellerLastName: "Bianchi",
    avgRate: "4.8",
    rateCount: "86",
  );

  /// The one shape both demo shops share. Only the identity fields differ,
  /// so a change to the demo shop's economics (tax, delivery, hours) reaches
  /// both without being retyped.
  static ShopData _seedShop({
    required String id,
    required String title,
    required String description,
    required String address,
    required String backgroundImg,
    required String logoImg,
    required String sellerFirstName,
    required String sellerLastName,
    required String avgRate,
    required String rateCount,
  }) =>
      ShopData(
        id: id,
        userId: id,
        tax: 10,
        pricePerKm: 5,
        minPrice: 10,
        percentage: 15,
        phone: "+27 11 000 0000",
        visibility: true,
        openTime: "09:00",
        open: true,
        verify: true,
        closeTime: "22:00",
        backgroundImg: backgroundImg,
        logoImg: logoImg,
        minAmount: 50,
        status: "approved",
        type: "restaurant",
        // from -> to, in that order: the shop cards render it as
        // "$from - $to min", so the old to:"30"/from:"45" pair printed the
        // window backwards ("45 - 30 min") in every capture.
        deliveryTime: DeliveryTime(from: "30", to: "45", type: "min"),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Johannesburg - the same city the demo delivery address sits in
        // (the tour seeds -26.2041, 28.0473), so the map and the address
        // agree with each other.
        location: Location(latitude: -26.2041, longitude: 28.0473),
        productsCount: 100,
        translation: Translation(
          title: title,
          description: description,
          address: address,
        ),
        locales: ["en"],
        seller: Seller(
          id: id,
          firstname: sellerFirstName,
          lastname: sellerLastName,
          active: true,
          role: "seller",
        ),
        avgRate: avgRate,
        rateCount: rateCount,
        enableCod: true,
      );

  @override
  Future<ApiResult<ShopsPaginateResponse>> getAllShops(
    int page, {
    String? categoryId,
    FilterModel? filterModel,
    required bool isOpen,
    bool? verify,
  }) async {
    return ApiResult.success(
      data: ShopsPaginateResponse(data: [demoShop, demoShopSecond]),
    );
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getNearbyShops(
    double latitude,
    double longitude,
  ) async {
    return ApiResult.success(data: ShopsPaginateResponse(data: [demoShop]));
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopsRecommend(int page) async {
    return ApiResult.success(data: ShopsPaginateResponse(data: [demoShop]));
  }

  @override
  Future<ApiResult<SingleShopResponse>> getSingleShop({
    required String uuid,
  }) async {
    return ApiResult.success(data: SingleShopResponse(data: demoShop));
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> searchShops({
    required String text,
    String? categoryId,
  }) async {
    return ApiResult.success(data: ShopsPaginateResponse(data: [demoShop]));
  }

  @override
  Future<ApiResult<void>> createShop({
    required double tax,
    required List<String> documents,
    required double deliveryTo,
    required double deliveryFrom,
    required String deliveryType,
    required String phone,
    required String name,
    required String category,
    required String description,
    required double startPrice,
    required double perKm,
    required AddressNewModel address,
    String? logoImage,
    String? backgroundImage,
  }) async {
    return ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getPickupShops() async {
    return ApiResult.success(data: ShopsPaginateResponse(data: [demoShop]));
  }

  @override
  Future<ApiResult<bool>> checkDriverZone(
    LatLng location, {
    String? shopId,
  }) async {
    return ApiResult.success(data: true);
  }

  @override
  Future<ApiResult<BranchResponse>> getShopBranch({
    required String uuid,
  }) async {
    return ApiResult.success(data: BranchResponse(data: []));
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopFilter({
    String? categoryId,
    required int page,
    String? subCategoryId,
  }) async {
    return ApiResult.success(data: ShopsPaginateResponse(data: [demoShop]));
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopsByIds(
    List<String> shopIds,
  ) async {
    return ApiResult.success(data: ShopsPaginateResponse(data: [demoShop]));
  }

  @override
  Future<ApiResult<List<List<StoryModel?>?>?>> getStory(int page) async {
    return ApiResult.success(data: []);
  }

  @override
  Future<ApiResult<PriceModel>> getSuggestPrice() async {
    return ApiResult.success(
      data: PriceModel(
        timestamp: DateTime.now(),
        status: true,
        message: "Success",
        data: Data(min: 10, max: 100),
      ),
    );
  }

  @override
  Future<ApiResult<TagResponse>> getTags(String categoryId) async {
    return ApiResult.success(data: TagResponse(data: []));
  }

  @override
  Future<ApiResult> joinOrder({
    required String shopId,
    required String name,
    required String cartId,
  }) async {
    return ApiResult.success(data: null);
  }
}
