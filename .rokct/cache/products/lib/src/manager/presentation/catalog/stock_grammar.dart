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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';

/// The approved stock-state grammar (frames 35a/35f, Ray 2026-08-29 15:41Z
/// "approved: … 35a,35b,35c,35d,35e."): amber badge + amber count BELOW
/// [kLowStockThreshold], red badge + red price-replacement AT ZERO, silence
/// when healthy. The threshold is the line the parked paas_pos 32a idea drew
/// (`product_grid_item.dart`'s hardcoded `quantity < 10`), carried here as a
/// named constant — the thresholds are part of the approved design; a
/// per-shop setting is a possible later evolution, not this build.
const int kLowStockThreshold = 10;

/// One product's (or one stock row's) place in the stock-state grammar.
enum StockLevel {
  /// Quiet grey count, no badge.
  healthy,

  /// Amber badge ("Low · N left") + amber count: 0 < quantity < 10.
  low,

  /// Red badge + the price gives way to red "Out of stock": quantity == 0,
  /// or no stocks at all (the shipped food_item's own out-of-stock rule).
  out,
}

/// Pure helpers for the grammar — no widgets, unit-tested.
abstract final class StockGrammar {
  /// Level for a single quantity (a stock row, or a product total).
  static StockLevel levelFor(int quantity) {
    if (quantity <= 0) return StockLevel.out;
    if (quantity < kLowStockThreshold) return StockLevel.low;
    return StockLevel.healthy;
  }

  /// A product's sellable count: the sum of its stock rows' quantities.
  /// No stocks at all means nothing sellable — 0.
  static int productQuantity(SellerProductData product) {
    final List<SellerStock> stocks = product.stocks ?? const [];
    var total = 0;
    for (final stock in stocks) {
      total += stock.quantity ?? 0;
    }
    return total < 0 ? 0 : total;
  }

  /// A product's level: [StockLevel.out] when it has no stocks (the shipped
  /// food_item rendered red "Out of stock" exactly then) or its rows sum to
  /// zero; otherwise the level of the summed count.
  static StockLevel productLevel(SellerProductData product) {
    if (product.stocks == null || product.stocks!.isEmpty) {
      return StockLevel.out;
    }
    return levelFor(productQuantity(product));
  }
}

/// The profitability arithmetic behind the approved 35a Price/Cost/Margin
/// strip: CLIENT-SIDE, from the product's existing `price` (first stock) and
/// manager-only `cost` fields — margin = price − cost, percent of price.
/// The revenue-aggregates endpoint is group I's later work; this strip only
/// shows its own arithmetic (the 14:51Z profitability groundwork).
class ProductMargin {
  final num price;
  final num cost;

  const ProductMargin._({required this.price, required this.cost});

  /// Null when it cannot honestly be computed: no price, or cost missing /
  /// non-positive — the pane then shows the "cost not set" state instead of
  /// a fake 100% margin.
  static ProductMargin? of({num? price, num? cost}) {
    if (price == null || price <= 0) return null;
    if (cost == null || cost <= 0) return null;
    return ProductMargin._(price: price, cost: cost);
  }

  /// The product's margin, from its first stock's price and its cost field.
  static ProductMargin? ofProduct(SellerProductData product) {
    final stocks = product.stocks;
    final num? price =
        (stocks != null && stocks.isNotEmpty) ? stocks.first.price : null;
    return of(price: price, cost: product.cost);
  }

  /// Price − cost. Negative when the product sells below cost — shown, not
  /// hidden: that is exactly what the strip exists to surface.
  num get margin => price - cost;

  /// Margin as a percent of the selling price.
  double get percent => (margin / price) * 100;
}
