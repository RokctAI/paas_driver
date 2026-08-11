import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';

class SellerGroupExtrasResponse {
  SellerGroupExtrasResponse({SellerExtrasGroup? data}) {
    _data = data;
  }

  SellerGroupExtrasResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? SellerExtrasGroup.fromJson(json['data']) : null;
  }

  SellerExtrasGroup? _data;

  SellerGroupExtrasResponse copyWith({SellerExtrasGroup? data}) =>
      SellerGroupExtrasResponse(data: data ?? _data);

  SellerExtrasGroup? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
