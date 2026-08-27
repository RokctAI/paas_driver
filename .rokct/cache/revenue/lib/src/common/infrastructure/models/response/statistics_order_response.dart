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

/// Paginated per-order rows behind the income page's "more orders" list.
///
/// Ported unchanged from `paas_manager`'s `StatisticsOrderResponse`.
library;

class StatisticsOrderResponse {
  StatisticsOrderResponse({
    this.timestamp,
    this.status,
    this.message,
    this.data,
  });

  DateTime? timestamp;
  bool? status;
  String? message;
  List<StatisticsOrder>? data;

  StatisticsOrderResponse copyWith({
    DateTime? timestamp,
    bool? status,
    String? message,
    List<StatisticsOrder>? data,
  }) =>
      StatisticsOrderResponse(
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );

  factory StatisticsOrderResponse.fromJson(Map<String, dynamic> json) {
    // Frappe returns the payload under `message`; the legacy shape nested it
    // as `data.data`. Accept either.
    final dynamic root = json['message'] ?? json['data'];
    final dynamic rows = root is Map ? (root['data'] ?? root) : root;
    return StatisticsOrderResponse(
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.tryParse('${json['timestamp']}')?.toLocal(),
      status: json['status'],
      message: json['message'] is String ? json['message'] as String : null,
      data: rows is List
          ? rows
              .map((x) =>
                  StatisticsOrder.fromJson(Map<String, dynamic>.from(x as Map)))
              .toList()
          : <StatisticsOrder>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp?.toIso8601String(),
        'status': status,
        'message': message,
        'data': data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class StatisticsOrder {
  StatisticsOrder({
    this.id,
    this.status,
    this.firstname,
    this.lastname,
    this.active,
    this.quantity,
    this.price,
    this.products,
  });

  int? id;
  String? status;
  String? firstname;
  String? lastname;
  int? active;
  int? quantity;
  double? price;
  List<String>? products;

  StatisticsOrder copyWith({
    int? id,
    String? status,
    String? firstname,
    String? lastname,
    int? active,
    int? quantity,
    double? price,
    List<String>? products,
  }) =>
      StatisticsOrder(
        id: id ?? this.id,
        status: status ?? this.status,
        firstname: firstname ?? this.firstname,
        lastname: lastname ?? this.lastname,
        active: active ?? this.active,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
        products: products ?? this.products,
      );

  factory StatisticsOrder.fromJson(Map<String, dynamic> json) =>
      StatisticsOrder(
        id: json['id'],
        status: json['status'],
        firstname: json['firstname'],
        lastname: json['lastname'],
        active: json['active'],
        quantity: json['quantity'],
        price: json['price']?.toDouble(),
        products: json['products'] == null
            ? []
            : List<String>.from((json['products'] as List).map((x) => '$x')),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'firstname': firstname,
        'lastname': lastname,
        'active': active,
        'quantity': quantity,
        'price': price,
        'products': products == null
            ? []
            : List<dynamic>.from(products!.map((x) => x)),
      };
}
