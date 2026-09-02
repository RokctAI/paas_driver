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
    this.isAdult = false,
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

  /// 18+ (adults only) flag sent as `is_adult` on the create request.
  final bool isAdult;
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
    bool? isAdult,
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
        isAdult: isAdult ?? this.isAdult,
        isCreating: isCreating ?? this.isCreating,
        images: images ?? this.images,
        listOfUrls: listOfUrls ?? this.listOfUrls,
        createdProduct:
            clearCreatedProduct ? null : (createdProduct ?? this.createdProduct),
        error: error,
      );
}
