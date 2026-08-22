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
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:products_sdk/src/manager/application/addons/edit/edit_addon_state.dart';
import 'package:products_sdk/src/manager/application/seller_product_requests.dart';

/// Port of `paas_manager`'s `EditAddonNotifier` — updates the addon product,
/// then saves its single stock. The app read the initial price/quantity via
/// `AppHelpers.getInitialAddon{Price,Quantity}`; those one-liners are inlined
/// here rather than widening base_sdk.
///
/// Departures per stage 2 conventions: no `BuildContext`/snackbars (failures
/// surface as `state.error`), request maps built here.
class EditAddonNotifier extends StateNotifier<EditAddonState> {
  EditAddonNotifier(this._repository) : super(const EditAddonState());

  final SellerProductsRepositoryFacade _repository;

  String _oldBarcode = '';
  String _tax = '';
  String _barcode = '';
  String _description = '';
  String _title = '';
  String _quantity = '';
  String _price = '';
  bool _active = true;

  void setQuantity(String value) {
    _quantity = value.trim();
  }

  void setPrice(String value) {
    _price = value.trim();
  }

  void setTax(String value) {
    _tax = value.trim();
  }

  void setActive(bool? value) {
    _active = !_active;
  }

  void setDesc() {
    final Map<String, List<String>> temp = Map.from(state.mapOfDesc);
    final String locale = LocalStorage.getLanguage()?.locale ?? 'en';
    temp[locale] = [_title, _description];
    state = state.copyWith(mapOfDesc: temp);
  }

  Future<void> updateAddon({
    String? uuid,
    SellerUnitData? unit,
    VoidCallback? updated,
    VoidCallback? failed,
  }) async {
    setDesc();
    state = state.copyWith(isLoading: true);
    final response = await _repository.updateProduct(
      uuid: uuid ?? '',
      product: buildUpdateProductRequest(
        titlesAndDescriptions: state.mapOfDesc,
        interval: '1',
        tax: _tax,
        maxQty: '10000',
        minQty: '1',
        qrcode: _barcode == _oldBarcode ? null : _barcode,
        active: _active,
        unitId: unit?.id,
        needAddons: true,
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
            ),
          ]),
          isAddon: true,
        );
        stockResponse.when(
          success: (stockData) {
            updated?.call();
            state = state.copyWith(isLoading: false);
          },
          failure: (stockFail, status) {
            debugPrint('===> update addon stock fail $stockFail');
            failed?.call();
            state = state.copyWith(isLoading: false, error: stockFail);
          },
        );
      },
      failure: (fail, status) {
        state = state.copyWith(isLoading: false, error: fail);
        debugPrint('===> addon update fail $fail');
        failed?.call();
      },
    );
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

  void setAddonDetails(SellerProductData addon) {
    _tax = addon.tax == null ? '' : addon.tax.toString();
    _title = addon.translation?.title ?? '';
    _description = addon.translation?.description ?? '';
    _oldBarcode = addon.barCode ?? '';
    _barcode = addon.barCode ?? '';
    _price = addon.stock?.price?.toString() ?? '';
    _quantity = addon.stock?.quantity == null
        ? ''
        : addon.stock?.quantity.toString() ?? '';
    _active = addon.active ?? false;
    if (addon.translations != null) {
      final Map<String, List<String>> temp = Map.from(state.mapOfDesc);
      final items = addon.translations;
      for (int i = 0; i < addon.translations!.length; i++) {
        temp[items?[i].locale ?? 'en'] = [
          items?[i].title ?? '',
          items?[i].description ?? '',
        ];
      }
      state = state.copyWith(mapOfDesc: temp);
    }
  }
}
