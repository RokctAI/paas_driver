import '../data/product_data.dart';

class SingleProductResponse {
  SingleProductResponse({ProductData? data}) {
    _data = data;
  }

  SingleProductResponse.fromJson(dynamic json) {
    _data = json['data'] != null ? ProductData.fromJson(json['data']) : null;
  }

  ProductData? _data;

  SingleProductResponse copyWith({ProductData? data}) =>
      SingleProductResponse(data: data ?? _data);

  ProductData? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }
}
