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
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_badge.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_grammar.dart';

/// The approved 35a READ-ONLY detail pane (the LAST plane on wide windows):
/// the selected product read plainly — photo with the state badge, title
/// with the Active pill, the PROFITABILITY STRIP (Price · Cost · Margin,
/// client-side arithmetic, the 14:51Z groundwork — "cost not set" when the
/// cost field is empty), the stock callout, the meta rows, and the two
/// doors: Edit product and Quick stock update.
///
/// A deliberate approved asymmetry: this read stop exists only at plane
/// widths — on phones a card tap still goes straight to the edit form
/// (approved 35c/35d, the shipped behaviour).
class ProductDetailPane extends StatelessWidget {
  final SellerProductData product;
  final VoidCallback onEdit;
  final VoidCallback onQuickStock;

  const ProductDetailPane({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onQuickStock,
  });

  @override
  Widget build(BuildContext context) {
    final StockLevel level = StockGrammar.productLevel(product);
    final int quantity = StockGrammar.productQuantity(product);
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyle.strokeDarkSubtle),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 140,
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
                      top: 8,
                      end: 8,
                      child: StockBadge(level: level, quantity: quantity),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.translation?.title ?? '',
                        style: AppStyle.interBold(
                          size: 18,
                          color: AppStyle.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _activePill(),
                  ],
                ),
                if ((product.translation?.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product.translation!.description!,
                    style: AppStyle.interNormal(
                      size: 13,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _marginStrip(),
                const SizedBox(height: 14),
                Text(
                  AppHelpers.getTranslation('stock').toUpperCase(),
                  style: AppStyle.interSemi(
                    size: 11,
                    color: AppStyle.textDarkFaint,
                  ),
                ),
                const SizedBox(height: 6),
                _stockCallout(level, quantity),
                const SizedBox(height: 12),
                _metaRow(
                  AppHelpers.getTranslation('sku').toUpperCase(),
                  product.stocks?.isNotEmpty == true
                      ? (product.stocks!.first.sku ?? '—')
                      : '—',
                ),
                _metaRow(
                  AppHelpers.getTranslation('product_category'),
                  product.category?.translation?.title ?? '—',
                ),
                _metaRow(
                  AppHelpers.getTranslation('units'),
                  _unitLine(),
                ),
                _metaRow(
                  AppHelpers.getTranslation('kitchen'),
                  product.kitchen?.title ?? '—',
                ),
                _metaRow(
                  AppHelpers.getTranslation(TrKeys.tax),
                  product.effectiveTax == null ? '—' : '${product.effectiveTax}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _primaryButton(
            title: AppHelpers.getTranslation(TrKeys.editProduct),
            onTap: onEdit,
          ),
          const SizedBox(height: 8),
          _outlineButton(
            title: AppHelpers.getTranslation('quick_stock_update'),
            onTap: onQuickStock,
          ),
        ],
      ),
    );
  }

  Widget _activePill() {
    final bool active = product.active ?? false;
    final Color color = active ? AppStyle.green : AppStyle.textDarkFaint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color),
      ),
      child: Text(
        AppHelpers.getTranslation(
          active ? TrKeys.active : 'inactive',
        ),
        style: AppStyle.interNormal(size: 11, color: color),
      ),
    );
  }

  /// Price R 78.00 · Cost R 48.00 · Margin R 30 · 38% — the approved strip.
  /// Cost is load-bearing now (the 14:51Z profitability directive), so it
  /// shows its work here, not just in a form field; with no usable cost the
  /// margin cell honestly says "cost not set".
  Widget _marginStrip() {
    final stocks = product.stocks;
    final num? price =
        (stocks != null && stocks.isNotEmpty) ? stocks.first.price : null;
    final ProductMargin? margin = ProductMargin.ofProduct(product);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppStyle.strokeDark),
      ),
      child: Row(
        children: [
          _stripCell(
            label: AppHelpers.getTranslation(TrKeys.price),
            value: price == null
                ? '—'
                : AppHelpers.numberFormat(number: price),
            valueColor: AppStyle.textPrimary,
          ),
          _stripDivider(),
          _stripCell(
            label: AppHelpers.getTranslation('cost'),
            value: (product.cost == null || product.cost! <= 0)
                ? '—'
                : AppHelpers.numberFormat(number: product.cost),
            valueColor: AppStyle.textPrimary,
          ),
          _stripDivider(),
          _stripCell(
            label: AppHelpers.getTranslation('margin'),
            value: margin == null
                ? AppHelpers.getTranslation('cost_not_set')
                : '${AppHelpers.numberFormat(number: margin.margin)} · '
                    '${margin.percent.round()}%',
            valueColor: margin == null
                ? AppStyle.textDarkFaint
                : (margin.margin < 0 ? AppStyle.red : AppStyle.green),
          ),
        ],
      ),
    );
  }

  Widget _stripCell({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppStyle.interNormal(
              size: 11,
              color: AppStyle.textDarkSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interSemi(size: 13, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _stripDivider() => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: AppStyle.strokeDark,
      );

  /// The amber/red callout bar under STOCK — "7 in stock — below the
  /// low-stock line (10)" / "Out of stock" / the quiet healthy line.
  Widget _stockCallout(StockLevel level, int quantity) {
    final Color color = stockLevelColor(level);
    final String text = switch (level) {
      StockLevel.out => AppHelpers.getTranslation('out_of_stock'),
      StockLevel.low => '$quantity ${AppHelpers.getTranslation('in_stock')}'
          ' — ${AppHelpers.getTranslation('below_the_low_stock_line')}'
          ' ($kLowStockThreshold)',
      StockLevel.healthy =>
        '$quantity ${AppHelpers.getTranslation('in_stock')}',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: level == StockLevel.healthy ? AppStyle.strokeDark : color,
        ),
      ),
      child: Row(
        children: [
          Icon(
            level == StockLevel.healthy
                ? Remix.archive_line
                : Remix.alert_line,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppStyle.interSemi(
                size: 12,
                color: level == StockLevel.healthy ? AppStyle.textPrimary : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _unitLine() {
    final parts = <String>[
      if ((product.unit?.translation?.title ?? '').isNotEmpty)
        product.unit!.translation!.title!,
      if (product.interval != null)
        '${AppHelpers.getTranslation('interval')} ${product.interval}',
      if (product.minQty != null) 'min ${product.minQty}',
      if (product.maxQty != null) 'max ${product.maxQty}',
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppStyle.interNormal(
                size: 12,
                color: AppStyle.textDarkFaint,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyle.interNormal(size: 12, color: AppStyle.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppStyle.primary,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          title,
          style: AppStyle.interSemi(size: 14, color: AppStyle.textPrimary),
        ),
      ),
    );
  }

  Widget _outlineButton({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppStyle.rate),
        ),
        child: Text(
          title,
          style: AppStyle.interSemi(size: 14, color: AppStyle.rate),
        ),
      ),
    );
  }
}
