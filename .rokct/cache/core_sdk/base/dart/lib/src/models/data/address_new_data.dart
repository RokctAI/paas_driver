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


import 'package:base_sdk/src/models/data/address_information.dart';

class AddressNewModel {
  String? id;
  bool? active;
  String? title;
  String? userId;
  AddressInformation? address;
  List? location;
  DateTime? createdAt;
  DateTime? updatedAt;

  AddressNewModel({
    this.id,
    this.title,
    this.userId,
    this.address,
    this.location,
    this.createdAt,
    this.updatedAt,
    this.active,
  });

  AddressNewModel copyWith({
    String? id,
    String? title,
    String? userId,
    AddressInformation? address,
    List? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? active,
  }) =>
      AddressNewModel(
        id: id ?? this.id,
        title: title ?? this.title,
        userId: userId ?? this.userId,
        address: address ?? this.address,
        location: location ?? this.location,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        active: active ?? this.active,
      );

  factory AddressNewModel.fromJson(Map<String, dynamic> json) =>
      AddressNewModel(
        id: json["id"]?.toString(),
        title: json["title"],
        userId: json["user_id"]?.toString(),
        active: json["active"] is int ? json["active"] == 1 : json["active"],
        address: json["address"] == null && json["address"].runtimeType == List
            ? null
            : AddressInformation.fromJson(json["address"]),
        location: json["location"] == null
            ? []
            : List.from(json["location"]!.map((x) => x)),
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        if (title != null && (title?.isNotEmpty ?? false)) "title": title,
        "active": 1,
        "user_id": userId,
        "address": address?.toJson(),
        "location":
            location == null ? [] : List<dynamic>.from(location!.map((x) => x)),
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}
