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

import 'package:base_sdk/src/models/data/translation.dart';

class KitchenModel {
  String? id;
  int? active;
  String? shopId;
  Translation? translation;

  KitchenModel({
    this.id,
    this.active,
    this.shopId,
    this.translation,
  });

  KitchenModel copyWith({
    String? id,
    int? active,
    String? shopId,
    Translation? translation,
  }) =>
      KitchenModel(
        id: id ?? this.id,
        active: active ?? this.active,
        shopId: shopId ?? this.shopId,
        translation: translation ?? this.translation,
      );

  factory KitchenModel.fromJson(Map<String, dynamic> json) => KitchenModel(
    id: (json["id"] ?? json["name"])?.toString(),
    active: json["active"],
    shopId: json["shop_id"]?.toString(),
    translation: json["translation"] == null ? null : Translation.fromJson(json["translation"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "active": active,
    "shop_id": shopId,
    "translation": translation?.toJson(),
  };
}
