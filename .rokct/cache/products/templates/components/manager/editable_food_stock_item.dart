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
import 'package:remixicon/remixicon.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_stock.dart';
import 'package:products_sdk/src/manager/utils/seller_form_helpers.dart';
import 'package:base_sdk/src/presentation/components/text_fields/underlined_text_field.dart';
import 'package:${package}/presentation/pages/main/widgets/buttons_bouncing_effect.dart';

/// One STOCK VARIANT card of the approved edit form (frame 35b's variant
/// cards): the variant label derived from the extras combination that made
/// the row ("STANDARD · CHAKALAKA" — the shipped rows were unlabelled; the
/// label is the approved dress, the fields are the shipped fields), then
/// price* / quantity* / SKU and the per-variant add-ons door. Delete rides
/// the header on every row but the first (the shipped `isDeletable` rule).
class EditableFoodStockItem extends StatelessWidget {
  final SellerStock stock;
  final Function(String) onPriceChange;
  final Function(String) onQuantityChange;
  final Function(String) onSkuChange;
  final Function() onDeleteStock;
  final bool isDeletable;
  final Function(BuildContext) onAddonTap;

  const EditableFoodStockItem({
    super.key,
    required this.stock,
    required this.onPriceChange,
    required this.onQuantityChange,
    required this.onDeleteStock,
    required this.isDeletable,
    required this.onAddonTap,
    required this.onSkuChange,
  });

  /// "STANDARD · CHAKALAKA" from the row's extras values; null when the
  /// product has no variants (the row IS the product).
  String? get _variantLabel {
    final List<SellerExtras> extras = stock.extras ?? const [];
    final values = [
      for (final extra in extras)
        if ((extra.value ?? '').isNotEmpty) extra.value!.toUpperCase(),
    ];
    return values.isEmpty ? null : values.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final String? label = _variantLabel;
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      padding: REdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: REdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null || isDeletable)
            Row(
              children: [
                Expanded(
                  child: Text(
                    label ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interSemi(
                      size: 13.sp,
                      color: AppStyle.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (isDeletable)
                  ButtonsBouncingEffect(
                    child: GestureDetector(
                      onTap: onDeleteStock,
                      child: Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: AppStyle.cardDarkAlt,
                          border: Border.all(color: AppStyle.strokeDark),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Remix.delete_bin_line,
                          size: 16.r,
                          color: AppStyle.textDarkSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: UnderlinedTextField(
                  label: '${AppHelpers.getTranslation(TrKeys.price)}*',
                  inputType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  initialText:
                      stock.price == null ? '' : stock.price.toString(),
                  onChanged: onPriceChange,
                  validator: SellerFormValidators.emptyCheck,
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: UnderlinedTextField(
                  label: '${AppHelpers.getTranslation(TrKeys.quantity)}*',
                  inputType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  initialText:
                      stock.quantity == null ? '' : stock.quantity.toString(),
                  onChanged: onQuantityChange,
                  validator: SellerFormValidators.emptyCheck,
                ),
              ),
            ],
          ),
          4.verticalSpace,
          UnderlinedTextField(
            label: AppHelpers.getTranslation(TrKeys.sku),
            textInputAction: TextInputAction.next,
            initialText: stock.sku == null ? '' : stock.sku.toString(),
            onChanged: onSkuChange,
          ),
          UnderlinedTextField(
            label: '',
            initialText: AppHelpers.getTranslation(TrKeys.addons),
            readOnly: true,
            descriptionText: SellerAddonHelpers.selectedAddonsTitles(stock),
            onTap: () => onAddonTap(context),
            validator: SellerFormValidators.emptyCheck,
          ),
        ],
      ),
    );
  }
}
