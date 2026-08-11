import 'package:base_sdk/src/models/data/translation.dart';

class KitchenModel {
  int? id;
  int? active;
  int? shopId;
  Translation? translation;

  KitchenModel({
    this.id,
    this.active,
    this.shopId,
    this.translation,
  });

  KitchenModel copyWith({
    int? id,
    int? active,
    int? shopId,
    Translation? translation,
  }) =>
      KitchenModel(
        id: id ?? this.id,
        active: active ?? this.active,
        shopId: shopId ?? this.shopId,
        translation: translation ?? this.translation,
      );

  factory KitchenModel.fromJson(Map<String, dynamic> json) => KitchenModel(
    id: json["id"],
    active: json["active"],
    shopId: json["shop_id"],
    translation: json["translation"] == null ? null : Translation.fromJson(json["translation"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "active": active,
    "shop_id": shopId,
    "translation": translation?.toJson(),
  };
}
