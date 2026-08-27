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

import '../data/payment_data.dart';

class PaymentsResponse {
  PaymentsResponse({List<Payment>? data}) {
    _data = data;
  }

  PaymentsResponse.fromJson(dynamic json) {
    if (json['data'] != null) {
      _data = [];
      json['data'].forEach((v) {
        _data?.add(Payment.fromJson(v));
      });
    }
  }

  List<Payment>? _data;

  PaymentsResponse copyWith({List<Payment>? data}) =>
      PaymentsResponse(data: data ?? _data);

  List<Payment>? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_data != null) {
      map['data'] = _data?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Payment {
  Payment({
    String? id,
    String? shopId,
    int? status,
    String? clientId,
    String? secretId,
    PaymentData? payment,
  }) {
    _id = id;
    _shopId = shopId;
    _status = status;
    _clientId = clientId;
    _secretId = secretId;
    _payment = payment;
  }

  Payment.fromJson(dynamic json) {
    _id = (json['id'] ?? json['name'])?.toString();
    _shopId = json['shop_id']?.toString();
    _status = json['status'];
    _clientId = json['client_id'];
    _secretId = json['secret_id'];
    _payment =
        json['payment'] != null ? PaymentData.fromJson(json['payment']) : null;
  }

  String? _id;
  String? _shopId;
  int? _status;
  String? _clientId;
  String? _secretId;
  PaymentData? _payment;

  Payment copyWith({
    String? id,
    String? shopId,
    int? status,
    String? clientId,
    String? secretId,
    PaymentData? payment,
  }) =>
      Payment(
        id: id ?? _id,
        shopId: shopId ?? _shopId,
        status: status ?? _status,
        clientId: clientId ?? _clientId,
        secretId: secretId ?? _secretId,
        payment: payment ?? _payment,
      );

  String? get id => _id;

  String? get shopId => _shopId;

  int? get status => _status;

  String? get clientId => _clientId;

  String? get secretId => _secretId;

  PaymentData? get payment => _payment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['shop_id'] = _shopId;
    map['status'] = _status;
    map['client_id'] = _clientId;
    map['secret_id'] = _secretId;
    if (_payment != null) {
      map['payment'] = _payment?.toJson();
    }
    return map;
  }
}
