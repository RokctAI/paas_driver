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

import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';

class RequestModelData {
  int? id;
  int? modelId;
  String? modelType;
  int? datumCreatedBy;
  CarData? data;
  String? status;
  String? statusNote;
  ProfileData? model;
  ProfileData? createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;

  RequestModelData({
    this.id,
    this.modelId,
    this.modelType,
    this.datumCreatedBy,
    this.data,
    this.status,
    this.statusNote,
    this.model,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  RequestModelData copyWith({
    int? id,
    int? modelId,
    String? modelType,
    int? datumCreatedBy,
    CarData? data,
    String? status,
    String? statusNote,
    ProfileData? model,
    ProfileData? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      RequestModelData(
        id: id ?? this.id,
        modelId: modelId ?? this.modelId,
        modelType: modelType ?? this.modelType,
        datumCreatedBy: datumCreatedBy ?? this.datumCreatedBy,
        data: data ?? this.data,
        status: status ?? this.status,
        statusNote: statusNote ?? this.statusNote,
        model: model ?? this.model,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory RequestModelData.fromJson(Map<String, dynamic> json) =>
      RequestModelData(
        id: json["id"],
        modelId: json["model_id"],
        modelType: json["model_type"],
        datumCreatedBy: json["created_by"],
        data: json["data"] == null ? null : CarData.fromJson(json["data"]),
        status: json["status"],
        statusNote: json["status_note"],
        model: json["model"] == null ? null : ProfileData.fromJson(json["model"]),
        createdBy: json["createdBy"] == null
            ? null
            : ProfileData.fromJson(json["createdBy"]),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "model_id": modelId,
        "model_type": modelType,
        "created_by": datumCreatedBy,
        "data": data?.toJson(),
        "status": status,
        "status_note": statusNote,
        "model": model?.toJson(),
        "createdBy": createdBy?.toJson(),
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

class CarData {
  int? kg;
  String? role;
  String? brand;
  String? color;
  String? model;
  int? width;
  int? height;
  int? length;
  String? number;
  int? online;
  String? images0;
  String? typeOfTechnique;
  Location? location;

  CarData({
    this.kg,
    this.role,
    this.brand,
    this.color,
    this.model,
    this.width,
    this.height,
    this.length,
    this.number,
    this.online,
    this.images0,
    this.typeOfTechnique,
    this.location,
  });

  CarData copyWith({
    int? kg,
    String? role,
    String? brand,
    String? color,
    String? model,
    int? width,
    int? height,
    int? length,
    String? number,
    int? online,
    String? images0,
    String? typeOfTechnique,
    Location? location,
  }) =>
      CarData(
        kg: kg ?? this.kg,
        role: role ?? this.role,
        brand: brand ?? this.brand,
        color: color ?? this.color,
        model: model ?? this.model,
        width: width ?? this.width,
        height: height ?? this.height,
        length: length ?? this.length,
        number: number ?? this.number,
        online: online ?? this.online,
        images0: images0 ?? this.images0,
        typeOfTechnique: typeOfTechnique ?? this.typeOfTechnique,
        location: location ?? this.location,
      );

  factory CarData.fromJson(Map<String, dynamic> json) => CarData(
        kg: json["kg"],
        role: json["role"],
        brand: json["brand"],
        color: json["color"],
        model: json["model"],
        width: json["width"],
        height: json["height"],
        length: json["length"],
        number: json["number"],
        online: json["online"],
        images0: json["images[0]"],
        typeOfTechnique: json["type_of_technique"],
        location: json["location"] == null
            ? null
            : Location.fromJson(json["location"]),
      );

  Map<String, dynamic> toJson() => {
        "kg": kg,
        "role": role,
        "brand": brand,
        "color": color,
        "model": model,
        "width": width,
        "height": height,
        "length": length,
        "number": number,
        "online": online,
        "images[0]": images0,
        "type_of_technique": typeOfTechnique,
        "location": location?.toJson(),
      };
}
