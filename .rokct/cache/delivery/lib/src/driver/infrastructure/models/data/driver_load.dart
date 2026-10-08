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

/// VAN SALES, THE DRIVER'S HALF — the shapes commerce's
/// `api.order.load.*` defs answer with.
///
/// The model, in the words it was approved in: the shop issues a LOAD to
/// the driver (a consignment order). The driver SELLS from that load at
/// each stop — a child order, cash, on his own account when he names no
/// customer. He RETURNS what he did not sell. The load is CLOSED by him
/// or by the shop, and whatever was neither sold nor returned is charged
/// to his wallet AT THE LOAD'S UNIT PRICE.
///
/// So every line carries four quantities that must add up in the
/// driver's head without arithmetic: issued, sold, returned, remaining.
/// `remaining` is the server's figure, never recomputed here — it is what
/// the server validates a sale against, and a client that disagreed with
/// it would offer a quantity the server then refuses.
///
/// Hand-written `fromJson`, like the sibling `deposit_request.dart` and
/// `order_detail.dart`, so the slice stays analyzable without a
/// build_runner pass. Every field is tolerant of absence: a shell whose
/// serializer has not caught up must degrade to a blank, never to a
/// crash.
library;

/// One product on a load: what the shop handed over, what has gone out at
/// the door, what came back, and what is still on the van.
class DriverLoadLine {
  const DriverLoadLine({
    this.itemId,
    this.stockId,
    this.productId,
    this.productUuid,
    this.title,
    this.img,
    this.unitTitle,
    this.unitPrice = 0,
    this.issuedQty = 0,
    this.soldQty = 0,
    this.returnedQty = 0,
    this.remainingQty = 0,
    this.varianceQty,
    this.varianceAmount,
  });

  /// The load order's own line docname — the row's identity for a person
  /// reading a load next to a paper waybill.
  final String? itemId;

  /// What a sale or a return is posted AGAINST (`items: [{stock,
  /// quantity}]`). A line with no stock cannot be sold from.
  final String? stockId;

  final int? productId;
  final String? productUuid;

  /// `product.translation.title`.
  final String? title;
  final String? img;

  /// `product.unit`, flattened to the one string a driver reads next to a
  /// count. Tolerates both shapes the fleet's serializers emit: a nested
  /// `{translation: {title}}` / `{title}` unit doc, or a bare string.
  final String? unitTitle;

  /// The price the load was issued at. The sale total AND the close-out
  /// charge are both struck at this figure — that is the whole point of
  /// carrying it on the line.
  final num unitPrice;

  final num issuedQty;
  final num soldQty;
  final num returnedQty;

  /// The server's remaining figure. Never recomputed client-side.
  final num remainingQty;

  /// Present only on a closed load (`close_load`): what was neither sold
  /// nor returned, and what it cost the driver at [unitPrice].
  final num? varianceQty;
  final num? varianceAmount;

  /// What is still on the van, valued at the load price — the figure the
  /// driver is carrying liability for.
  num get remainingValue => remainingQty * unitPrice;

  /// True when this line can still be sold from or returned.
  bool get hasRemaining => remainingQty > 0 && stockId != null;

  factory DriverLoadLine.fromJson(Map<String, dynamic> json) {
    final product = _asMap(json['product']);
    final translation = _asMap(product['translation']);
    return DriverLoadLine(
      itemId: _asString(json['item_id']),
      stockId: _asString(json['stock_id']),
      productId: _asInt(product['id']),
      productUuid: _asString(product['uuid']),
      title: _asString(translation['title']),
      img: _asString(product['img']),
      unitTitle: _unitTitle(product['unit']),
      unitPrice: _asNum(json['unit_price']),
      issuedQty: _asNum(json['issued_qty']),
      soldQty: _asNum(json['sold_qty']),
      returnedQty: _asNum(json['returned_qty']),
      remainingQty: _asNum(json['remaining_qty']),
      varianceQty: _asNumOrNull(json['variance_qty']),
      varianceAmount: _asNumOrNull(json['variance_amount']),
    );
  }

  /// `product.unit` as the driver reads it. A unit doc carries its word
  /// under `translation.title` (base_sdk's `Unit`); some serializers send
  /// the word itself.
  static String? _unitTitle(dynamic unit) {
    if (unit is String) return unit.trim().isEmpty ? null : unit;
    final map = _asMap(unit);
    if (map.isEmpty) return null;
    final translated = _asString(_asMap(map['translation'])['title']);
    return translated ?? _asString(map['title']);
  }
}

/// One consignment load as the driver holds it.
class DriverLoad {
  const DriverLoad({
    required this.id,
    this.shopId,
    this.shopTitle,
    this.loadStatus,
    this.createdAt,
    this.lines = const [],
    this.totals = const {},
  });

  /// The load order's docname — what every write call names as
  /// `load_order`.
  final String id;

  final String? shopId;
  final String? shopTitle;

  /// The server's own word for the load's state. Rendered as given (and
  /// humanized), never re-judged client-side.
  final String? loadStatus;

  final String? createdAt;

  final List<DriverLoadLine> lines;

  /// `close_load` adds page-level totals. Carried verbatim rather than
  /// typed, so a server that adds a total does not need a client release
  /// to keep the ones it already sends.
  final Map<String, dynamic> totals;

  /// A load is open while the server has not said otherwise. `closed` and
  /// `cancelled` are the two words that take it off the driver's screen;
  /// anything else (including a missing status) is still his to work.
  bool get isOpen {
    final status = (loadStatus ?? '').trim().toLowerCase();
    return status != 'closed' && status != 'cancelled' && status != 'canceled';
  }

  /// Total still on the van at the load price.
  num get remainingTotal =>
      lines.fold<num>(0, (sum, line) => sum + line.remainingValue);

  num get remainingQtyTotal =>
      lines.fold<num>(0, (sum, line) => sum + line.remainingQty);

  /// What the close charged the driver. Prefers the server's own total
  /// when it sent one; otherwise the sum of the per-line variances it did
  /// send. Never invented: a load with no variance answers zero.
  num get varianceTotal {
    final served = _asNumOrNull(totals['variance_amount']) ??
        _asNumOrNull(totals['variance_total']);
    if (served != null) return served;
    return lines.fold<num>(
      0,
      (sum, line) => sum + (line.varianceAmount ?? 0),
    );
  }

  num get varianceQtyTotal => lines.fold<num>(
        0,
        (sum, line) => sum + (line.varianceQty ?? 0),
      );

  /// Lines a sale or a return can still touch.
  List<DriverLoadLine> get sellableLines =>
      lines.where((line) => line.hasRemaining).toList(growable: false);

  factory DriverLoad.fromJson(Map<String, dynamic> json) {
    final shop = _asMap(json['shop']);
    final rawLines = json['lines'];
    return DriverLoad(
      id: _asString(json['id']) ?? '',
      shopId: _asString(shop['id']),
      shopTitle: _asString(shop['title']),
      loadStatus: _asString(json['load_status']),
      createdAt: _asString(json['created_at']),
      lines: rawLines is List
          ? rawLines
              .whereType<Map>()
              .map((row) =>
                  DriverLoadLine.fromJson(Map<String, dynamic>.from(row)))
              .toList(growable: false)
          : const [],
      totals: _totalsOf(json),
    );
  }

  /// The load-level figures `close_load` adds. Kept as whatever numeric
  /// `*_total` / `variance_*` keys the row carries beside the typed ones.
  static Map<String, dynamic> _totalsOf(Map<String, dynamic> json) {
    final totals = <String, dynamic>{};
    final served = json['totals'];
    if (served is Map) {
      totals.addAll(Map<String, dynamic>.from(served));
    }
    for (final entry in json.entries) {
      final key = entry.key;
      if (key.endsWith('_total') || key.startsWith('variance_')) {
        totals[key] = entry.value;
      }
    }
    return totals;
  }

  /// `{"data": [...]}`, a bare list, or a single row — the envelope
  /// tolerance `DepositRecord.listFrom` set the precedent for (the Dio
  /// stack's FrappeResponseInterceptor has already stripped `message`,
  /// but a hand-rolled harness may not have).
  static List<DriverLoad> listFrom(dynamic body) {
    final unwrapped = unwrap(body);
    if (unwrapped is List) {
      return unwrapped
          .whereType<Map>()
          .map((row) => DriverLoad.fromJson(Map<String, dynamic>.from(row)))
          .toList(growable: false);
    }
    if (unwrapped is Map && unwrapped.isNotEmpty) {
      return [DriverLoad.fromJson(Map<String, dynamic>.from(unwrapped))];
    }
    return const [];
  }

  /// One load out of `{"data": <load shape>}`.
  static DriverLoad? oneFrom(dynamic body) {
    final unwrapped = unwrap(body);
    if (unwrapped is Map && unwrapped.isNotEmpty) {
      return DriverLoad.fromJson(Map<String, dynamic>.from(unwrapped));
    }
    return null;
  }

  /// Peels the repo's usual `{"data": ...}` envelope (and a stray
  /// `message` one) off a gateway answer.
  static dynamic unwrap(dynamic body) {
    var current = body;
    for (var depth = 0; depth < 2; depth++) {
      if (current is Map && current.containsKey('message')) {
        current = current['message'];
        continue;
      }
      if (current is Map && current.containsKey('data')) {
        current = current['data'];
        continue;
      }
      break;
    }
    return current;
  }
}

/// `create_load_sale`'s answer: the order that was just born (Delivered
/// and Paid, cash) and the load as it now stands.
class DriverLoadSale {
  const DriverLoadSale({this.orderId, this.load, this.amount = 0});

  /// What the driver reads back to the customer, and what the shop can
  /// look up. Null only if the server did not name it.
  final String? orderId;

  /// The load AFTER the sale — remaining already decremented, so the
  /// caller never has to re-read to redraw.
  final DriverLoad? load;

  /// The cash to collect for this sale, struck at the load's unit prices.
  /// Computed by the caller from the quantities it sent, because the
  /// contract's success payload is the order id and the load, not a
  /// total.
  final num amount;

  /// The same answer with the cash figure the caller struck for it.
  DriverLoadSale withAmount(num amount) =>
      DriverLoadSale(orderId: orderId, load: load, amount: amount);

  factory DriverLoadSale.fromJson(dynamic body, {num amount = 0}) {
    final unwrapped = DriverLoad.unwrap(body);
    final map = _asMap(unwrapped);
    return DriverLoadSale(
      orderId: _asString(map['order_id']),
      load: DriverLoad.oneFrom(map['load']),
      amount: amount,
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}');
}

num _asNum(dynamic value) => _asNumOrNull(value) ?? 0;

num? _asNumOrNull(dynamic value) {
  if (value is num) return value;
  if (value == null) return null;
  return num.tryParse(value.toString().trim());
}
