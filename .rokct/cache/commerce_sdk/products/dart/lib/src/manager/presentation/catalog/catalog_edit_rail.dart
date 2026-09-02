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

import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/helper/common_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_badge.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_grammar.dart';

/// The ORIGIN catalog compressed onto plane 1 while the edit form holds the
/// other planes (approved 35b, the 12:26Z origin rule): a scannable
/// read-only list — thumbnail, title, price (red "Out of stock" when out),
/// the warning triangle kept even at this width, and the product being
/// edited highlighted. Deliberately not tappable: it is the yielded page
/// keeping context, not a second navigation surface — switching products
/// mid-edit would discard unsaved form state.
class CatalogEditRail extends StatelessWidget {
  final List<SellerProductData> products;
  final String? editedId;

  const CatalogEditRail({
    super.key,
    required this.products,
    required this.editedId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppHelpers.getTranslation('products'),
          style: AppStyle.interBold(size: 20, color: AppStyle.textPrimary),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              final StockLevel level = StockGrammar.productLevel(product);
              final bool edited =
                  editedId != null && product.id == editedId;
              final bool out = level == StockLevel.out;
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppStyle.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: edited ? AppStyle.primary : AppStyle.strokeDarkSubtle,
                    width: edited ? 1.4 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CommonImage(
                        url: product.img,
                        width: 40,
                        height: 40,
                        radius: 0,
                        errorRadius: 0,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.translation?.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyle.interSemi(
                              size: 13,
                              color: AppStyle.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            out
                                ? AppHelpers.getTranslation('out_of_stock')
                                : AppHelpers.numberFormat(
                                    number: product.stocks?.first.price ?? 0,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyle.interNormal(
                              size: 12,
                              color: out
                                  ? AppStyle.red
                                  : AppStyle.textDarkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (level != StockLevel.healthy) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Remix.alert_line,
                        size: 16,
                        color: stockLevelColor(level),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
