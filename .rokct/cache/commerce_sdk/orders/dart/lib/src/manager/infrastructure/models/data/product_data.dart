// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'galleries.dart';
import 'kitchen_data.dart';
import 'stock.dart';
import 'unit_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'category_data.dart';

class ProductData {
  ProductData({
    String? id,
    int? cartCount,
    String? uuid,
    String? shopId,
    String? categoryId,
    num? tax,
    num? interval,
    String? barCode,
    String? status,
    bool? active,
    bool? addon,
    String? img,
    int? minQty,
    int? maxQty,
    List<String>? locales,
    Translation? translation,
    List<Translation>? translations,
    CategoryData? category,
    UnitData? unit,
    List<Stock>? stocks,
    List<Galleries>? galleries,
    Stock? stock,
    KitchenModel? kitchen,
    int? unitId,
    List<ProductDiscounts>? discounts,
    bool? isSelectedAddon,
  }) {
    _id = id;
    _kitchen = kitchen;
    _galleries = galleries;
    _cartCount = cartCount;
    _uuid = uuid;
    _shopId = shopId;
    _translations = translations;
    _categoryId = categoryId;
    _tax = tax;
    _interval = interval;
    _barCode = barCode;
    _status = status;
    _active = active;
    _addon = addon;
    _img = img;
    _minQty = minQty;
    _maxQty = maxQty;
    _locales = locales;
    _translation = translation;
    _category = category;
    _unit = unit;
    _stocks = stocks;
    _stock = stock;
    _unitId = unitId;
    _discounts = discounts;
    _isSelectedAddon = isSelectedAddon;
  }

  ProductData.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _cartCount = 0;
    _uuid = json['uuid'];
    _shopId = json['shop_id']?.toString();
    _categoryId = json['category_id']?.toString();

    // FIXED: Read tax from product level first (this is where user input is stored)
    if (json['tax'] != null) {
      _tax = json['tax'] is num ? json['tax'] : num.tryParse(json['tax'].toString());
    } else if (json['stocks'] != null && json['stocks'].isNotEmpty) {
      // Fallback to stocks only if product level tax is null
      final taxValue = json['stocks'][0]['tax'];
      if (taxValue != null) {
        if (taxValue is num) {
          _tax = taxValue;
        } else if (taxValue is String) {
          _tax = num.tryParse(taxValue);
        }
      } else {
        _tax = null;
      }
    } else {
      _tax = null;
    }

    _interval = json['interval'];
    _barCode = json['bar_code'];
    _status = json['status'];

    // FIXED: Active field parsing
    _active = json['active'] is bool ? json['active'] :
    (json['active'] == 1 || json['active'] == '1' || json['active'] == true);

    _addon = json['addon'];
    _img = json['img'];
    _minQty = int.tryParse(json['min_qty'].toString());
    _maxQty = int.tryParse(json['max_qty'].toString());
    _locales = json['locales'] != null ? json['locales'].cast<String>() : [];

    _translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
    _stock = json?["stock"] == null ? null : Stock.fromJson(json?["stock"]);
    _category = json['category'] != null
        ? CategoryData.fromJson(json['category'])
        : null;

    if (json['galleries'] != null) {
      _galleries = [];
      json['galleries'].forEach((v) {
        _galleries?.add(Galleries.fromJson(v));
      });
    }

    _unit = json['unit'] != null ? UnitData.fromJson(json['unit']) : null;
    _kitchen = json['kitchen'] != null ? KitchenModel.fromJson(json['kitchen']) : null;

    if (json['stocks'] != null) {
      _stocks = [];
      json['stocks'].forEach((v) {
        _stocks?.add(Stock.fromJson(v));
      });
    }

    _unitId = json['unit_id'];

    if (json['discounts'] != null) {
      _discounts = [];
      json['discounts'].forEach((v) {
        _discounts?.add(ProductDiscounts.fromJson(v));
      });
    }

    if (json['translations'] != null) {
      _translations = [];
      json['translations'].forEach((v) {
        _translations?.add(Translation.fromJson(v));
      });
    }

    _isSelectedAddon = false;
  }

  String? _id;
  List<Galleries>? _galleries;
  int? _cartCount;
  String? _uuid;
  String? _shopId;
  String? _categoryId;
  num? _tax;
  num? _interval;
  String? _barCode;
  String? _status;
  bool? _active;
  bool? _addon;
  String? _img;
  int? _minQty;
  int? _maxQty;
  List<String>? _locales;
  List<Translation>? _translations;
  Translation? _translation;
  CategoryData? _category;
  UnitData? _unit;
  List<Stock>? _stocks;
  Stock? _stock;
  KitchenModel? _kitchen;
  int? _unitId;
  List<ProductDiscounts>? _discounts;
  bool? _isSelectedAddon;

  ProductData copyWith({
    String? id,
    int? cartCount,
    List<Galleries>? galleries,
    String? uuid,
    String? shopId,
    String? categoryId,
    num? tax,
    num? interval,
    String? barCode,
    String? status,
    bool? active,
    bool? addon,
    String? img,
    int? minQty,
    int? maxQty,
    List<String>? locales,
    Translation? translation,
    CategoryData? category,
    UnitData? unit,
    List<Stock>? stocks,
    List<Translation>? translations,
    Stock? stock,
    int? unitId,
    List<ProductDiscounts>? discounts,
    bool? isSelectedAddon,
    KitchenModel? kitchen,
  }) =>
      ProductData(
        id: id ?? _id,
        cartCount: cartCount ?? _cartCount,
        uuid: uuid ?? _uuid,
        shopId: shopId ?? _shopId,
        categoryId: categoryId ?? _categoryId,
        tax: tax ?? _tax,
        galleries: galleries ?? _galleries,
        interval: interval ?? _interval,
        barCode: barCode ?? _barCode,
        status: status ?? _status,
        active: active ?? _active,
        addon: addon ?? _addon,
        translations: translations ?? _translations,
        img: img ?? _img,
        minQty: minQty ?? _minQty,
        maxQty: maxQty ?? _maxQty,
        locales: locales ?? _locales,
        translation: translation ?? _translation,
        category: category ?? _category,
        unit: unit ?? _unit,
        stocks: stocks ?? _stocks,
        stock: stock ?? _stock,
        unitId: unitId ?? _unitId,
        discounts: discounts ?? _discounts,
        isSelectedAddon: isSelectedAddon ?? _isSelectedAddon,
        kitchen: kitchen ?? _kitchen,
      );

  // Helper method to get effective tax (prioritizes stocks over product level)
  num? get effectiveTax {
    // Return product level tax first (this is the user input)
    if (_tax != null) {
      return _tax;
    }
    // Fallback to stocks tax only if product tax is null
    if (_stocks?.isNotEmpty == true) {
      return _stocks?.first.tax;
    }
    return null;
  }

  // Helper method to get tax as string for UI display
  String get taxDisplayValue {
    final tax = effectiveTax;
    return tax?.toString() ?? '';
  }

  String? get id => _id;
  int? get cartCount => _cartCount;
  String? get uuid => _uuid;
  String? get shopId => _shopId;
  List<Galleries>? get galleries => _galleries;
  List<Translation>? get translations => _translations;
  String? get categoryId => _categoryId;
  num? get tax => _tax;
  num? get interval => _interval;
  String? get barCode => _barCode;
  String? get status => _status;
  bool? get active => _active;
  bool? get addon => _addon;
  String? get img => _img;
  int? get minQty => _minQty;
  int? get maxQty => _maxQty;
  List<String>? get locales => _locales;
  Translation? get translation => _translation;
  CategoryData? get category => _category;
  UnitData? get unit => _unit;
  KitchenModel? get kitchen => _kitchen;
  List<Stock>? get stocks => _stocks;
  Stock? get stock => _stock;
  int? get unitId => _unitId;
  List<ProductDiscounts>? get discounts => _discounts;
  bool? get isSelectedAddon => _isSelectedAddon;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['uuid'] = _uuid;
    map['shop_id'] = _shopId;
    map['category_id'] = _categoryId;
    map['tax'] = _tax;
    map['bar_code'] = _barCode;
    map['status'] = _status;
    map['active'] = _active;
    map['img'] = _img;
    map['min_qty'] = _minQty;
    map['max_qty'] = _maxQty;
    map['locales'] = _locales;
    map['unit_id'] = _unitId;
    if (_discounts != null) {
      map['discounts'] = _discounts?.map((v) => v.toJson()).toList();
    }
    if (_translations != null) {
      map['translations'] = _translations?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class ProductDiscounts {
  ProductDiscounts({
    String? id,
    String? shopId,
    String? type,
    num? price,
    String? start,
    String? end,
    String? img,
    int? active,
    ProductPivot? pivot,
  }) {
    _id = id;
    _shopId = shopId;
    _type = type;
    _price = price;
    _start = start;
    _end = end;
    _img = img;
    _active = active;
    _pivot = pivot;
  }

  ProductDiscounts.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _shopId = json['shop_id']?.toString();
    _type = json['type'];
    _price = json['price'];
    _start = json['start'];
    _end = json['end'];
    _img = json['img'];
    _active = json['active'];
    _pivot = json['pivot'] != null ? ProductPivot.fromJson(json['pivot']) : null;
  }

  String? _id;
  String? _shopId;
  String? _type;
  num? _price;
  String? _start;
  String? _end;
  String? _img;
  int? _active;
  ProductPivot? _pivot;

  ProductDiscounts copyWith({
    String? id,
    String? shopId,
    String? type,
    num? price,
    String? start,
    String? end,
    String? img,
    int? active,
    ProductPivot? pivot,
  }) =>
      ProductDiscounts(
        id: id ?? _id,
        shopId: shopId ?? _shopId,
        type: type ?? _type,
        price: price ?? _price,
        start: start ?? _start,
        end: end ?? _end,
        img: img ?? _img,
        active: active ?? _active,
        pivot: pivot ?? _pivot,
      );

  String? get id => _id;
  String? get shopId => _shopId;
  String? get type => _type;
  num? get price => _price;
  String? get start => _start;
  String? get end => _end;
  String? get img => _img;
  int? get active => _active;
  ProductPivot? get pivot => _pivot;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['shop_id'] = _shopId;
    map['type'] = _type;
    map['price'] = _price;
    map['start'] = _start;
    map['end'] = _end;
    map['img'] = _img;
    map['active'] = _active;
    if (_pivot != null) {
      map['pivot'] = _pivot?.toJson();
    }
    return map;
  }
}

class ProductPivot {
  ProductPivot({String? productId, String? discountId}) {
    _productId = productId;
    _discountId = discountId;
  }

  ProductPivot.fromJson(dynamic json) {
    _productId = json['product_id']?.toString();
    _discountId = json['discount_id']?.toString();
  }

  String? _productId;
  String? _discountId;

  ProductPivot copyWith({String? productId, String? discountId}) => ProductPivot(
    productId: productId ?? _productId,
    discountId: discountId ?? _discountId,
  );

  String? get productId => _productId;
  String? get discountId => _discountId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['product_id'] = _productId;
    map['discount_id'] = _discountId;
    return map;
  }
}