// Copyright (c) 2026 RokctAI
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:base_sdk/src/models/data/translation.dart';

class TableData {
  int? id;
  String? name;
  int? shopSectionId;
  int? tax;
  int? chairCount;
  bool? active;
  String? createdAt;
  String? updatedAt;
  ShopSection? shopSection;

  TableData({this.id, this.name, this.shopSectionId, this.tax, this.chairCount, this.active, this.createdAt, this.updatedAt, this.shopSection});

  TableData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    shopSectionId = json['shop_section_id'];
    tax = json['tax'];
    chairCount = json['chair_count'];
    active = json['active'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    shopSection = json['shop_section'] != null ? ShopSection.fromJson(json['shop_section']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['shop_section_id'] = shopSectionId;
    data['tax'] = tax;
    data['chair_count'] = chairCount;
    data['active'] = active;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (shopSection != null) {
      data['shop_section'] = shopSection!.toJson();
    }
    return data;
  }
}

class ShopSection {
  int? id;
  int? shopId;
  String? area;
  String? img;
  String? createdAt;
  String? updatedAt;
  Translation? translation;

  ShopSection({this.id, this.shopId, this.area, this.img, this.createdAt, this.updatedAt, this.translation});

  ShopSection.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    shopId = json['shop_id'];
    area = json['area'];
    img = json['img'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    translation = json['translation'] != null ? Translation.fromJson(json['translation']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['shop_id'] = shopId;
    data['area'] = area;
    data['img'] = img;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (translation != null) {
      data['translation'] = translation!.toJson();
    }
    return data;
  }
}





