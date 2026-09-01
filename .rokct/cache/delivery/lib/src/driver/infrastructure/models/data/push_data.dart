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

import 'dart:convert';

class PushModel {
  final String? shopImage;
  final String? shopName;
  final String? orderId;
  final String? startTime;
  final String? customerImge;
  final AddressModel? addressName;
  final String? customerName;
  final String? customerPhoneNumber;
  final String? shopNumber;
  final String? distance;
  final String? comment;
  final num? totalPrice;
  final num? deliveryFree;
  final String? type;
  final String? orderType;
  final double? latitude;
  final double? longitude;

  PushModel({
    this.shopImage,
    this.orderType,
    this.shopName,
    this.orderId,
    this.startTime,
    this.customerImge,
    this.addressName,
    this.customerName,
    this.customerPhoneNumber,
    this.shopNumber,
    this.distance,
    this.comment,
    this.totalPrice,
    this.deliveryFree,
    this.type,
    this.latitude,
    this.longitude,
  });

  factory PushModel.fromJson(Map data) {
    return PushModel(
      shopImage: jsonDecode(data["order"])["shop"]["logo_img"],
      shopName: jsonDecode(data["order"])["shop"]["translation"]["title"],
      // Order docnames are strings; prefer the always-present `name`,
      // falling back to the legacy numeric `id` for older payloads.
      orderId: (jsonDecode(data["order"])["name"] ??
              jsonDecode(data["order"])["id"])
          ?.toString(),
      startTime: jsonDecode(data["order"])["updated_at"],
      customerImge: jsonDecode(data["order"])["user"]["img"],
      addressName: AddressModel.fromJson(jsonDecode(data["order"])["address"]),
      customerName: jsonDecode(data["order"])["user"]["firstname"],
      customerPhoneNumber: jsonDecode(data["order"])["user"]["phone"],
      shopNumber: jsonDecode(data["order"])["shop"]["phone"],
      distance: data["km"],
      comment: jsonDecode(data["order"])["note"],
      totalPrice: jsonDecode(data["order"])["total_price"],
      type: jsonDecode(data["order"])["transaction"]["payment_system"]["tag"],
      deliveryFree: jsonDecode(data["order"])["delivery_fee"],
      longitude: double.tryParse(
          jsonDecode(data["order"])["location"]["longitude"].toString()),
      latitude: double.tryParse(
          jsonDecode(data["order"])["location"]["latitude"].toString()),
    );
  }

  factory PushModel.fromJsonSuggest(Map data) {
    return PushModel(
      shopImage: jsonDecode(data["order"])["shop"]["logo_img"],
      shopName: jsonDecode(data["order"])["shop"]["translation"]["title"],
      orderId: (jsonDecode(data["order"])["name"] ??
              jsonDecode(data["order"])["id"])
          ?.toString(),
      startTime: jsonDecode(data["order"])["updated_at"],
      customerImge: jsonDecode(data["order"])["user"]["img"],
      addressName: AddressModel.fromJson(jsonDecode(data["order"])["address"]),
      customerName: jsonDecode(data["order"])["user"]["firstname"],
      customerPhoneNumber: jsonDecode(data["order"])["user"]["phone"],
      shopNumber: jsonDecode(data["order"])["shop"]["phone"],
      distance: data["km"],
      comment: jsonDecode(data["order"])["note"],
      totalPrice: jsonDecode(data["order"])["total_price"],
      type: jsonDecode(data["order"])["transaction"]["payment_system"]["tag"],
      deliveryFree: jsonDecode(data["order"])["delivery_fee"],
      longitude: double.tryParse(
          jsonDecode(data["order"])["location"]["longitude"].toString()),
      latitude: double.tryParse(
          jsonDecode(data["order"])["location"]["latitude"].toString()),
    );
  }
}

class AddressModel {
  final String? address;
  final String? office;
  final String? house;
  final String? floor;

  AddressModel({
    this.address,
    this.office,
    this.house,
    this.floor,
  });

  Map toJson() {
    return {
      "address": address,
      "office": office,
      "house": house,
      "floor": floor
    };
  }

  factory AddressModel.fromJson(Map? data) {
    return AddressModel(
      address: data?["address"],
      office: data?["office"].toString(),
      house: data?["house"].toString(),
      floor: data?["floor"].toString(),
    );
  }
}
