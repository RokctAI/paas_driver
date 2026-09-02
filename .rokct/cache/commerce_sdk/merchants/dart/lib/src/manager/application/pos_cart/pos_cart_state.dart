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

import 'package:base_sdk/src/models/data/product_data.dart';

/// Cents rounding for POS money math.
///
/// Every amount that leaves this state (line totals, the cart total, the
/// item-count chip) is rounded to cents AT THE STATE BOUNDARY, so float
/// accumulation (`18.99 * 3 + 150 * 0.75` = `169.47000000000003`) can never
/// reach a formatter as a long float. The retired Spazafy port let the raw
/// sum through, and any non-terminating total overflowed `numberFormat`'s
/// 16-char guard into its `toStringAsExponential` branch — the on-screen
/// "R1.0473000000e+2" bug (approved strip, section 8, chip 241).
double posRoundCents(num value) => (value * 100).roundToDouble() / 100;

/// One cart line: a base_sdk [ProductData] + the [Stocks] entry being sold
/// and a DECIMAL quantity (weighed goods sell fractional kg/L — the strip's
/// "Loose Tomatoes (kg) × 0.75", section 11a chip 282).
///
/// Built on base_sdk's REAL model family (`product_data.dart`'s
/// `ProductData`/`Stocks`). The Spazafy source was written against a
/// phantom parallel family (`Stock.cartCount`/`.addons`/`.copyWith` on
/// classes its imports never declared — compile error #2 of the five), so
/// the cart keeps its own quantity here instead of mutating the model.
class PosCartLine {
  const PosCartLine({
    required this.product,
    required this.stock,
    required this.quantity,
  });

  final ProductData product;
  final Stocks stock;
  final double quantity;

  num get unitPrice => stock.price ?? 0;

  /// Line total, cents-rounded at the boundary (see [posRoundCents]).
  double get lineTotal => posRoundCents(unitPrice * quantity);

  String get title => product.translation?.title ?? '';

  PosCartLine copyWith({double? quantity}) => PosCartLine(
        product: product,
        stock: stock,
        quantity: quantity ?? this.quantity,
      );
}

/// Plain immutable state with a hand-written `copyWith` (main_state.dart's
/// convention — no freezed, no build_runner pass needed standalone).
///
/// The total and item count are DERIVED getters, never stored fields: the
/// Spazafy source cached the running total next to the list and its Clear
/// All button emptied the list without resetting the cached sum (the
/// stale-total bug found in the held build's review). A derived total
/// cannot go stale by construction.
class PosCartState {
  const PosCartState({
    this.lines = const [],
    this.orderId = '',
    this.isLoading = false,
    this.searchResults = const [],
    this.isSearching = false,
  });

  final List<PosCartLine> lines;

  /// Stable per order: minted when the first line lands in an empty cart
  /// and unchanged until the sale finishes (or the cart is cleared). The
  /// held build's review found the id being re-minted on every widget
  /// rebuild — which re-keyed the pay-link QR and the offline verification
  /// code mid-checkout — so the id lives HERE, never in a build method.
  final String orderId;

  /// A barcode lookup or manual search is in flight.
  final bool isLoading;

  /// Manual "Add Items" lane search results.
  final List<ProductData> searchResults;
  final bool isSearching;

  /// Sum of quantities (decimal — weighed lines count fractionally), for
  /// the cart chip ("2.75").
  double get itemCount =>
      posRoundCents(lines.fold<double>(0, (sum, l) => sum + l.quantity));

  /// Cart total: the sum of already-cents-rounded line totals, rounded
  /// again at the boundary. `18.99×3 + 150×0.75` is exactly `169.47`.
  double get total =>
      posRoundCents(lines.fold<double>(0, (sum, l) => sum + l.lineTotal));

  bool get isEmpty => lines.isEmpty;

  PosCartState copyWith({
    List<PosCartLine>? lines,
    String? orderId,
    bool? isLoading,
    List<ProductData>? searchResults,
    bool? isSearching,
  }) =>
      PosCartState(
        lines: lines ?? this.lines,
        orderId: orderId ?? this.orderId,
        isLoading: isLoading ?? this.isLoading,
        searchResults: searchResults ?? this.searchResults,
        isSearching: isSearching ?? this.isSearching,
      );
}
