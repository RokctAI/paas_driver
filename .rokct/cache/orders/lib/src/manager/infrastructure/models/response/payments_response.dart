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
    int? id,
    int? shopId,
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
    _id = json['id'];
    _shopId = json['shop_id'];
    _status = json['status'];
    _clientId = json['client_id'];
    _secretId = json['secret_id'];
    _payment =
        json['payment'] != null ? PaymentData.fromJson(json['payment']) : null;
  }

  int? _id;
  int? _shopId;
  int? _status;
  String? _clientId;
  String? _secretId;
  PaymentData? _payment;

  Payment copyWith({
    int? id,
    int? shopId,
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

  int? get id => _id;

  int? get shopId => _shopId;

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
