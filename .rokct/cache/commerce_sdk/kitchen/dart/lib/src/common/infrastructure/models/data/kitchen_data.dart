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

/// A kitchen (prep station) belonging to a shop.
///
/// Ported from `paas_manager`'s `KitchenModel`. The app carried its own
/// `Translation`; base_sdk's is a superset of it (83% identical, plus
/// `buttonText`/`address`), so this uses base_sdk's per the
/// prefer-the-SDK's-version convention.
class KitchenModel {
  KitchenModel({this.id, this.active, this.shopId, this.translation});

  String? id;
  int? active;
  String? shopId;
  Translation? translation;

  String get title => translation?.title ?? '';

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
        // Kitchen docnames are Frappe hash strings; list endpoints emit only
        // `name`, so fall back to it (reference pattern, sections_tables).
        id: (json['id'] ?? json['name'])?.toString(),
        active: json['active'],
        shopId: json['shop_id']?.toString(),
        translation: json['translation'] == null
            ? null
            : Translation.fromJson(json['translation']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'active': active,
        'shop_id': shopId,
        'translation': translation?.toJson(),
      };
}
