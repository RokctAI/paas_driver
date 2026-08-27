// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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


class TakeModel {
  int? id;
  String? img;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;
  Translation? translation;

  TakeModel({
    this.id,
    this.img,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.translation,
  });

  TakeModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    img = json['img'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    translation = json['translation'] != null
        ? Translation.fromJson(json['translation'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['img'] = img;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    if (translation != null) {
      data['translation'] = translation!.toJson();
    }
    return data;
  }
}

class Translation {
  int? id;
  int? shopTagId;
  String? title;
  String? locale;
  String? deletedAt;

  Translation({
    this.id,
    this.shopTagId,
    this.title,
    this.locale,
    this.deletedAt,
  });

  Translation.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    shopTagId = json['shop_tag_id'];
    title = json['title'];
    locale = json['locale'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['shop_tag_id'] = shopTagId;
    data['title'] = title;
    data['locale'] = locale;
    data['deleted_at'] = deletedAt;
    return data;
  }
}
