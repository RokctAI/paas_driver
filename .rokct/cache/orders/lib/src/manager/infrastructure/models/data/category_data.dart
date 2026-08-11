// Ported from paas_manager; the legacy `ShopData? shop` member is dropped -
// nothing in the orders slice reads it, and manager's 939-line ShopData is a
// merchants-workstream concern (products_sdk made the same cut in
// SellerCategoryData).

import 'package:base_sdk/src/models/data/translation.dart';

class CategoryData {
  CategoryData({
    int? id,
    int? shopId,
    String? uuid,
    String? keywords,
    int? parentId,
    String? type,
    String? img,
    bool? active,
    String? status,
    Translation? translation,
    List<CategoryData>? children,
  }) {
    _id = id;
    _shopId = shopId;
    _uuid = uuid;
    _keywords = keywords;
    _parentId = parentId;
    _type = type;
    _img = img;
    _active = active;
    _status = status;
    _translation = translation;
    _children = children;
  }

  CategoryData.fromJson(dynamic json) {
    _id = json['id'];
    _uuid = json['uuid'];
    _shopId = json['shop_id'];
    _keywords = json['keywords'];
    _parentId = json['parent_id'];
    _type = json['type'];
    _img = json['img'];
    _active = json['active'];
    _status = json['status'];
    _translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
    if (json['children'] != null) {
      _children = [];
      json['children'].forEach((v) {
        _children?.add(CategoryData.fromJson(v));
      });
    }
  }

  int? _id;
  int? _shopId;
  String? _uuid;
  String? _keywords;
  int? _parentId;
  String? _type;
  String? _img;
  bool? _active;
  String? _status;
  Translation? _translation;
  List<CategoryData>? _children;

  CategoryData copyWith({
    int? id,
    int? shopId,
    String? uuid,
    String? keywords,
    int? parentId,
    String? type,
    String? img,
    bool? active,
    String? status,
    Translation? translation,
    List<CategoryData>? children,
  }) =>
      CategoryData(
        id: id ?? _id,
        shopId: shopId ?? _shopId,
        uuid: uuid ?? _uuid,
        keywords: keywords ?? _keywords,
        parentId: parentId ?? _parentId,
        type: type ?? _type,
        img: img ?? _img,
        active: active ?? _active,
        status: status ?? _status,
        translation: translation ?? _translation,
        children: children ?? _children,
      );

  int? get id => _id;
  int? get shopId => _shopId;

  String? get uuid => _uuid;

  String? get keywords => _keywords;

  int? get parentId => _parentId;

  String? get type => _type;

  String? get img => _img;


  bool? get active => _active;
  String? get status => _status;

  Translation? get translation => _translation;

  List<CategoryData>? get children => _children;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['shopId'] = _shopId;
    map['uuid'] = _uuid;
    map['keywords'] = _keywords;
    map['parent_id'] = _parentId;
    map['type'] = _type;
    map['img'] = _img;
    map['active'] = _active;
    map['status'] = _status;
    if (_translation != null) {
      map['translation'] = _translation?.toJson();
    }
    if (_children != null) {
      map['children'] = _children?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}
