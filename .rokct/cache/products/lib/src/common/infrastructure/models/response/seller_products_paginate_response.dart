

import 'package:base_sdk/src/models/data/meta.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

class SellerProductsPaginateResponse {
  SellerProductsPaginateResponse({List<SellerProductData>? data, Meta? meta}) {
    _data = data;
    _meta = meta;
  }

  SellerProductsPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(SellerProductData.fromJson(v));
      });
    }
    _meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  List<SellerProductData>? _data;
  Meta? _meta;

  SellerProductsPaginateResponse copyWith({List<SellerProductData>? data, Meta? meta}) =>
      SellerProductsPaginateResponse(data: data ?? _data, meta: meta ?? _meta);

  List<SellerProductData>? get data => _data;

  Meta? get meta => _meta;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    if (_meta != null) {
      map['meta'] = _meta?.toJson();
    }
    return map;
  }
}
