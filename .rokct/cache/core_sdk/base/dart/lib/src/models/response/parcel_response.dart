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


import 'package:base_sdk/src/models/data/links.dart';
import 'package:base_sdk/src/models/data/meta.dart';
import 'package:base_sdk/src/models/data/translation.dart';

class ParcelTypeResponse {
  List<TypeModel>? data;
  Links? links;
  Meta? meta;

  ParcelTypeResponse({this.data, this.links, this.meta});

  ParcelTypeResponse copyWith({
    List<TypeModel>? data,
    Links? links,
    Meta? meta,
  }) =>
      ParcelTypeResponse(
        data: data ?? this.data,
        links: links ?? this.links,
        meta: meta ?? this.meta,
      );

  factory ParcelTypeResponse.fromJson(Map<String, dynamic> json) =>
      ParcelTypeResponse(
        data: json["data"] == null
            ? []
            : List<TypeModel>.from(
                json["data"]!.map((x) => TypeModel.fromJson(x)),
              ),
        links: json["links"] == null ? null : Links.fromJson(json["links"]),
        meta: json["meta"] == null ? null : Meta.fromJson(json["meta"]),
      );

  Map<String, dynamic> toJson() => {
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
        "links": links?.toJson(),
        "meta": meta?.toJson(),
      };
}

class TypeModel {
  String? id;
  String? type;
  String? img;
  num? minWidth;
  num? minHeight;
  num? minLength;
  num? maxWidth;
  num? maxHeight;
  num? maxLength;
  num? minG;
  num? maxG;
  num? price;
  num? pricePerKm;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<Option>? options;

  TypeModel({
    this.id,
    this.type,
    this.img,
    this.minWidth,
    this.minHeight,
    this.minLength,
    this.maxWidth,
    this.maxHeight,
    this.maxLength,
    this.minG,
    this.maxG,
    this.price,
    this.pricePerKm,
    this.createdAt,
    this.updatedAt,
    this.options,
  });

  TypeModel copyWith({
    String? id,
    String? type,
    String? img,
    num? minWidth,
    num? minHeight,
    num? minLength,
    num? maxWidth,
    num? maxHeight,
    num? maxLength,
    num? minG,
    num? maxG,
    num? price,
    num? pricePerKm,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Option>? options,
  }) =>
      TypeModel(
        id: id ?? this.id,
        type: type ?? this.type,
        img: img ?? this.img,
        minWidth: minWidth ?? this.minWidth,
        minHeight: minHeight ?? this.minHeight,
        minLength: minLength ?? this.minLength,
        maxWidth: maxWidth ?? this.maxWidth,
        maxHeight: maxHeight ?? this.maxHeight,
        maxLength: maxLength ?? this.maxLength,
        minG: minG ?? this.minG,
        maxG: maxG ?? this.maxG,
        price: price ?? this.price,
        pricePerKm: pricePerKm ?? this.pricePerKm,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        options: options ?? this.options,
      );

  factory TypeModel.fromJson(Map<String, dynamic> json) => TypeModel(
        id: json["id"]?.toString(),
        type: json["type"],
        img: json["img"],
        minWidth: json["min_width"],
        minHeight: json["min_height"],
        minLength: json["min_length"],
        maxWidth: json["max_width"],
        maxHeight: json["max_height"],
        maxLength: json["max_length"],
        minG: json["min_g"],
        maxG: json["max_g"],
        price: json["price"],
        pricePerKm: json["price_per_km"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        options: json["options"] == null
            ? []
            : List<Option>.from(
                json["options"]!.map((x) => Option.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "img": img,
        "min_width": minWidth,
        "min_height": minHeight,
        "min_length": minLength,
        "max_width": maxWidth,
        "max_height": maxHeight,
        "max_length": maxLength,
        "min_g": minG,
        "max_g": maxG,
        "price": price,
        "price_per_km": pricePerKm,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "options": options == null
            ? []
            : List<dynamic>.from(options!.map((x) => x.toJson())),
      };
}

class Option {
  String? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  Translation? translation;

  Option({this.id, this.createdAt, this.updatedAt, this.translation});

  Option copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Translation? translation,
  }) =>
      Option(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        translation: translation ?? this.translation,
      );

  factory Option.fromJson(Map<String, dynamic> json) => Option(
        id: json["id"]?.toString(),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        translation: json["translation"] == null
            ? null
            : Translation.fromJson(json["translation"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "translation": translation?.toJson(),
      };
}
