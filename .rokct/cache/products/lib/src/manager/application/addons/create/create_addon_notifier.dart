// Copyright (c) 2026 RokctAI
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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/manager/application/addons/create/create_addon_state.dart';
import 'package:products_sdk/src/manager/application/seller_product_requests.dart';

/// Port of `paas_manager`'s `CreateAddonNotifier` — creates an addon as a
/// product with `addon: 1`, then saves its single stock (price + quantity).
///
/// Departures per stage 2 conventions: no `BuildContext`/snackbars (failures
/// surface as `state.error`), and the request maps are built here because the
/// facade takes ready maps.
class CreateAddonNotifier extends StateNotifier<CreateAddonState> {
  CreateAddonNotifier(this._repository) : super(const CreateAddonState());

  final SellerProductsRepositoryFacade _repository;

  String _title = '';
  String _description = '';
  String _tax = '';
  String _barcode = '';
  String _price = '';
  String _quantity = '';
  bool _active = true;

  void setQuantity(String value) {
    _quantity = value.trim();
  }

  void setPrice(String value) {
    _price = value.trim();
  }

  void updateAddonInfo() {
    _title = '';
    _description = '';
    _tax = '';
    _barcode = '';
    _active = true;
  }

  Future<void> createAddon({
    int? unitId,
    VoidCallback? created,
    VoidCallback? failed,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.createProduct(
      product: buildCreateProductRequest(
        title: _title,
        description: _description,
        tax: _tax,
        minQty: '1',
        maxQty: '10000',
        interval: '1',
        active: _active,
        qrcode: _barcode,
        unitId: unitId,
        isAddon: true,
      ),
    );
    response.when(
      success: (data) async {
        final stockResponse = await _repository.updateStocks(
          uuid: data.data?.uuid ?? '',
          stocks: buildStocksRequest([
            SellerStock(
              quantity: int.tryParse(_quantity),
              price: num.tryParse(_price),
              sku: _barcode,
            ),
          ]),
          isAddon: true,
        );
        stockResponse.when(
          success: (stockData) {
            created?.call();
            state = state.copyWith(isLoading: false);
          },
          failure: (stockFail, status) {
            debugPrint('===> create addon stock fail $stockFail');
            failed?.call();
            state = state.copyWith(isLoading: false, error: stockFail);
          },
        );
      },
      failure: (fail, status) {
        debugPrint('===> create addon fail $fail');
        state = state.copyWith(isLoading: false, error: fail);
        failed?.call();
      },
    );
  }

  void setActive(bool? value) {
    _active = value ?? false;
  }

  void setTax(String value) {
    _tax = value.trim();
  }

  void setBarcode(String value) {
    _barcode = value.trim();
  }

  void setDescription(String value) {
    _description = value.trim();
  }

  void setTitle(String value) {
    _title = value.trim();
  }
}
