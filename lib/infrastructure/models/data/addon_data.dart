import 'order_detail.dart';
import 'product_data.dart';

class AddonData {
  AddonData(
      {int? id,
        int? stockId,
        int? addonId,
        int? quantity,
        num? totalPrice,
        ProductData? product,
        Stock? stock,
        bool? active}) {
    _id = id;
    _stockId = stockId;
    _addonId = addonId;
    _totalPrice = totalPrice;
    _quantity = quantity;
    _product = product;
    _stock = stock;
    _active = active;
  }

  AddonData.fromJson(dynamic json) {
    _id = json['id'];
    _stockId = json['stock_id'];
    _addonId = json['addon_id'];
    _quantity = json['quantity'];
    _totalPrice = json["total_price"];
    _stock = json['stock'] != null ? Stock.fromJson(json['stock']) : null;
    _product =
    json['product'] != null ? ProductData.fromJson(json['product']) : null;
  }

  int? _id;
  int? _stockId;
  int? _addonId;
  int? _quantity;
  bool? _active;
  num? _totalPrice;
  ProductData? _product;
  Stock? _stock;

  AddonData copyWith({
    int? id,
    int? stockId,
    int? addonId,
    int? quantity,
    bool? active,
    num? totalPrice,
    Stock? stock,
    ProductData? product,
  }) =>
      AddonData(
        id: id ?? _id,
        stockId: stockId ?? _stockId,
        addonId: addonId ?? _addonId,
        quantity: quantity ?? _quantity,
        totalPrice: totalPrice ?? _totalPrice,
        stock: stock ?? _stock,
        active: active ?? _active,
        product: product ?? _product,
      );

  int? get id => _id;

  int? get stockId => _stockId;

  int? get addonId => _addonId;

  int? get quantity => _quantity;

  bool? get active => _active;

  set setActive(bool active) => _active = active;

  set setCount(int count) => _quantity = count;

  num? get totalPrice => _totalPrice;

  ProductData? get product => _product;

  Stock? get stock => _stock;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['stock_id'] = _stockId;
    map['addon_id'] = _addonId;
    if (_product != null) {
      map['product'] = _product?.toJson();
    }
    return map;
  }
}