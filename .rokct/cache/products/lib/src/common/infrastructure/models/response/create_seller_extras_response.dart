import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';

class CreateSellerExtrasResponse {
  CreateSellerExtrasResponse({SellerExtras? data}) {
    _data = data;
  }

  CreateSellerExtrasResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? SellerExtras.fromJson(json['data']) : null;
  }

  SellerExtras? _data;

  CreateSellerExtrasResponse copyWith({SellerExtras? data}) =>
      CreateSellerExtrasResponse(data: data ?? _data);

  SellerExtras? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
