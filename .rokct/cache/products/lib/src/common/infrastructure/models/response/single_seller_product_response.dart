import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

class SingleSellerProductResponse {
  SingleSellerProductResponse({SellerProductData? data}) {
    _data = data;
  }

  SingleSellerProductResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? SellerProductData.fromJson(json['data']) : null;
  }

  SellerProductData? _data;

  SingleSellerProductResponse copyWith({SellerProductData? data}) =>
      SingleSellerProductResponse(data: data ?? _data);

  SellerProductData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
