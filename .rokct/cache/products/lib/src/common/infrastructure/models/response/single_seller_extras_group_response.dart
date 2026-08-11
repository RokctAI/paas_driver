import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';

class SingleSellerExtrasGroupResponse {
  SingleSellerExtrasGroupResponse({SellerExtrasGroup? data}) {
    _data = data;
  }

  SingleSellerExtrasGroupResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? SellerExtrasGroup.fromJson(json['data']) : null;
  }

  SellerExtrasGroup? _data;

  SingleSellerExtrasGroupResponse copyWith({SellerExtrasGroup? data}) =>
      SingleSellerExtrasGroupResponse(data: data ?? _data);

  SellerExtrasGroup? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
