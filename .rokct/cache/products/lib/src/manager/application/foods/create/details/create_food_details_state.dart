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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_gallery.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class CreateFoodDetailsState {
  const CreateFoodDetailsState({
    this.title = '',
    this.description = '',
    this.tax = '',
    this.costPrice = '',
    this.minQty = '',
    this.maxQty = '',
    this.qrcode = '',
    this.interval = '',
    this.active = true,
    this.isCreating = false,
    this.images = const [],
    this.listOfUrls = const [],
    this.createdProduct,
    this.error,
  });

  final String title;
  final String description;
  final String tax;

  /// Manager-only cost price; empty means "not provided" and the create
  /// request omits the field entirely.
  final String costPrice;
  final String minQty;
  final String maxQty;
  final String qrcode;
  final String interval;
  final bool active;
  final bool isCreating;

  /// Local file paths picked but not yet uploaded.
  final List<String> images;

  /// Already-uploaded gallery entries.
  final List<SellerGallery> listOfUrls;
  final SellerProductData? createdProduct;

  /// Set on a failed upload or create; the page decides how to show it. The
  /// app raised a snackbar from inside the notifier.
  final String? error;

  /// [createdProduct] is nullable-through: passing null clears it (the app's
  /// freezed copyWith did the same on `updateAddFoodInfo`). [error] clears
  /// unless passed, per the stage 2 convention.
  CreateFoodDetailsState copyWith({
    String? title,
    String? description,
    String? tax,
    String? costPrice,
    String? minQty,
    String? maxQty,
    String? qrcode,
    String? interval,
    bool? active,
    bool? isCreating,
    List<String>? images,
    List<SellerGallery>? listOfUrls,
    SellerProductData? createdProduct,
    bool clearCreatedProduct = false,
    String? error,
  }) =>
      CreateFoodDetailsState(
        title: title ?? this.title,
        description: description ?? this.description,
        tax: tax ?? this.tax,
        costPrice: costPrice ?? this.costPrice,
        minQty: minQty ?? this.minQty,
        maxQty: maxQty ?? this.maxQty,
        qrcode: qrcode ?? this.qrcode,
        interval: interval ?? this.interval,
        active: active ?? this.active,
        isCreating: isCreating ?? this.isCreating,
        images: images ?? this.images,
        listOfUrls: listOfUrls ?? this.listOfUrls,
        createdProduct:
            clearCreatedProduct ? null : (createdProduct ?? this.createdProduct),
        error: error,
      );
}
