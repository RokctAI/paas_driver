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

import 'package:base_sdk/src/presentation/components/helper/common_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_badge.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_grammar.dart';

/// The approved 35a catalog GRID card (wide widths): photo with the
/// stock-state badge riding its corner, title, one description line, then
/// price beside the state-colored live count — the extra width buys detail,
/// not zoom. Out of stock replaces the price with red text (the shipped
/// food_item's rule, kept). A selected card carries the primary outline
/// that drives the detail plane.
class ProductCatalogCard extends StatelessWidget {
  final SellerProductData product;
  final bool selected;
  final VoidCallback onTap;

  const ProductCatalogCard({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final StockLevel level = StockGrammar.productLevel(product);
    final int quantity = StockGrammar.productQuantity(product);
    final bool out = level == StockLevel.out;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppStyle.primary : AppStyle.strokeDark,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 84,
                    width: double.infinity,
                    child: CommonImage(
                      url: product.img,
                      radius: 0,
                      errorRadius: 0,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 6,
                  end: 6,
                  child: StockBadge(level: level, quantity: quantity),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              product.translation?.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interSemi(size: 14, color: AppStyle.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              product.translation?.description ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interNormal(
                size: 11,
                color: AppStyle.textDarkSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: out
                      ? Text(
                          AppHelpers.getTranslation('out_of_stock'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyle.interSemi(
                            size: 13,
                            color: AppStyle.red,
                          ),
                        )
                      : Text(
                          AppHelpers.numberFormat(
                            number: product.stocks?.first.price ?? 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyle.interSemi(
                            size: 13,
                            color: AppStyle.textPrimary,
                          ),
                        ),
                ),
                StockCountText(level: level, quantity: quantity, size: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The approved 35c PHONE list card — the shipped food_item shape (title,
/// description, price on the left, photo on the right) with the stock
/// states riding along: the amber badge under the price, the red badge
/// where the price would be.
class ProductCatalogTile extends StatelessWidget {
  final SellerProductData product;
  final VoidCallback onTap;

  const ProductCatalogTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final StockLevel level = StockGrammar.productLevel(product);
    final int quantity = StockGrammar.productQuantity(product);
    final bool out = level == StockLevel.out;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppStyle.strokeDarkSubtle),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.translation?.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interSemi(size: 15, color: AppStyle.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.translation?.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(
                      size: 12,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (out)
                    StockBadge(level: level, quantity: quantity)
                  else
                    Row(
                      children: [
                        Text(
                          AppHelpers.numberFormat(
                            number: product.stocks?.first.price ?? 0,
                          ),
                          style: AppStyle.interSemi(
                            size: 14,
                            color: AppStyle.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (level == StockLevel.low)
                          StockBadge(level: level, quantity: quantity)
                        else
                          StockCountText(level: level, quantity: quantity),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CommonImage(
                url: product.img,
                width: 72,
                height: 72,
                radius: 0,
                errorRadius: 0,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
