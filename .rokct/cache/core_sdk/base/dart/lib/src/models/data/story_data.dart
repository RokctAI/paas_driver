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


import 'dart:convert';

List<List<StoryModel?>?>? storyModelFromJson(dynamic str) => str == null
    ? []
    : List<List<StoryModel?>?>.from(
        str.map(
          (x) => x == null
              ? []
              : List<StoryModel?>.from(x!.map((x) => StoryModel.fromJson(x))),
        ),
      );

String storyModelToJson(List<List<StoryModel?>?>? data) => json.encode(
      data == null
          ? []
          : List<dynamic>.from(
              data.map(
                (x) => x == null
                    ? []
                    : List<dynamic>.from(x.map((x) => x!.toJson())),
              ),
            ),
    );

class StoryModel {
  StoryModel({
    this.shopId,
    this.logoImg,
    this.title,
    this.productUuid,
    this.productTitle,
    this.url,
    this.createdAt,
    this.updatedAt,
  });

  String? shopId;
  String? logoImg;
  String? title;
  String? productUuid;
  String? productTitle;
  String? url;
  DateTime? createdAt;
  DateTime? updatedAt;

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      shopId: json["shop_id"]?.toString(),
      logoImg: json["logo_img"],
      title: json["title"],
      productUuid: json["product_uuid"],
      productTitle: json["product_title"],
      url: json["url"],
      createdAt: DateTime.tryParse(json["created_at"])?.toLocal(),
      updatedAt: DateTime.tryParse(json["updated_at"])?.toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
        "shop_id": shopId,
        "logo_img": logoImg,
        "title": title,
        "product_id": productUuid,
        "product_title": productTitle,
        "url": url,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
