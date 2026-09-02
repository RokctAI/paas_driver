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

class ReferralModel {
  int? id;
  bool? active;
  int? priceFrom;
  int? priceTo;
  String? img;
  String? expiredAt;
  String? createdAt;
  String? updatedAt;
  Translation? translation;

  ReferralModel({
    this.id,
    this.active,
    this.priceFrom,
    this.priceTo,
    this.img,
    this.expiredAt,
    this.createdAt,
    this.updatedAt,
    this.translation,
  });

  ReferralModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    active = json['active'];
    priceFrom = json['price_from'];
    priceTo = json['price_to'];
    img = json['img'];
    expiredAt = json['expired_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['active'] = active;
    data['price_from'] = priceFrom;
    data['price_to'] = priceTo;
    data['img'] = img;
    data['expired_at'] = expiredAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (translation != null) {
      data['translation'] = translation!.toJson();
    }
    return data;
  }
}
