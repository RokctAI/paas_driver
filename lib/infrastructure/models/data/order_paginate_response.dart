

import '../data/meta.dart';
import 'order_detail.dart';

class OrderPaginateResponse {
  OrderPaginateResponse({
    List<OrderDetailData>? data,
    Meta? meta,
  }) {
    _data = data;
    _meta = meta;
  }

  OrderPaginateResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(OrderDetailData.fromJson(v));
      });
    }
    _meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
  }

  List<OrderDetailData>? _data;
  Meta? _meta;

  OrderPaginateResponse copyWith({
    List<OrderDetailData>? data,
    Meta? meta,
  }) =>
      OrderPaginateResponse(
        data: data ?? _data,
        meta: meta ?? _meta,
      );

  List<OrderDetailData>? get data => _data;

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
