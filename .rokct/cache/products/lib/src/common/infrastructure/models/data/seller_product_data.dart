import 'package:products_sdk/src/common/infrastructure/models/data/seller_gallery.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';

class SellerProductData {
  SellerProductData({
    int? id,
    int? cartCount,
    String? uuid,
    int? shopId,
    int? categoryId,
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
    SellerCategoryData? category,
    SellerUnitData? unit,
    List<SellerStock>? stocks,
    List<SellerGallery>? galleries,
    SellerStock? stock,
    SellerProductKitchen? kitchen,
    int? unitId,
    List<SellerProductDiscount>? discounts,
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

  SellerProductData.fromJson(dynamic json) {
    _id = json['id'];
    _cartCount = 0;
    _uuid = json['uuid'];
    _shopId = json['shop_id'];
    _categoryId = int.tryParse(json['category_id'].toString());

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
    _stock = json?["stock"] == null ? null : SellerStock.fromJson(json?["stock"]);
    _category = json['category'] != null
        ? SellerCategoryData.fromJson(json['category'])
        : null;

    if (json['galleries'] != null) {
      _galleries = [];
      json['galleries'].forEach((v) {
        _galleries?.add(SellerGallery.fromJson(v));
      });
    }

    _unit = json['unit'] != null ? SellerUnitData.fromJson(json['unit']) : null;
    _kitchen = json['kitchen'] != null ? SellerProductKitchen.fromJson(json['kitchen']) : null;

    if (json['stocks'] != null) {
      _stocks = [];
      json['stocks'].forEach((v) {
        _stocks?.add(SellerStock.fromJson(v));
      });
    }

    _unitId = json['unit_id'];

    if (json['discounts'] != null) {
      _discounts = [];
      json['discounts'].forEach((v) {
        _discounts?.add(SellerProductDiscount.fromJson(v));
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

  int? _id;
  List<SellerGallery>? _galleries;
  int? _cartCount;
  String? _uuid;
  int? _shopId;
  int? _categoryId;
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
  SellerCategoryData? _category;
  SellerUnitData? _unit;
  List<SellerStock>? _stocks;
  SellerStock? _stock;
  SellerProductKitchen? _kitchen;
  int? _unitId;
  List<SellerProductDiscount>? _discounts;
  bool? _isSelectedAddon;

  SellerProductData copyWith({
    int? id,
    int? cartCount,
    List<SellerGallery>? galleries,
    String? uuid,
    int? shopId,
    int? categoryId,
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
    SellerCategoryData? category,
    SellerUnitData? unit,
    List<SellerStock>? stocks,
    List<Translation>? translations,
    SellerStock? stock,
    int? unitId,
    List<SellerProductDiscount>? discounts,
    bool? isSelectedAddon,
    SellerProductKitchen? kitchen,
  }) =>
      SellerProductData(
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

  int? get id => _id;
  int? get cartCount => _cartCount;
  String? get uuid => _uuid;
  int? get shopId => _shopId;
  List<SellerGallery>? get galleries => _galleries;
  List<Translation>? get translations => _translations;
  int? get categoryId => _categoryId;
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
  SellerCategoryData? get category => _category;
  SellerUnitData? get unit => _unit;
  SellerProductKitchen? get kitchen => _kitchen;
  List<SellerStock>? get stocks => _stocks;
  SellerStock? get stock => _stock;
  int? get unitId => _unitId;
  List<SellerProductDiscount>? get discounts => _discounts;
  bool? get isSelectedAddon => _isSelectedAddon;

  // Local-first sync metadata, set only on rows built from the
  // manager_products KV box (never part of the wire shape and deliberately
  // outside copyWith/toJson): [pendingSync] marks a local not-yet-synced
  // create for the list badge, [needsAttention]/[syncError] the parked
  // rejected state, [localId] the `offline:<uuid>` record key.
  String? localId;
  bool pendingSync = false;
  bool needsAttention = false;
  String? syncError;

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

class SellerProductDiscount {
  SellerProductDiscount({
    int? id,
    int? shopId,
    String? type,
    num? price,
    String? start,
    String? end,
    String? img,
    int? active,
    SellerProductPivot? pivot,
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

  SellerProductDiscount.fromJson(dynamic json) {
    _id = json['id'];
    _shopId = json['shop_id'];
    _type = json['type'];
    _price = json['price'];
    _start = json['start'];
    _end = json['end'];
    _img = json['img'];
    _active = json['active'];
    _pivot = json['pivot'] != null ? SellerProductPivot.fromJson(json['pivot']) : null;
  }

  int? _id;
  int? _shopId;
  String? _type;
  num? _price;
  String? _start;
  String? _end;
  String? _img;
  int? _active;
  SellerProductPivot? _pivot;

  SellerProductDiscount copyWith({
    int? id,
    int? shopId,
    String? type,
    num? price,
    String? start,
    String? end,
    String? img,
    int? active,
    SellerProductPivot? pivot,
  }) =>
      SellerProductDiscount(
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

  int? get id => _id;
  int? get shopId => _shopId;
  String? get type => _type;
  num? get price => _price;
  String? get start => _start;
  String? get end => _end;
  String? get img => _img;
  int? get active => _active;
  SellerProductPivot? get pivot => _pivot;

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

class SellerProductPivot {
  SellerProductPivot({int? productId, int? discountId}) {
    _productId = productId;
    _discountId = discountId;
  }

  SellerProductPivot.fromJson(dynamic json) {
    _productId = json['product_id'];
    _discountId = json['discount_id'];
  }

  int? _productId;
  int? _discountId;

  SellerProductPivot copyWith({int? productId, int? discountId}) => SellerProductPivot(
    productId: productId ?? _productId,
    discountId: discountId ?? _discountId,
  );

  int? get productId => _productId;
  int? get discountId => _discountId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['product_id'] = _productId;
    map['discount_id'] = _discountId;
    return map;
  }
}
/// products_sdk's own minimal view of the kitchen a product is assigned to.
///
/// The full `KitchenModel` lives in `kitchen_sdk`, which ADR-005 forbids this
/// package from importing. The seller product list seeds the kitchen picker
/// with the product's current kitchen, so the host adapter converts this into
/// `kitchen_sdk`'s type at the injection boundary — id and title are all that
/// crosses.
class SellerProductKitchen {
  SellerProductKitchen({this.id, this.title});

  final int? id;
  final String? title;

  factory SellerProductKitchen.fromJson(Map<String, dynamic> json) =>
      SellerProductKitchen(
        id: json['id'],
        title: json['translation'] == null
            ? json['title'] as String?
            : json['translation']['title'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title};
}
