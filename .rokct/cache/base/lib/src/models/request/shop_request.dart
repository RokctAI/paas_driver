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


import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:base_sdk/src/constants/app_constants.dart';

class ShopRequest {
  final int page;
  final int? take;
  final bool? freeDelivery;
  final bool? onlyOpen;
  final bool? deals;
  final String? rating;
  final List<double>? price;
  final String? orderBy;
  final int? categoryId;
  final bool? verify;

  ShopRequest({
    this.orderBy,
    this.price,
    this.take,
    this.freeDelivery,
    this.onlyOpen,
    this.deals,
    this.rating,
    this.categoryId,
    this.verify,
    required this.page,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (LocalStorage.getSelectedCurrency() != null)
      map["currency_id"] = LocalStorage.getSelectedCurrency()?.id;
    if (price != null) {
      for (int i = 0; i < price!.length; i++) {
        map["prices[$i]"] = price?[i];
      }
    }
    map["page"] = page;
    if (take != null) {
      map["take"] = take;
    }
    if (verify != null) {
      map["verify"] = 1;
    }
    if (categoryId != null) {
      map["category_id"] = categoryId;
    }
    if (freeDelivery != null && (freeDelivery ?? false)) {
      map["free_delivery"] = freeDelivery;
    }
    if (deals != null && (deals ?? false)) {
      map["deals"] = deals;
    }
    if (onlyOpen != null && (onlyOpen ?? false)) {
      map["open"] = 1;
    }
    if (rating != null && (rating?.isNotEmpty ?? false)) {
      if (rating!.contains("-")) {
        map["rating[0]"] = rating!.substring(0, rating!.indexOf("-"));
        map["rating[1]"] = rating!.substring(rating!.indexOf("-") + 1);
      } else {
        map["rating[0]"] = rating;
      }
    }
    if (orderBy != null && (orderBy?.isNotEmpty ?? false)) {
      map["order_by"] = AppHelpers.getOrderByString(orderBy!);
    }
    map["perPage"] = AppHelpers.getType() == 3 ? 9 : 6;
    map["lang"] = LocalStorage.getLanguage()?.locale ?? "en";
    map["address"] = {
      "latitude": LocalStorage.getAddressSelected()?.location?.latitude ??
          AppConstants.demoLatitude,
      "longitude": LocalStorage.getAddressSelected()?.location?.longitude ??
          AppConstants.demoLongitude,
    };
    return map;
  }
}
