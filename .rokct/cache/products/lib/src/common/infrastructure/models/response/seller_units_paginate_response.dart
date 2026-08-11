import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';

class SellerUnitsPaginateResponse {
  SellerUnitsPaginateResponse({List<SellerUnitData>? data}) {
    _data = data;
  }

  SellerUnitsPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(SellerUnitData.fromJson(v));
      });
    }
  }

  List<SellerUnitData>? _data;

  SellerUnitsPaginateResponse copyWith({List<SellerUnitData>? data}) =>
      SellerUnitsPaginateResponse(data: data ?? _data);

  List<SellerUnitData>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
