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

/// THE LOAD BEING PUT TOGETHER, before it is issued.
///
/// One line per shelf row (`Stock` docname), which is the only handle the
/// backend addresses quantities by. The rules live here as pure functions
/// so the issue screen's arithmetic — never two lines for one shelf row,
/// never more than the shelf holds, never a zero line on the wire — is
/// testable without a till.
library;

import 'package:orders_sdk/src/manager/domain/interface/shop_loads.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/product_data.dart';

/// One shelf row picked for the load.
class LoadDraftLine {
  /// The `Stock` docname; the load's identity for this line.
  final String stockId;

  /// What the row is called on screen.
  final String title;

  /// The shelf price, which is the price the load is issued at.
  final num unitPrice;

  /// What the shelf holds right now — the ceiling for [quantity], because
  /// issuing the load is what takes the goods off that shelf.
  final num available;

  final num quantity;

  const LoadDraftLine({
    required this.stockId,
    required this.title,
    required this.unitPrice,
    required this.available,
    required this.quantity,
  });

  LoadDraftLine copyWith({num? quantity}) => LoadDraftLine(
    stockId: stockId,
    title: title,
    unitPrice: unitPrice,
    available: available,
    quantity: quantity ?? this.quantity,
  );

  num get lineValue => quantity * unitPrice;
}

/// Sets the line's quantity, adding it when it is new and dropping it when
/// the quantity reaches zero. Clamped to what the shelf holds, because
/// issuing the load is what takes the goods off that shelf; a shelf row
/// with nothing on it is refused a line outright rather than clamped to
/// zero and left showing.
List<LoadDraftLine> setDraftQuantity(
  List<LoadDraftLine> lines,
  LoadDraftLine line,
  num quantity,
) {
  final num ceiling = line.available;
  final num wanted = (quantity < 0 || ceiling <= 0)
      ? 0
      : (quantity > ceiling ? ceiling : quantity);
  final int index = lines.indexWhere((l) => l.stockId == line.stockId);
  if (wanted <= 0) {
    if (index < 0) return List<LoadDraftLine>.unmodifiable(lines);
    return List<LoadDraftLine>.unmodifiable([
      for (int i = 0; i < lines.length; i++)
        if (i != index) lines[i],
    ]);
  }
  if (index < 0) {
    return List<LoadDraftLine>.unmodifiable([
      ...lines,
      line.copyWith(quantity: wanted),
    ]);
  }
  return List<LoadDraftLine>.unmodifiable([
    for (int i = 0; i < lines.length; i++)
      if (i == index) lines[i].copyWith(quantity: wanted) else lines[i],
  ]);
}

/// The quantity [stockId] currently carries, zero when it is not on the
/// draft at all.
num draftQuantityOf(List<LoadDraftLine> lines, String stockId) {
  for (final line in lines) {
    if (line.stockId == stockId) return line.quantity;
  }
  return 0;
}

/// What the whole draft is worth at shelf prices — the figure the review
/// step shows before the load goes out.
num draftLoadValue(List<LoadDraftLine> lines) =>
    lines.fold<num>(0, (sum, line) => sum + line.lineValue);

/// The draft as the wire rows `create_load` takes. Zero-quantity lines
/// never survive [setDraftQuantity], and this refuses them again rather
/// than letting the backend throw on one.
List<LoadIssueLine> draftIssueLines(List<LoadDraftLine> lines) => [
  for (final line in lines)
    if (line.quantity > 0)
      LoadIssueLine(stockId: line.stockId, quantity: line.quantity),
];

/// A load can be issued once a driver is named and at least one shelf row
/// carries a quantity.
bool canIssueLoad({
  required String? deliverymanId,
  required List<LoadDraftLine> lines,
}) =>
    (deliverymanId != null && deliverymanId.isNotEmpty) &&
    draftIssueLines(lines).isNotEmpty;

/// The draft line a picked product stands for.
///
/// The shelf row is `stocks.first` — the same row the POS product list
/// prices and counts every product by, so a load is put together off
/// exactly the shelf the walk-in till sells off. A product the shop
/// carries no stock row for has nothing to issue and answers null.
LoadDraftLine? loadDraftLineFromProduct(ProductData product) {
  final stocks = product.stocks;
  if (stocks == null || stocks.isEmpty) return null;
  final stock = stocks.first;
  final String? stockId = stock.id;
  if (stockId == null || stockId.isEmpty) return null;
  final String title = product.translation?.title ?? product.uuid ?? stockId;
  return LoadDraftLine(
    stockId: stockId,
    title: title,
    unitPrice: stock.price ?? 0,
    available: stock.quantity ?? 0,
    quantity: 0,
  );
}
