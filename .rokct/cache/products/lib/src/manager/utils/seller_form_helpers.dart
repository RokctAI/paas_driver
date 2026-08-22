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

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';

/// Form validators and display helpers for the seller product-authoring pages.
///
/// The app kept these on its global `AppValidators`/`AppHelpers`; base_sdk's
/// copies never grew the quantity checks or the addon-typed helpers (they are
/// typed on this SDK's seller models), so they live here with the only slice
/// that uses them. Messages come from the same translation keys the app used —
/// `cannotBeEmpty` is already a base key, the two quantity messages are
/// declared in this SDK's manifest `tr_keys`.
abstract class SellerFormValidators {
  static String? emptyCheck(String? text) {
    if (text == null || text.trim().isEmpty) {
      return AppHelpers.getTranslation(TrKeys.cannotBeEmpty);
    }
    return null;
  }

  static String? minQtyCheck(String? min) {
    if (min == null || min.isEmpty) {
      return AppHelpers.getTranslation(TrKeys.cannotBeEmpty);
    }
    if (double.tryParse(min)?.isNegative ?? true) {
      return AppHelpers.getTranslation('min_quantity_error');
    }
    return null;
  }

  static String? maxQtyCheck(String? max, String? min) {
    if (max == null || max.isEmpty) {
      return AppHelpers.getTranslation(TrKeys.cannotBeEmpty);
    }
    if (min != null) {
      if ((num.tryParse(min) ?? 0) > (num.tryParse(max) ?? 0)) {
        return AppHelpers.getTranslation('max_qty_should_be_greater_than_min_qty');
      }
    }
    return null;
  }
}

/// Addon display helpers the app carried on `AppHelpers`, retyped on the
/// seller models.
abstract class SellerAddonHelpers {
  static String getInitialAddonPrice(SellerProductData addon) {
    return addon.stock?.price?.toString() ?? '';
  }

  static String getInitialAddonQuantity(SellerProductData addon) {
    return addon.stock?.quantity == null
        ? ''
        : addon.stock?.quantity.toString() ?? '';
  }

  static String? selectedAddonsTitles(SellerStock stock) {
    final List<SellerAddonData> addons = stock.localAddons ?? [];
    if (addons.isEmpty) {
      return null;
    }
    String text = '${addons[0].product?.translation?.title}';
    if (addons.length > 1) {
      for (int i = 1; i < addons.length; i++) {
        text =
            '$text${i != addons.length ? ',' : ''} ${addons[i].product?.translation?.title} ';
      }
    }
    return text;
  }
}
