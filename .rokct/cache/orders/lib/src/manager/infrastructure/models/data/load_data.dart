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

/// A CONSIGNMENT LOAD as the shop side reads it (commerce#135,
/// `frappe/src/tenant/api/order/load.py`).
///
/// A load is an Order the shop issues to a driver: the shop's shelf is
/// decremented ONCE when the load is issued, the driver sells from the van
/// stop by stop, brings the leftovers back, and whatever was neither sold
/// nor returned is his VARIANCE — charged to his wallet at the load's own
/// unit price the moment the load is closed.
///
/// Plain Dart with a `fromJson`, like every other model in this slice
/// ([CollectConversion], `Stock`, `OrderData`): freezed is used here for
/// application STATE only.
///
/// The line's product is modelled by [LoadProduct] rather than the POS's
/// `ProductData` on purpose: the load payload's `unit` is the unit's
/// docname (a bare string), while `ProductData.fromJson` hands `unit` to
/// `UnitData.fromJson`, which indexes it as a map.
library;

/// The shop that issued a load — `{id, title}`, the shape the clients
/// already read everywhere else.
class LoadShop {
  final String id;
  final String title;

  const LoadShop({required this.id, required this.title});

  factory LoadShop.fromJson(Map<String, dynamic> json) => LoadShop(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
  );
}

/// The driver a load was issued to — `{id, name}`, as
/// `list_shop_deliverymen` and the serialized load both spell it. `name`
/// is the User's full name, falling back server-side to the id.
class LoadDeliveryman {
  final String id;
  final String name;

  const LoadDeliveryman({required this.id, required this.name});

  factory LoadDeliveryman.fromJson(Map<String, dynamic> json) {
    final String id = json['id']?.toString() ?? '';
    final String name = json['name']?.toString() ?? '';
    return LoadDeliveryman(id: id, name: name.isEmpty ? id : name);
  }
}

/// The product on one load line, exactly the keys `_product_payload`
/// serializes.
class LoadProduct {
  final String id;
  final String uuid;
  final String title;
  final String? img;
  final String? unit;

  const LoadProduct({
    required this.id,
    required this.uuid,
    required this.title,
    this.img,
    this.unit,
  });

  factory LoadProduct.fromJson(Map<String, dynamic> json) {
    final translation = json['translation'];
    final String title = translation is Map
        ? (translation['title']?.toString() ?? '')
        : '';
    final String id = json['id']?.toString() ?? '';
    return LoadProduct(
      id: id,
      uuid: json['uuid']?.toString() ?? id,
      title: title.isEmpty ? id : title,
      img: json['img']?.toString(),
      unit: json['unit']?.toString(),
    );
  }
}

/// One line of a load: what went out, what came back as cash, what came
/// back as stock, and what is still on the van.
class LoadLine {
  final String itemId;
  final String? stockId;
  final LoadProduct product;
  final num unitPrice;
  final num issuedQty;
  final num soldQty;
  final num returnedQty;
  final num remainingQty;

  const LoadLine({
    required this.itemId,
    required this.product,
    required this.unitPrice,
    required this.issuedQty,
    required this.soldQty,
    required this.returnedQty,
    required this.remainingQty,
    this.stockId,
  });

  factory LoadLine.fromJson(Map<String, dynamic> json) {
    final num issued = _num(json['issued_qty']);
    final num sold = _num(json['sold_qty']);
    final num returned = _num(json['returned_qty']);
    final product = json['product'];
    return LoadLine(
      itemId: json['item_id']?.toString() ?? '',
      stockId: json['stock_id']?.toString(),
      product: LoadProduct.fromJson(
        product is Map ? product.cast<String, dynamic>() : const {},
      ),
      unitPrice: _num(json['unit_price']),
      issuedQty: issued,
      soldQty: sold,
      returnedQty: returned,
      // Trust the server's own remainder when it sent one; fall back to
      // the same subtraction it does rather than showing nothing.
      remainingQty: json['remaining_qty'] == null
          ? _clampToZero(issued - sold - returned)
          : _num(json['remaining_qty']),
    );
  }

  /// Issued minus sold minus returned — what the driver is short. Never
  /// negative: an over-return is the backend's business, not a credit.
  num get varianceQty => _clampToZero(issuedQty - soldQty - returnedQty);

  /// That shortfall priced at the LOAD's unit price, which is the money
  /// that comes off the driver's wallet when the load closes.
  num get varianceAmount => varianceQty * unitPrice;
}

/// What `close_load` adds on top of the load: the three running totals
/// plus the variance it charged.
class LoadTotals {
  final num issuedQty;
  final num soldQty;
  final num returnedQty;
  final num varianceQty;
  final num varianceAmount;
  final num varianceCharged;

  const LoadTotals({
    this.issuedQty = 0,
    this.soldQty = 0,
    this.returnedQty = 0,
    this.varianceQty = 0,
    this.varianceAmount = 0,
    this.varianceCharged = 0,
  });

  factory LoadTotals.fromJson(Map<String, dynamic> json) => LoadTotals(
    issuedQty: _num(json['issued_qty']),
    soldQty: _num(json['sold_qty']),
    returnedQty: _num(json['returned_qty']),
    varianceQty: _num(json['variance_qty']),
    varianceAmount: _num(json['variance_amount']),
    varianceCharged: _num(json['variance_charged']),
  );
}

const String kLoadStatusOpen = 'open';
const String kLoadStatusClosed = 'closed';

/// One consignment load.
class LoadData {
  final String id;
  final LoadShop? shop;
  final LoadDeliveryman? deliveryman;
  final String loadStatus;
  final DateTime? createdAt;

  /// Present on a `close_load` answer. The list serializer does not carry
  /// it, so a closed load read from `get_shop_loads` has none and the
  /// surface simply says nothing about when it closed.
  final DateTime? closedAt;
  final List<LoadLine> lines;

  /// Only `close_load` sends totals.
  final LoadTotals? totals;

  /// `close_load` answering a load that was already closed: no money
  /// moved on this call.
  final bool alreadyClosed;

  const LoadData({
    required this.id,
    required this.loadStatus,
    this.shop,
    this.deliveryman,
    this.createdAt,
    this.closedAt,
    this.lines = const [],
    this.totals,
    this.alreadyClosed = false,
  });

  factory LoadData.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'];
    final driver = json['deliveryman'];
    final totals = json['totals'];
    return LoadData(
      id: json['id']?.toString() ?? '',
      shop: shop is Map ? LoadShop.fromJson(shop.cast<String, dynamic>()) : null,
      deliveryman: driver is Map
          ? LoadDeliveryman.fromJson(driver.cast<String, dynamic>())
          : null,
      loadStatus: json['load_status']?.toString() ?? '',
      createdAt: _date(json['created_at']),
      closedAt: _date(json['closed_at']),
      lines: <LoadLine>[
        for (final line in (json['lines'] as List?) ?? const [])
          if (line is Map) LoadLine.fromJson(line.cast<String, dynamic>()),
      ],
      totals: totals is Map
          ? LoadTotals.fromJson(totals.cast<String, dynamic>())
          : null,
      alreadyClosed: json['already_closed'] == true,
    );
  }

  bool get isClosed => loadStatus == kLoadStatusClosed;

  /// The whole load's outstanding shortfall in money — what the confirm
  /// dialog has to name BEFORE the shop presses Close, because closing is
  /// what charges it to the driver.
  num get varianceAmount =>
      lines.fold<num>(0, (sum, line) => sum + line.varianceAmount);

  num get varianceQty =>
      lines.fold<num>(0, (sum, line) => sum + line.varianceQty);

  num get issuedQty => lines.fold<num>(0, (sum, line) => sum + line.issuedQty);

  num get remainingQty =>
      lines.fold<num>(0, (sum, line) => sum + line.remainingQty);
}

/// Loads whose `load_status` matches [status]; a null [status] keeps them
/// all. The list surface filters the one fetched set this way so switching
/// tabs never costs a round trip.
List<LoadData> filterLoadsByStatus(List<LoadData> loads, String? status) =>
    status == null
    ? List<LoadData>.unmodifiable(loads)
    : List<LoadData>.unmodifiable(
        loads.where((load) => load.loadStatus == status),
      );

num _clampToZero(num value) => value < 0 ? 0 : value;

num _num(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  final String text = value?.toString() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
