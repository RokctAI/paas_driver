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

import 'package:flutter/material.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_category_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_gallery.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_unit_data.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/edit_food_details_state.dart';
import 'package:products_sdk/src/manager/application/seller_product_requests.dart';

/// Port of `paas_manager`'s `EditFoodDetailsNotifier` — the edit-product form:
/// multi-locale titles/descriptions, image management, and the update call.
///
/// Departures, per stage 2 conventions: no `BuildContext`/snackbars (failures
/// surface as `state.error`), the request map is built here
/// (`buildUpdateProductRequest`), and the app's step-by-step debug logging of
/// the active/tax plumbing was dropped as noise. `updateProduct` takes
/// `kitchenId` as a plain int where the app took a `KitchenModel` — kitchens
/// live in kitchen_sdk and ADR-005 forbids importing it.
class EditFoodDetailsNotifier extends StateNotifier<EditFoodDetailsState> {
  EditFoodDetailsNotifier(this._repository, this._galleryRepository)
      : super(const EditFoodDetailsState());

  final SellerProductsRepositoryFacade _repository;
  final GalleryRepositoryFacade _galleryRepository;

  String? _oldBarcode;

  void setTax(String value) {
    state = state.copyWith(tax: value.trim());
  }

  void setCostPrice(String value) {
    state = state.copyWith(costPrice: value.trim());
  }

  void setInterval(String value) {
    state = state.copyWith(interval: value.trim());
  }

  void setMaxQty(String value) {
    state = state.copyWith(maxQty: value.trim());
  }

  void setMinQty(String value) {
    state = state.copyWith(minQty: value.trim());
  }

  void setActive(bool? value) {
    final bool newActiveValue = value ?? !state.active;
    state = state.copyWith(active: newActiveValue);
    final product = state.product?.copyWith(active: newActiveValue);
    state = state.copyWith(product: product);
  }

  void setIsAdult(bool? value) {
    final bool newValue = value ?? !state.isAdult;
    state = state.copyWith(isAdult: newValue);
    final product = state.product?.copyWith(isAdult: newValue);
    state = state.copyWith(product: product);
  }

  Future<void> updateProduct({
    SellerUnitData? unit,
    String? kitchenId,
    SellerCategoryData? category,
    Function(SellerProductData?)? updated,
    VoidCallback? failed,
  }) async {
    state = state.copyWith(isLoading: true);
    setDesc();
    final List<String> imageUrl =
        List.from(state.listOfUrls.map((e) => e.path));
    if (state.images.isNotEmpty) {
      final imageResponse = await _galleryRepository.uploadMultiImage(
        state.images,
        UploadType.products,
      );
      imageResponse.when(
        success: (data) {
          imageUrl.addAll(data.data?.title ?? []);
        },
        failure: (failure, status) {
          debugPrint('==> upload product image fail: $failure');
          state = state.copyWith(isLoading: true, error: failure);
        },
      );
    }
    final response = await _repository.updateProduct(
      uuid: state.product?.uuid ?? '',
      product: buildUpdateProductRequest(
        titlesAndDescriptions: state.mapOfDesc,
        interval: state.interval,
        tax: state.tax,
        costPrice: state.costPrice,
        maxQty: state.maxQty,
        minQty: state.minQty,
        qrcode: state.barcode == _oldBarcode ? null : state.barcode,
        active: state.product?.active ?? false,
        isAdult: state.product?.isAdult ?? state.isAdult,
        categoryId: category?.id,
        unitId: unit?.id,
        kitchenId: kitchenId,
        images: imageUrl,
      ),
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        final updatedTranslation = state.product?.translation?.copyWith(
          title: state.title,
          description: state.description,
        );
        final updatedProduct = state.product?.copyWith(
          translation: updatedTranslation,
          tax: num.tryParse(state.tax),
          cost: num.tryParse(state.costPrice),
          maxQty: int.tryParse(state.maxQty),
          minQty: int.tryParse(state.minQty),
          barCode: state.barcode,
          active: state.active,
          isAdult: state.isAdult,
          interval: num.tryParse(state.interval),
          categoryId: category?.id,
          category: category,
          unit: unit,
          img: imageUrl.isEmpty ? null : imageUrl.first,
        );
        _oldBarcode = state.barcode;
        updated?.call(updatedProduct);
      },
      failure: (fail, status) {
        state = state.copyWith(isLoading: false, error: fail);
        debugPrint('===> product update fail $fail');
        failed?.call();
      },
    );
  }

  void setDesc() {
    final Map<String, List<String>> temp = Map.from(state.mapOfDesc);
    final String locale = state.language?.locale ??
        LocalStorage.getLanguage()?.locale ??
        'en';
    temp[locale] = [state.title, state.description];
    state = state.copyWith(mapOfDesc: temp);
  }

  void setBarcode(String value) {
    state = state.copyWith(barcode: value.trim());
  }

  void setDescription(String value) {
    state = state.copyWith(description: value.trim());
  }

  void setTitle(String value) {
    state = state.copyWith(title: value.trim());
  }

  void setImageFile(String file) {
    final List<String> list = List.from(state.images)..add(file);
    state = state.copyWith(images: list);
  }

  void setUploadImage(SellerGallery gallery) {
    final List<SellerGallery> list = List.from(state.listOfUrls)
      ..insert(0, gallery);
    state = state.copyWith(listOfUrls: list);
  }

  void deleteImage(String value) {
    final List<String> list = List.from(state.images)..remove(value);
    final List<SellerGallery> urls = List.from(state.listOfUrls)
      ..removeWhere((element) => element.path == value);
    state = state.copyWith(images: list, listOfUrls: urls);
  }

  void setFoodDetails(SellerProductData? product) {
    // Tax comes from the product level first (the seller's input); the stock
    // level is a fallback only — same resolution the app landed on.
    String taxValue = '';
    if (product?.tax != null) {
      taxValue = product!.tax.toString();
    } else if (product?.stocks?.isNotEmpty == true) {
      final stockTax = product?.stocks?.first.tax;
      if (stockTax != null) {
        taxValue = stockTax.toString();
      }
    }
    state = state.copyWith(
      product: product,
      listOfUrls: product?.galleries ?? [],
      images: [],
      minQty: product?.minQty?.toString() ?? '',
      maxQty: product?.maxQty?.toString() ?? '',
      tax: taxValue,
      costPrice: product?.cost?.toString() ?? '',
      interval: product?.interval?.toString() ?? '',
      title: product?.translation?.title ?? '',
      description: product?.translation?.description ?? '',
      barcode: product?.barCode ?? '',
      active: product?.active ?? false,
      isAdult: product?.isAdult ?? false,
    );
    _oldBarcode = product?.barCode;
    if (product?.uuid?.isNotEmpty == true) {
      getProductDetailsById(product!.uuid!);
    }
  }

  Future<void> getProductDetailsById(String productId) async {
    state = state.copyWith(isLoading: true);
    final response = await _repository.getProductDetails(productId);
    response.when(
      success: (data) async {
        String taxValue = state.tax;
        if (data.data?.tax != null) {
          taxValue = data.data!.tax.toString();
        } else if (data.data?.stocks?.isNotEmpty == true) {
          final stockTax = data.data?.stocks?.first.tax;
          if (stockTax != null) {
            taxValue = stockTax.toString();
          }
        }
        state = state.copyWith(
          product: data.data,
          isLoading: false,
          listOfUrls: data.data?.galleries ?? [],
          tax: taxValue,
          costPrice: data.data?.cost?.toString() ?? state.costPrice,
          active: data.data?.active ?? state.active,
          isAdult: data.data?.isAdult ?? state.isAdult,
        );
        if (data.data?.translations != null) {
          final Map<String, List<String>> temp = Map.from(state.mapOfDesc);
          final items = data.data?.translations;
          for (int i = 0; i < data.data!.translations!.length; i++) {
            temp[items?[i].locale ?? 'en'] = [
              items?[i].title ?? '',
              items?[i].description ?? '',
            ];
          }
          state = state.copyWith(mapOfDesc: temp);
        }
      },
      failure: (failure, s) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> get product details failure: $failure');
      },
    );
  }
}
