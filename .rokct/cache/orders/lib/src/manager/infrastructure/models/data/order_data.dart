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

import 'package:orders_sdk/src/manager/infrastructure/models/data/order_json_ext.dart';

import 'kitchen_data.dart';
import 'payment_data.dart';
import 'stock.dart';
import 'table_data.dart';
import 'user_data.dart';
import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/models/data/location.dart';

class OrderData {
  OrderData({
    String? id,
    String? userId,
    num? totalPrice,
    num? rate,
    num? tax,
    num? originPrice,
    num? serviceFee,
    num? totalDiscount,
    num? couponPrice,
    num? tips,
    num? commissionFee,
    String? status,
    LocationModel? location,
    String? deliveryType,
    num? deliveryFee,
    num? otp,
    dynamic deliveryman,
    String? deliveryDate,
    String? deliveryTime,
    String? createdAt,
    String? updatedAt,
    TableData? table,
    CurrencyData? currency,
    UserData? user,
    List<OrderDetail>? details,
    Transaction? transaction,
    OrderAddress? orderAddress,
    dynamic review,
    String? note,
    String? afterDeliveredImage,
    bool? seen,
  }) {
    _id = id;
    _userId = userId;
    _table = table;
    _serviceFee = serviceFee;
    _totalPrice = totalPrice;
    _rate = rate;
    _tax = tax;
    _tips = tips;
    _afterDeliveredImage = afterDeliveredImage;
    _commissionFee = commissionFee;
    _status = status;
    _location = location;
    _deliveryType = deliveryType;
    _deliveryFee = deliveryFee;
    _otp = otp;
    _deliveryman = deliveryman;
    _deliveryDate = deliveryDate;
    _deliveryTime = deliveryTime;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _currency = currency;
    _user = user;
    _details = details;
    _transaction = transaction;
    _orderAddress = orderAddress;
    _review = review;
    _note = note;
    _seen = seen;
  }

  OrderData.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _afterDeliveredImage = json['image_after_delivered'];
    _userId = json['user_id']?.toString();
    _serviceFee = json['service_fee'];
    _totalDiscount = json['total_discount'];
    _originPrice = json['origin_price'];
    _couponPrice = json['coupon'] != null ? json['coupon']["price"] : null;
    _totalPrice = json['total_price'];
    _rate = json['rate'];
    _tips = json['tips'];
    _tax = json['tax'];
    _commissionFee = json['commission_fee'];
    _status = json['status'];
    _location = json['location'] != null
        ? LocationModel.fromJson(json['location'])
        : null;
    _deliveryType = json['delivery_type'];
    _deliveryFee = json['delivery_fee'];
    _otp = json['otp'];
    _deliveryman = json['deliveryman'];
    _deliveryDate = json['delivery_date'];
    _deliveryTime = json['delivery_time'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _table = json['table'] != null ? TableData.fromJson(json['table']) : null;
    _currency = json['currency'] != null
        ? CurrencyData.fromJson(json['currency'])
        : null;
    _user = json['user'] != null ? UserData.fromJson(json['user']) : null;
    if (json['details'] != null) {
      _details = [];
      json['details'].forEach((v) {
        _details?.add(OrderDetail.fromJson(v));
      });
    }
    _transaction = json['transaction'] != null
        ? Transaction.fromJson(json['transaction'])
        : null;
    _orderAddress =
    json['address'] != null ? OrderAddress.fromJson(json['address']) : null;
    _review = json['review'];
    _note = json['note'];
    _seen = false;
  }

  String? _id;
  String? _userId;
  num? _totalPrice;
  num? _rate;
  num? _tax;
  num? _originPrice;
  num? _serviceFee;
  num? _tips;
  num? _totalDiscount;
  num? _commissionFee;
  num? _couponPrice;
  String? _status;
  String? _afterDeliveredImage;
  LocationModel? _location;
  TableData? _table;
  String? _deliveryType;
  num? _deliveryFee;
  num? _otp;
  dynamic _deliveryman;
  String? _deliveryDate;
  String? _deliveryTime;
  String? _createdAt;
  String? _updatedAt;
  CurrencyData? _currency;
  UserData? _user;
  List<OrderDetail>? _details;
  Transaction? _transaction;
  OrderAddress? _orderAddress;
  dynamic _review;
  String? _note;
  bool? _seen;

  // Local-first sync metadata, set only on rows built from the
  // manager_orders KV box (never part of the wire shape and deliberately
  // outside copyWith/toJson): [pendingSync] marks a local not-yet-synced
  // create for the list badge, [needsAttention]/[syncError] the parked
  // rejected state, [localId] the `offline:<uuid>` record key the POS keys
  // on until the backend id arrives.
  String? localId;
  bool pendingSync = false;
  bool needsAttention = false;
  String? syncError;

  OrderData copyWith({
    String? id,
    String? userId,
    num? totalPrice,
    num? rate,
    num? tax,
    num? tips,
    num? commissionFee,
    String? status,
    String? afterDeliveredImage,
    LocationModel? location,
    String? deliveryType,
    num? deliveryFee,
    num? otp,
    dynamic deliveryman,
    String? deliveryDate,
    String? deliveryTime,
    String? createdAt,
    String? updatedAt,
    CurrencyData? currency,
    UserData? user,
    List<OrderDetail>? details,
    Transaction? transaction,
    OrderAddress? orderAddress,
    dynamic review,
    String? note,
    bool? seen,
  }) =>
      OrderData(
        id: id ?? _id,
        userId: userId ?? _userId,
        tips: tips ?? _tips,
        totalPrice: totalPrice ?? _totalPrice,
        rate: rate ?? _rate,
        tax: tax ?? _tax,
        afterDeliveredImage: afterDeliveredImage ?? _afterDeliveredImage,
        commissionFee: commissionFee ?? _commissionFee,
        status: status ?? _status,
        location: location ?? _location,
        deliveryType: deliveryType ?? _deliveryType,
        deliveryFee: deliveryFee ?? _deliveryFee,
        otp: otp ?? _otp,
        deliveryman: deliveryman ?? _deliveryman,
        deliveryDate: deliveryDate ?? _deliveryDate,
        deliveryTime: deliveryTime ?? _deliveryTime,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
        currency: currency ?? _currency,
        user: user ?? _user,
        details: details ?? _details,
        transaction: transaction ?? _transaction,
        review: review ?? _review,
        note: note ?? _note,
        seen: seen ?? _seen,
      );

  String? get id => _id;

  String? get userId => _userId;

  num? get totalPrice => _totalPrice;

  num? get rate => _rate;

  num? get tax => _tax;

  num? get serviceFee => _serviceFee;

  num? get totalDiscount => _totalDiscount;

  num? get couponPrice => _couponPrice;

  num? get tips => _tips;

  num? get originPrice => _originPrice;

  num? get commissionFee => _commissionFee;

  String? get status => _status;

  String? get afterDeliveredImage => _afterDeliveredImage;

  LocationModel? get location => _location;

  TableData? get table => _table;

  String? get deliveryType => _deliveryType;

  num? get deliveryFee => _deliveryFee;
  num? get otp => _otp;

  dynamic get deliveryman => _deliveryman;

  String? get deliveryDate => _deliveryDate;

  String? get deliveryTime => _deliveryTime;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;


  CurrencyData? get currency => _currency;

  UserData? get user => _user;

  List<OrderDetail>? get details => _details;

  Transaction? get transaction => _transaction;

  OrderAddress? get orderAddress => _orderAddress;

  dynamic get review => _review;

  String? get note => _note;

  bool? get seen => _seen;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['user_id'] = _userId;
    map['total_price'] = _totalPrice;
    map['rate'] = _rate;
    map['tax'] = _tax;
    map['tips'] = _tips;
    map['commission_fee'] = _commissionFee;
    map['status'] = _status;
    if (_location != null) {
      map['location'] = _location?.toJson();
    }
    if (_table != null) {
      map['table'] = _table?.toJson();
    }
    map['delivery_type'] = _deliveryType;
    map['image_after_delivered'] = _afterDeliveredImage;
    map['delivery_fee'] = _deliveryFee;
    map['otp'] = _otp;
    map['deliveryman'] = _deliveryman;
    map['delivery_date'] = _deliveryDate;
    map['delivery_time'] = _deliveryTime;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    if (_currency != null) {
      map['currency'] = _currency?.toJson();
    }
    if (_user != null) {
      map['user'] = _user?.toJson();
    }
    if (_details != null) {
      map['details'] = _details?.map((v) => v.toJson()).toList();
    }
    if (_transaction != null) {
      map['transaction'] = _transaction?.toJson();
    }
    map['review'] = _review;
    map['seen'] = _seen;
    return map;
  }
}

class OrderDetail {
  OrderDetail({
    String? note,
    String? id,
    String? orderId,
    String? stockId,
    num? originPrice,
    num? totalPrice,
    num? tax,
    num? discount,
    int? quantity,
    bool? bonus,
    bool? shopBonus,
    String? createdAt,
    String? status,
    String? updatedAt,
    Stock? stock,
    KitchenModel? kitchen,
    List<AddonData>? addons,
    bool? isChecked,
  }) {
    _note = note;
    _id = id;
    _orderId = orderId;
    _stockId = stockId;
    _status = status;
    _kitchen = kitchen;
    _originPrice = originPrice;
    _totalPrice = totalPrice;
    _tax = tax;
    _discount = discount;
    _quantity = quantity;
    _bonus = bonus;
    _shopBonus = shopBonus;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _stock = stock;
    _addons = addons;
    _isChecked = isChecked;
  }

  OrderDetail.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _status = json['status'];
    _orderId = json['order_id']?.toString();
    _stockId = json['stock_id']?.toString();
    _originPrice = json['origin_price'];
    _totalPrice = json['total_price'];
    _tax = json['tax'];
    _discount = json['discount'];
    _quantity = json['quantity'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _bonus = json['bonus']?.toString().toBool();
    _stock = json['stock'] != null ? Stock.fromJson(json['stock']) : null;
    _kitchen =
    json['kitchen'] != null ? KitchenModel.fromJson(json['kitchen']) : null;
    if (json['addons'] != null) {
      _addons = [];
      json['addons'].forEach((v) {
        _addons?.add(AddonData.fromJson(v));
      });
    }
    _isChecked = false;
    _note = json['note'] ?? '';
  }

  String? _note;
  String? _id;
  String? _orderId;
  String? _stockId;
  num? _originPrice;
  num? _totalPrice;
  num? _tax;
  num? _discount;
  int? _quantity;
  bool? _bonus;
  bool? _shopBonus;
  String? _createdAt;
  String? _status;
  String? _updatedAt;
  Stock? _stock;
  KitchenModel? _kitchen;
  List<AddonData>? _addons;
  bool? _isChecked;

  OrderDetail copyWith({
    String? note,
    String? id,
    String? orderId,
    String? stockId,
    num? originPrice,
    num? totalPrice,
    num? tax,
    num? discount,
    int? quantity,
    bool? bonus,
    bool? shopBonus,
    String? createdAt,
    String? updatedAt,
    String? status,
    Stock? stock,
    KitchenModel? kitchen,
    List<AddonData>? addons,
    bool? isChecked,
  }) =>
      OrderDetail(
        note: note ?? _note,
        id: id ?? _id,
        orderId: orderId ?? _orderId,
        stockId: stockId ?? _stockId,
        originPrice: originPrice ?? _originPrice,
        totalPrice: totalPrice ?? _totalPrice,
        tax: tax ?? _tax,
        discount: discount ?? _discount,
        quantity: quantity ?? _quantity,
        bonus: bonus ?? _bonus,
        kitchen: kitchen ?? _kitchen,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
        stock: stock ?? _stock,
        addons: addons ?? _addons,
        status: status ?? _status,
        isChecked: isChecked ?? _isChecked,
        shopBonus: shopBonus ?? _shopBonus,
      );

  String? get id => _id;

  String? get orderId => _orderId;

  String? get stockId => _stockId;

  num? get originPrice => _originPrice;

  num? get totalPrice => _totalPrice;

  num? get tax => _tax;

  num? get discount => _discount;

  int? get quantity => _quantity;

  bool? get bonus => _bonus;

  bool? get shopBonus => _shopBonus;

  String? get createdAt => _createdAt;

  String? get status => _status;

  String? get updatedAt => _updatedAt;

  Stock? get stock => _stock;

  KitchenModel? get kitchen => _kitchen;

  List<AddonData>? get addons => _addons;

  bool? get isChecked => _isChecked;

  String? get note => _note;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['order_id'] = _orderId;
    map['stock_id'] = _stockId;
    map['origin_price'] = _originPrice;
    map['total_price'] = _totalPrice;
    map['tax'] = _tax;
    map['discount'] = _discount;
    map['quantity'] = _quantity;
    map['bonus'] = _bonus;
    map['status'] = _status;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    if (_stock != null) {
      map['stock'] = _stock?.toJson();
    }
    map['note'] = _note;
    return map;
  }
}

class Transaction {
  Transaction({
    String? id,
    String? payableId,
    num? price,
    String? paymentTrxId,
    String? note,
    dynamic performTime,
    String? status,
    String? statusDescription,
    String? createdAt,
    String? updatedAt,
    PaymentData? paymentSystem,
  }) {
    _id = id;
    _payableId = payableId;
    _price = price;
    _paymentTrxId = paymentTrxId;
    _note = note;
    _performTime = performTime;
    _status = status;
    _statusDescription = statusDescription;
    _createdAt = createdAt;
    _updatedAt = updatedAt;
    _paymentSystem = paymentSystem;
  }

  Transaction.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _payableId = json['payable_id']?.toString();
    _price = json['price'];
    _paymentTrxId = json['payment_trx_id'];
    _note = json['note'];
    _performTime = json['perform_time'];
    _status = json['status'];
    _statusDescription = json['status_description'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    _paymentSystem = json['payment_system'] != null
        ? PaymentData.fromJson(json['payment_system'])
        : null;
  }

  String? _id;
  String? _payableId;
  num? _price;
  String? _paymentTrxId;
  String? _note;
  dynamic _performTime;
  String? _status;
  String? _statusDescription;
  String? _createdAt;
  String? _updatedAt;
  PaymentData? _paymentSystem;

  Transaction copyWith({
    String? id,
    String? payableId,
    num? price,
    String? paymentTrxId,
    String? note,
    dynamic performTime,
    String? status,
    String? statusDescription,
    String? createdAt,
    String? updatedAt,
    PaymentData? paymentSystem,
  }) =>
      Transaction(
        id: id ?? _id,
        payableId: payableId ?? _payableId,
        price: price ?? _price,
        paymentTrxId: paymentTrxId ?? _paymentTrxId,
        note: note ?? _note,
        performTime: performTime ?? _performTime,
        status: status ?? _status,
        statusDescription: statusDescription ?? _statusDescription,
        createdAt: createdAt ?? _createdAt,
        updatedAt: updatedAt ?? _updatedAt,
        paymentSystem: paymentSystem ?? _paymentSystem,
      );

  String? get id => _id;

  String? get payableId => _payableId;

  num? get price => _price;

  String? get paymentTrxId => _paymentTrxId;

  String? get note => _note;

  dynamic get performTime => _performTime;

  String? get status => _status;

  String? get statusDescription => _statusDescription;

  String? get createdAt => _createdAt;

  String? get updatedAt => _updatedAt;

  PaymentData? get paymentSystem => _paymentSystem;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['payable_id'] = _payableId;
    map['price'] = _price;
    map['payment_trx_id'] = _paymentTrxId;
    map['note'] = _note;
    map['perform_time'] = _performTime;
    map['status'] = _status;
    map['status_description'] = _statusDescription;
    map['created_at'] = _createdAt;
    map['updated_at'] = _updatedAt;
    if (_paymentSystem != null) {
      map['payment_system'] = _paymentSystem?.toJson();
    }
    return map;
  }
}

class OrderAddress {
  OrderAddress({
    String? address,
    String? office,
    String? house,
    String? floor,
  }) {
    _address = address;
    _office = office;
    _house = house;
    _floor = floor;
  }

  OrderAddress.fromJson(dynamic json) {
    _address = json['address'];
    _office = json['office'];
    _house = json['house'];
    _floor = json['floor'];
  }

  String? _address;
  String? _office;
  String? _house;
  String? _floor;

  OrderAddress copyWith({
    String? address,
    String? office,
    String? house,
    String? floor,
  }) =>
      OrderAddress(
        address: address ?? _address,
        office: office ?? _office,
        house: house ?? _house,
        floor: floor ?? _floor,
      );

  String? get address => _address;

  String? get office => _office;

  String? get house => _house;

  String? get floor => _floor;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['address'] = _address;
    map['office'] = _office;
    map['house'] = _house;
    map['floor'] = _floor;
    return map;
  }
}
