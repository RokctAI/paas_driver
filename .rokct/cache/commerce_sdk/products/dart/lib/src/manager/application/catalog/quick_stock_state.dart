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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_grammar.dart';

/// The 35e triage chips: All / Low stock N / Out N.
enum QuickStockFilter { all, low, out }

/// One stepper row of the approved quick-adjust surface — one STOCK row of
/// one product (a product with variants gets a row per variant, labelled by
/// the extras combination that made it).
class QuickStockRow {
  const QuickStockRow({
    required this.product,
    required this.stockIndex,
    required this.original,
    required this.current,
  });

  final SellerProductData product;

  /// Index into `product.stocks` — the row's identity together with the
  /// product id (stock ids can be absent on offline-created rows).
  final int stockIndex;

  /// The quantity as loaded — the baseline a change is measured against.
  final int original;

  /// The adjusted quantity (never below zero).
  final int current;

  String get key => '${product.id}#$stockIndex';

  SellerStock get stock => product.stocks![stockIndex];

  bool get dirty => current != original;

  /// TRIAGE is judged on the LOADED quantity, so a row stays in the Low
  /// list while being corrected instead of jumping out mid-count.
  StockLevel get level => StockGrammar.levelFor(original);

  /// The current count's display level (drives the amber/red count color).
  StockLevel get currentLevel => StockGrammar.levelFor(current);

  /// "STANDARD · CHAKALAKA" — derived from the extras combination that made
  /// the row; null for a variant-less product (the row is the product).
  String? get variantLabel {
    final List<SellerExtras> extras = stock.extras ?? const [];
    final values = [
      for (final extra in extras)
        if ((extra.value ?? '').isNotEmpty) extra.value!.toUpperCase(),
    ];
    if (values.isEmpty) return null;
    return values.join(' · ');
  }
}

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class QuickStockState {
  const QuickStockState({
    this.rows = const [],
    this.filter = QuickStockFilter.all,
    this.isSaving = false,
    this.error,
  });

  final List<QuickStockRow> rows;
  final QuickStockFilter filter;
  final bool isSaving;
  final String? error;

  List<QuickStockRow> get visibleRows => switch (filter) {
        QuickStockFilter.all => rows,
        QuickStockFilter.low =>
          rows.where((r) => r.level == StockLevel.low).toList(),
        QuickStockFilter.out =>
          rows.where((r) => r.level == StockLevel.out).toList(),
      };

  int get lowCount => rows.where((r) => r.level == StockLevel.low).length;

  int get outCount => rows.where((r) => r.level == StockLevel.out).length;

  int get dirtyCount => rows.where((r) => r.dirty).length;

  QuickStockState copyWith({
    List<QuickStockRow>? rows,
    QuickStockFilter? filter,
    bool? isSaving,
    String? error,
  }) =>
      QuickStockState(
        rows: rows ?? this.rows,
        filter: filter ?? this.filter,
        isSaving: isSaving ?? this.isSaving,
        error: error,
      );
}
