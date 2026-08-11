import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orders_sdk/src/manager/domain/interface/pos_products.dart';

import 'products_state.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';

class ProductsNotifier extends StateNotifier<ProductsState> {
  final PosProductsRepositoryFacade _productsRepository;
  ProductsNotifier(this._productsRepository) : super(const ProductsState());

  Future<void> setProductDetails({
    required ProductData product,
    required List<Stock> cartStocks,
  }) async {
    final List<Stock> stocks = product.stocks ?? <Stock>[];
    state = state.copyWith(
      productData: product,
      initialStocks: stocks,
      selectedStock: null,
      stockCount: 0,
      typedExtras: [],
    );
    if (stocks.isNotEmpty) {
      final int groupsCount = stocks[0].extras?.length ?? 0;
      final List<int> selectedIndexes = List.filled(groupsCount, 0);
      initialSetSelectedIndexes(selectedIndexes, cartStocks: cartStocks);
    }
    getProductDetailsById( product.uuid ?? "",);
  }

  Future<void> getProductDetailsById(String productId) async {
      final response = await _productsRepository.getProductDetails(productId);
      response.when(
        success: (data) async {
          final List<Stock> stocks = data.data?.stocks ?? <Stock>[];
          state = state.copyWith(
            productData: data.data,
            initialStocks: stocks,
            isLoading: false,
          );
          if (stocks.isNotEmpty) {
            final int groupsCount = stocks[0].extras?.length ?? 0;
            final List<int> selectedIndexes = List.filled(groupsCount, 0);
            initialSetSelectedIndexes(selectedIndexes, cartStocks: stocks);
          }
        },
        failure: (failure, s) {
          debugPrint('==> get product details failure: $failure');
        },
      );

  }

  void updateIngredient(BuildContext context, int selectIndex) {
    List<AddonData>? data = state.selectedStock?.addons;
    data?[selectIndex].setActive = !(data[selectIndex].active ?? false);
    List<Stock>? stocks = state.productData?.stocks;
    Stock? newStock = stocks?.first.copyWith(addons: data);
    ProductData? product = state.productData;
    ProductData? newProduct = product?.copyWith(stocks: [newStock!]);
    state = state.copyWith(productData: newProduct);
  }

  void addIngredient(
      BuildContext context,
      int selectIndex,
      ) {
    if ((state.selectedStock?.addons?[selectIndex].product?.maxQty ?? 0) >
        (state.selectedStock?.addons?[selectIndex].quantity ?? 0) &&
        (state.selectedStock?.addons?[selectIndex].product?.stock?.quantity ??
            0) >
            (state.selectedStock?.addons?[selectIndex].quantity ?? 0)) {
      List<AddonData>? data = state.selectedStock?.addons;
      data?[selectIndex].setCount = (data[selectIndex].quantity ?? 0) + 1;
      List<Stock>? stocks = state.productData?.stocks;
      Stock? newStock = stocks?.first.copyWith(addons: data);
      ProductData? product = state.productData;
      ProductData? newProduct = product?.copyWith(stocks: [newStock!]);
      state = state.copyWith(productData: newProduct);
    }
  }

  void removeIngredient(BuildContext context, int selectIndex) {
    if ((state.selectedStock?.addons?[selectIndex].product?.minQty ?? 0) <
        (state.selectedStock?.addons?[selectIndex].quantity ?? 0)) {
      List<AddonData>? data = state.selectedStock?.addons;
      data?[selectIndex].setCount = (data[selectIndex].quantity ?? 0) - 1;
      List<Stock>? stocks = state.productData?.stocks;
      Stock? newStock = stocks?.first.copyWith(addons: data);
      ProductData? product = state.productData;
      ProductData? newProduct = product?.copyWith(stocks: [newStock!]);
      state = state.copyWith(productData: newProduct);
    }
  }

  void updateSelectedIndexes(
    int index,
    int value, {
    required List<Stock> cartStocks,
  }) {
    final newList = state.selectedIndexes.sublist(0, index);
    newList.add(value);
    final postList =
        List.filled(state.selectedIndexes.length - newList.length, 0);
    newList.addAll(postList);
    initialSetSelectedIndexes(newList, cartStocks: cartStocks);
  }

  void initialSetSelectedIndexes(
    List<int> indexes, {
    required List<Stock> cartStocks,
  }) {
    state = state.copyWith(selectedIndexes: indexes);
    updateExtras(cartStocks: cartStocks);
  }

  void updateExtras({required List<Stock> cartStocks}) {
    final int groupsCount = state.initialStocks[0].extras?.length ?? 0;
    final List<TypedExtra> groupExtras = [];
    for (int i = 0; i < groupsCount; i++) {
      if (i == 0) {
        final TypedExtra extras = getFirstExtras(state.selectedIndexes[0]);
        groupExtras.add(extras);
      } else {
        final TypedExtra extras =
            getUniqueExtras(groupExtras, state.selectedIndexes, i);
        groupExtras.add(extras);
      }
    }
    Stock? selectedStock = getSelectedStock(groupExtras);
    int cartCount = 0;
    for (final cartStock in cartStocks) {
      if (cartStock.id == selectedStock?.id) {
        selectedStock = selectedStock?.copyWith(cartCount: cartStock.cartCount);
        cartCount = cartStock.cartCount ?? 0;
      }
    }
    state = state.copyWith(
      typedExtras: groupExtras,
      selectedStock: selectedStock,
      stockCount: cartCount,
    );
  }

  Stock? getSelectedStock(List<TypedExtra> groupExtras) {
    List<Stock> stocks = List.from(state.initialStocks);
    for (int i = 0; i < groupExtras.length; i++) {
      String selectedExtrasValue =
          groupExtras[i].uiExtras[state.selectedIndexes[i]].value;
      stocks = getSelectedStocks(stocks, selectedExtrasValue, i);
    }
    return stocks[0];
  }

  List<Stock> getSelectedStocks(List<Stock> stocks, String value, int index) {
    List<Stock> included = [];
    for (int i = 0; i < stocks.length; i++) {
      if ((stocks[i].extras?.length ?? 0) >= (index + 1)) {
        if (stocks[i].extras?[index].value == value) {
          included.add(stocks[i]);
        }
      }
    }
    return included;
  }

  TypedExtra getFirstExtras(int selectedIndex) {
    ExtrasType type = ExtrasType.text;
    String title = '';
    final List<String> uniques = [];
    for (int i = 0; i < state.initialStocks.length; i++) {
      if (state.initialStocks[i].extras?.isNotEmpty ?? false) {
        uniques.add(state.initialStocks[i].extras?[0].value ?? '');
        title =
            state.initialStocks[i].extras?[0].group?.translation?.title ?? '';
        type = AppHelpers.getExtraTypeByValue(
            state.initialStocks[i].extras?[0].group?.type);
      }
    }
    final setOfUniques = uniques.toSet().toList();
    final List<UiExtra> extras = [];
    for (int i = 0; i < setOfUniques.length; i++) {
      if (selectedIndex == i) {
        extras.add(UiExtra(setOfUniques[i], true, i));
      } else {
        extras.add(UiExtra(setOfUniques[i], false, i));
      }
    }
    return TypedExtra(type, extras, title, 0);
  }

  TypedExtra getUniqueExtras(
    List<TypedExtra> groupExtras,
    List<int> selectedIndexes,
    int index,
  ) {
    List<Stock> includedStocks = List.from(state.initialStocks);
    for (int i = 0; i < groupExtras.length; i++) {
      final String includedValue =
          groupExtras[i].uiExtras[selectedIndexes[i]].value;
      includedStocks = getIncludedStocks(includedStocks, i, includedValue);
    }
    final List<String> uniques = [];
    String title = '';
    ExtrasType type = ExtrasType.text;
    for (int i = 0; i < includedStocks.length; i++) {
      uniques.add(includedStocks[i].extras?[index].value ?? '');
      title = includedStocks[i].extras?[index].group?.translation?.title ?? '';
      type = AppHelpers.getExtraTypeByValue(
          includedStocks[i].extras?[index].group?.type ?? '');
    }
    final setOfUniques = uniques.toSet().toList();
    final List<UiExtra> extras = [];
    for (int i = 0; i < setOfUniques.length; i++) {
      if (selectedIndexes[groupExtras.length] == i) {
        extras.add(UiExtra(setOfUniques[i], true, i));
      } else {
        extras.add(UiExtra(setOfUniques[i], false, i));
      }
    }
    return TypedExtra(type, extras, title, index);
  }

  List<Stock> getIncludedStocks(
    List<Stock> includedStocks,
    int index,
    String includedValue,
  ) {
    List<Stock> stocks = [];
    for (int i = 0; i < includedStocks.length; i++) {
      if ((includedStocks[i].extras?.length ?? 0) >= (index + 1)) {
        if (includedStocks[i].extras?[index].value == includedValue) {
          stocks.add(includedStocks[i]);
        }
      }
    }
    return stocks;
  }

  void increaseStockCount({required Function(int) updateCart}) {
    if ((state.selectedStock?.quantity ?? 0) <
        (state.productData?.minQty ?? 0)) {
      return;
    }
    int newCount = state.stockCount;
    if (newCount >= (state.productData?.maxQty ?? 100000) ||
        newCount >= (state.selectedStock?.quantity ?? 100000)) {
      return;
    }
    if (newCount < (state.productData?.minQty ?? 0)) {
      newCount = state.productData?.minQty ?? 1;
    } else {
      newCount = newCount + 1;
    }
    state = state.copyWith(stockCount: newCount);
    updateCart(newCount);
  }

  void decreaseStockCount({required Function(int) updateCart}) {
    int newCount = state.stockCount;
    if (newCount < 1) {
      return;
    }
    if (newCount <= (state.productData?.minQty ?? 0)) {
      newCount = 0;
    } else {
      newCount = newCount - 1;
    }
    state = state.copyWith(stockCount: newCount);
    updateCart(newCount);
  }
}
