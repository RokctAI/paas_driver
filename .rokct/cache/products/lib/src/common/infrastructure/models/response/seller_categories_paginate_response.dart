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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';

/// Named `Seller*` because base_sdk already has a `CategoriesPaginateResponse`
/// over a different `CategoryData` (measured 27.9% similar).
class SellerCategoriesPaginateResponse {
  SellerCategoriesPaginateResponse({List<SellerCategoryData>? data}) {
    _data = data;
  }

  /// Frappe returns whitelisted payloads under `message`; the legacy shape used
  /// `data`. Accept either.
  SellerCategoriesPaginateResponse.fromJson(dynamic json) {
    final dynamic payload =
        (json is Map) ? (json['message'] ?? json['data']) : json;
    final dynamic rows =
        (payload is Map) ? (payload['data'] ?? payload) : payload;
    if (rows is List) {
      _data = rows
          .map((v) =>
              SellerCategoryData.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList();
    }
  }

  List<SellerCategoryData>? _data;

  SellerCategoriesPaginateResponse copyWith({List<SellerCategoryData>? data}) =>
      SellerCategoriesPaginateResponse(data: data ?? _data);

  List<SellerCategoryData>? get data => _data;

  Map<String, dynamic> toJson() => {
        if (_data != null) 'data': _data?.map((v) => v.toJson()).toList(),
      };
}
