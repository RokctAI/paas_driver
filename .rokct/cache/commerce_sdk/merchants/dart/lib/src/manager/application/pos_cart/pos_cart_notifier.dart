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

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ApiResult's `when` lives in the freezed extension declared by this
// library, so the import is load-bearing even though no type is named.
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_catalog.dart';

/// The POS till's cart (the BillingPage scan/add/cart flow and the
/// CheckoutPage both ride this one notifier).
///
/// Port of the retired Spazafy `orderCartProvider.addStockByBarcode` idea
/// onto base_sdk's real `ProductData`/`Stocks` model family, with the held
/// build's found bugs designed out:
/// - scan dedupe: a barcode that re-fires within [scanDedupeWindow] is
///   ignored, so a camera frame-stream can never machine-gun one physical
///   scan into N cart lines;
/// - the order id is minted ONCE per order (first line into an empty
///   cart), never in a build method — the pay-link QR and the offline
///   verification code stay keyed to one stable id for the order's life;
/// - the total is derived state (see PosCartState), so Clear All can never
///   leave a stale total behind.
class PosCartNotifier extends StateNotifier<PosCartState> {
  PosCartNotifier(this._catalog) : super(const PosCartState());

  final PosCatalogRepositoryFacade _catalog;

  /// A repeat of the SAME barcode inside this window is one physical scan.
  static const Duration scanDedupeWindow = Duration(seconds: 2);

  String? _lastBarcode;
  DateTime? _lastScanAt;
  final Random _random = Random();

  /// Barcode lane. Returns true when the scan was accepted and landed a
  /// product in the cart (the page haptics on true), false when it was
  /// deduped or nothing matched.
  Future<bool> addByBarcode(String barcode) async {
    if (barcode.isEmpty) return false;
    final now = DateTime.now();
    if (barcode == _lastBarcode &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < scanDedupeWindow) {
      // Same physical scan still in front of the camera — never re-add
      // per frame (held-build finding).
      _lastScanAt = now;
      return false;
    }
    _lastBarcode = barcode;
    _lastScanAt = now;

    state = state.copyWith(isLoading: true);
    final result = await _catalog.searchProducts(text: barcode);
    var added = false;
    result.when(
      success: (data) {
        final products = data.data ?? const <ProductData>[];
        if (products.isNotEmpty) {
          addProduct(products.first);
          added = true;
        }
      },
      failure: (error, statusCode) {},
    );
    if (mounted) state = state.copyWith(isLoading: false);
    return added;
  }

  /// Manual "Add Items" lane search (by name or barcode).
  Future<void> search(String text) async {
    if (text.trim().isEmpty) {
      state = state.copyWith(searchResults: const [], isSearching: false);
      return;
    }
    state = state.copyWith(isSearching: true);
    final result = await _catalog.searchProducts(text: text.trim());
    if (!mounted) return;
    result.when(
      success: (data) => state = state.copyWith(
        searchResults: data.data ?? const [],
        isSearching: false,
      ),
      failure: (error, statusCode) =>
          state = state.copyWith(isSearching: false),
    );
  }

  /// Drops a product into the cart: an existing line for the same stock
  /// steps +1, a new product opens a quantity-1 line. Mints the stable
  /// order id when the cart was empty.
  void addProduct(ProductData product) {
    final stock = (product.stocks?.isNotEmpty ?? false)
        ? product.stocks!.first
        : (product.stock ?? Stocks());
    final lines = [...state.lines];
    final index = lines.indexWhere(
      (l) => l.stock.id == stock.id && l.product.id == product.id,
    );
    if (index >= 0) {
      lines[index] =
          lines[index].copyWith(quantity: lines[index].quantity + 1);
    } else {
      lines.add(PosCartLine(product: product, stock: stock, quantity: 1));
    }
    state = state.copyWith(
      lines: lines,
      orderId: state.orderId.isEmpty ? _mintOrderId() : state.orderId,
    );
  }

  void increment(int index) {
    if (index < 0 || index >= state.lines.length) return;
    final lines = [...state.lines];
    lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);
    state = state.copyWith(lines: lines);
  }

  void decrement(int index) {
    if (index < 0 || index >= state.lines.length) return;
    final next = state.lines[index].quantity - 1;
    if (next <= 0) {
      removeLine(index);
      return;
    }
    final lines = [...state.lines];
    lines[index] = lines[index].copyWith(quantity: next);
    state = state.copyWith(lines: lines);
  }

  /// Decimal quantity edit (weighed kg/L units). Zero or negative removes
  /// the line.
  void setQuantity(int index, double quantity) {
    if (index < 0 || index >= state.lines.length) return;
    if (quantity <= 0) {
      removeLine(index);
      return;
    }
    final lines = [...state.lines];
    lines[index] = lines[index].copyWith(quantity: quantity);
    state = state.copyWith(lines: lines);
  }

  void removeLine(int index) {
    if (index < 0 || index >= state.lines.length) return;
    final lines = [...state.lines]..removeAt(index);
    // Emptying the cart closes the order — the next first line mints a
    // fresh id (same rule as clearAll).
    state = lines.isEmpty
        ? const PosCartState()
        : state.copyWith(lines: lines);
  }

  /// Clear All: back to the empty state. The total is a derived getter,
  /// so it reads 0 the moment the lines go — the Spazafy stale-total bug
  /// cannot reoccur.
  void clearAll() => state = const PosCartState();

  /// Completes the sale: returns the finished order's identity for the
  /// receipt, then resets the cart (a new order id is minted on the next
  /// first scan). Recording the sale against the backend order queue is
  /// the checkout's sync seam, deliberately outside this cart.
  ({String orderId, double total}) finishSale() {
    final receipt = (orderId: state.orderId, total: state.total);
    state = const PosCartState();
    return receipt;
  }

  /// 'POS-<millis>-<4 random digits>' — unique enough for a single till,
  /// stable for the order's life (held-build finding: never mint in build).
  String _mintOrderId() =>
      'POS-${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(10000).toString().padLeft(4, '0')}';
}
