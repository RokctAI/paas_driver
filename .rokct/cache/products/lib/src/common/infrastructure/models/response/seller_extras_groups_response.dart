import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';

class SellerExtrasGroupsResponse {
  SellerExtrasGroupsResponse({List<SellerExtrasGroup>? data}) {
    _data = data;
  }

  SellerExtrasGroupsResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(SellerExtrasGroup.fromJson(v));
      });
    }
  }

  List<SellerExtrasGroup>? _data;

  SellerExtrasGroupsResponse copyWith({List<SellerExtrasGroup>? data}) =>
      SellerExtrasGroupsResponse(data: data ?? _data);

  List<SellerExtrasGroup>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
