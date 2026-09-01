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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/components/helper/common_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/manager/application/catalog/quick_stock_notifier.dart';
import 'package:products_sdk/src/manager/application/catalog/quick_stock_provider.dart';
import 'package:products_sdk/src/manager/application/catalog/quick_stock_state.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_badge.dart';

/// The approved 35e QUICK STOCK UPDATE surface — the standalone stock
/// screen group G never had: COUNTS ONLY (the approved scope tag) — a
/// stepper per stock row, the Low-stock/Out triage chips floating the
/// problems to the top, one batch save. Prices, variants, SKUs and add-ons
/// stay in the product form — this surface can never fork the form family.
///
/// One widget serves both approved presentations: the bottom sheet on
/// phones (frame 35e) and, per the 12:02Z sheet fork, a plane pane at
/// plane widths ([asSheet] false — the catalog flow pushes it and the nav
/// folds to the corner pill).
class QuickStockView extends ConsumerStatefulWidget {
  /// The loaded catalog to seed from.
  final List<SellerProductData> products;

  /// Sheet dressing (drag handle, sheet corners) on phones.
  final bool asSheet;

  /// Called after a successful batch save (the host refreshes the list).
  final void Function(int savedProducts) onSaved;

  /// Closes the surface (pops the sheet / the plane pane).
  final VoidCallback onClose;

  const QuickStockView({
    super.key,
    required this.products,
    required this.asSheet,
    required this.onSaved,
    required this.onClose,
  });

  @override
  ConsumerState<QuickStockView> createState() => _QuickStockViewState();
}

class _QuickStockViewState extends ConsumerState<QuickStockView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quickStockProvider.notifier).seedFrom(widget.products);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickStockProvider);
    final notifier = ref.read(quickStockProvider.notifier);
    final rows = state.visibleRows;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.asSheet) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppStyle.strokeDark,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                AppHelpers.getTranslation('quick_stock_update'),
                style: AppStyle.interBold(size: 20, color: AppStyle.textPrimary),
              ),
            ),
            Text(
              AppHelpers.getTranslation('counts_only'),
              style: AppStyle.interNormal(
                size: 12,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppHelpers.getTranslation('tap_to_adjust_counts_prices_and_variants_stay_in_the_product_form'),
          style: AppStyle.interNormal(
            size: 12,
            color: AppStyle.textDarkSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _triageChips(state, notifier),
        const SizedBox(height: 12),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Text(
                    AppHelpers.getTranslation('nothing_to_count_here'),
                    style: AppStyle.interNormal(
                      size: 12,
                      color: AppStyle.textDarkFaint,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _row(rows[index], notifier),
                ),
        ),
        const SizedBox(height: 10),
        _saveButton(state, notifier),
      ],
    );
    if (!widget.asSheet) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppStyle.cardDarkAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyle.strokeDarkSubtle),
        ),
        child: body,
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(top: false, child: body),
    );
  }

  Widget _triageChips(QuickStockState state, QuickStockNotifier notifier) {
    Widget chip({
      required QuickStockFilter filter,
      required String label,
      int? count,
      Color? color,
    }) {
      final bool active = state.filter == filter;
      final Color accent = color ?? AppStyle.primary;
      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: GestureDetector(
          onTap: () => notifier.setFilter(filter),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: active && color == null
                  ? AppStyle.primary
                  : AppStyle.transparent,
              border: Border.all(
                color: active ? accent : AppStyle.strokeDark,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppStyle.interSemi(
                    size: 13,
                    color: active
                        ? (color == null ? AppStyle.textPrimary : accent)
                        : AppStyle.textDarkSecondary,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: AppStyle.interSemi(
                      size: 13,
                      color: active
                          ? (color == null ? AppStyle.textPrimary : accent)
                          : AppStyle.textDarkFaint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            filter: QuickStockFilter.all,
            label: AppHelpers.getTranslation(TrKeys.all),
          ),
          chip(
            filter: QuickStockFilter.low,
            label: AppHelpers.getTranslation('low_stock'),
            count: state.lowCount,
            color: AppStyle.rate,
          ),
          chip(
            filter: QuickStockFilter.out,
            label: AppHelpers.getTranslation('out'),
            count: state.outCount,
            color: AppStyle.red,
          ),
        ],
      ),
    );
  }

  Widget _row(QuickStockRow row, QuickStockNotifier notifier) {
    final String? variant = row.variantLabel;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: row.dirty ? AppStyle.primary : AppStyle.strokeDarkSubtle,
          width: row.dirty ? 1.4 : 1,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CommonImage(
              url: row.product.img,
              width: 48,
              height: 48,
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
                  row.product.translation?.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(size: 14, color: AppStyle.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  variant ??
                      AppHelpers.numberFormat(number: row.stock.price ?? 0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interNormal(
                    size: 12,
                    color: AppStyle.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _stepper(row, notifier),
        ],
      ),
    );
  }

  Widget _stepper(QuickStockRow row, QuickStockNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppStyle.strokeDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepButton(
            icon: Remix.subtract_line,
            onTap: () => notifier.decrement(row.key),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${row.current}',
              textAlign: TextAlign.center,
              style: AppStyle.interBold(
                size: 15,
                color: stockLevelColor(row.currentLevel),
              ),
            ),
          ),
          _stepButton(
            icon: Remix.add_line,
            onTap: () => notifier.increment(row.key),
          ),
        ],
      ),
    );
  }

  Widget _stepButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, size: 18, color: AppStyle.textPrimary),
      ),
    );
  }

  Widget _saveButton(QuickStockState state, QuickStockNotifier notifier) {
    final int dirty = state.dirtyCount;
    final bool enabled = dirty > 0 && !state.isSaving;
    return InkWell(
      onTap: enabled
          ? () => notifier.saveAll(
                updated: (saved) {
                  widget.onSaved(saved);
                  widget.onClose();
                },
                failed: () {
                  if (!mounted) return;
                  AppHelpers.showCheckTopSnackBar(
                    context,
                    AppHelpers.getTranslation('update_failed'),
                  );
                },
              )
          : null,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? AppStyle.primary
              : AppStyle.primary.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(100),
        ),
        child: state.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                dirty == 0
                    ? AppHelpers.getTranslation(TrKeys.save)
                    : '${AppHelpers.getTranslation(TrKeys.save)} $dirty '
                        '${AppHelpers.getTranslation('changes')}',
                style: AppStyle.interSemi(size: 15, color: AppStyle.textPrimary),
              ),
      ),
    );
  }
}
