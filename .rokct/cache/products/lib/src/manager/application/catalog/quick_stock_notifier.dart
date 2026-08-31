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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/manager/application/catalog/quick_stock_state.dart';
import 'package:products_sdk/src/manager/application/seller_product_requests.dart';

/// The approved 35e quick-adjust surface's state machine: COUNTS ONLY —
/// steppers over the loaded stock rows, triage on Low/Out, one batch save.
/// Prices, SKUs, variants and add-ons are deliberately untouchable here so
/// the surface can never fork the form family (the approved scope tag).
///
/// The save RIDES THE EXISTING stock update call
/// ([SellerProductsRepositoryFacade.updateStocks], the same call the shipped
/// stocks tab makes): per changed product it resends that product's full
/// stock rows — quantities adjusted, every other field exactly as loaded, no
/// deletions — so no new backend surface exists for this build.
class QuickStockNotifier extends StateNotifier<QuickStockState> {
  QuickStockNotifier(this._repository) : super(const QuickStockState());

  final SellerProductsRepositoryFacade _repository;

  /// Builds the stepper rows from the loaded catalog. A product without any
  /// stock rows has nothing to count — creating its first stock (price
  /// required) is the form's job, so it is skipped here.
  void seedFrom(List<SellerProductData> products) {
    final rows = <QuickStockRow>[
      for (final product in products)
        if (product.id != null)
          for (var i = 0; i < (product.stocks?.length ?? 0); i++)
            QuickStockRow(
              product: product,
              stockIndex: i,
              original: product.stocks![i].quantity ?? 0,
              current: product.stocks![i].quantity ?? 0,
            ),
    ];
    state = state.copyWith(rows: rows);
  }

  void setFilter(QuickStockFilter filter) =>
      state = state.copyWith(filter: filter);

  void increment(String key) => _adjust(key, 1);

  void decrement(String key) => _adjust(key, -1);

  void _adjust(String key, int delta) {
    final rows = List<QuickStockRow>.from(state.rows);
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].key != key) continue;
      var next = rows[i].current + delta;
      if (next < 0) next = 0; // A shelf never holds -1.
      rows[i] = QuickStockRow(
        product: rows[i].product,
        stockIndex: rows[i].stockIndex,
        original: rows[i].original,
        current: next,
      );
      break;
    }
    state = state.copyWith(rows: rows);
  }

  /// Commits every dirty row, product by product, over the existing
  /// `updateStocks` endpoint. [updated] fires once after ALL products saved
  /// (the caller refreshes the catalog list); [failed] on the first failure
  /// (already-saved products stay saved — the rows are re-seeded from the
  /// refreshed list either way).
  Future<void> saveAll({
    void Function(int savedProducts)? updated,
    void Function()? failed,
  }) async {
    final dirtyByProduct = <String, List<QuickStockRow>>{};
    for (final row in state.rows) {
      if (row.dirty) {
        dirtyByProduct.putIfAbsent(row.product.id!, () => []).add(row);
      }
    }
    if (dirtyByProduct.isEmpty) {
      updated?.call(0);
      return;
    }
    state = state.copyWith(isSaving: true);
    var saved = 0;
    for (final entry in dirtyByProduct.entries) {
      final product = entry.value.first.product;
      final adjusted = <int, int>{
        for (final row in entry.value) row.stockIndex: row.current,
      };
      // The product's FULL stock list, quantities swapped in — everything
      // else (price, sku, extras, add-ons) rides through unchanged, and
      // nothing is deleted.
      final stocks = <SellerStock>[
        for (var i = 0; i < product.stocks!.length; i++)
          adjusted.containsKey(i)
              ? product.stocks![i].copyWith(quantity: adjusted[i])
              : product.stocks![i],
      ];
      final response = await _repository.updateStocks(
        uuid: product.uuid ?? '',
        stocks: buildStocksRequest(stocks),
      );
      final bool ok = response.when(
        success: (_) => true,
        failure: (fail, status) {
          state = state.copyWith(isSaving: false, error: fail.toString());
          return false;
        },
      );
      if (!ok) {
        failed?.call();
        return;
      }
      saved++;
    }
    state = state.copyWith(isSaving: false);
    updated?.call(saved);
  }
}
