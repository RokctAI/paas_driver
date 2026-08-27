// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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


import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:base_sdk/src/models/models.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(true) bool isCategoryLoading,
    @Default(true) bool isBannerLoading,
    @Default(true) bool isShopLoading,
    @Default(true) bool isAllShopsLoading,
    @Default(true) bool isNewShopsLoading,
    @Default(true) bool isStoryLoading,
    @Default(true) bool isShopRecommendLoading,
    @Default([]) List<ProductData> discountProducts,
    @Default(true) bool isDiscountProductsLoading,
    @Default(-1) int totalShops,
    @Default(-1) int selectIndexCategory,
    @Default(-1) int selectIndexSubCategory,
    @Default(0) int isSelectCategoryLoading,
    @Default(null) AddressNewModel? addressData,
    @Default([]) List<CategoryData> categories,
    @Default([]) List<BannerData> banners,
    @Default([]) List<BannerData> ads,
    @Default(null) BannerData? banner,
    @Default([]) List<ShopData> shops,
    @Default([]) List<ShopData> allShops,
    @Default([]) List<ShopData> newShops,
    @Default([]) List<List<StoryModel?>?>? story,
    @Default([]) List<ShopData> shopsRecommend,
    @Default([]) List<ShopData> filterShops,
    @Default([]) List<ShopData> filterMarket,
    @Default([]) List<BrandData> brands,
  }) = _HomeState;

  const HomeState._();
}
