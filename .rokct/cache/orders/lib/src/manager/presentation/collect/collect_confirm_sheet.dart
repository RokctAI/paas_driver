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
import 'package:flutter_remix/flutter_remix.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';

import 'collect_keys.dart';

/// 818 — one row of the outcome ledger: a tinted glyph, the thing that
/// moves, and what happens to it. Fixed three-column rhythm so the two
/// branches line up and can never be confused for each other.
class CollectLedgerRow extends StatelessWidget {
  final IconData glyph;
  final Color accent;
  final String label;
  final String strong;
  final String plain;
  final bool last;

  const CollectLedgerRow({
    super.key,
    required this.glyph,
    required this.accent,
    required this.label,
    required this.strong,
    required this.plain,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: AppStyle.strokeDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
            ),
            child: Icon(glyph, size: 15, color: accent),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: AppStyle.interNormal(
                size: 12.5,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppStyle.interNormal(
                  size: 12.5,
                  color: AppStyle.textPrimary,
                ),
                children: [
                  TextSpan(
                    text: strong,
                    style: AppStyle.interSemi(size: 12.5, color: accent),
                  ),
                  TextSpan(text: plain.isEmpty ? '' : ' $plain'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 817 / 818 / 819 — the convert confirm guard: the consequence put
/// BEFORE the tap, never in a snackbar afterwards (the chip-768
/// pattern). Four rows, one per thing that actually moves, so the
/// two branches can never be confused:
///
///   Goods         — handed over NOW, never withheld, never forfeited;
///   Delivery type — Delivery becomes Pickup on this order;
///   Delivery fee  — kept for the driver's callout, or back to her wallet;
///   Driver task   — the driver is unassigned and his task cancels.
///
/// Rows 3 and 4 are the two that differ between the branches, and the
/// Driver task row is not decoration: standing the driver down is what
/// keeps the settlement from paying him the fee a second time.
class CollectConfirmSheet extends StatelessWidget {
  final String customerName;
  final String orderId;
  final String totalText;
  final String feeText;
  final bool driverAssigned;
  final String? driverName;
  final VoidCallback onConfirm;

  const CollectConfirmSheet({
    super.key,
    required this.customerName,
    required this.orderId,
    required this.totalText,
    required this.feeText,
    required this.driverAssigned,
    required this.onConfirm,
    this.driverName,
  });

  /// Shows the guard centred over a scrim; resolves true when the seller
  /// confirmed.
  static Future<bool> show(BuildContext context, CollectConfirmSheet sheet) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (_) => sheet,
    );
    return ok ?? false;
  }

  String get _driver => (driverName ?? '').trim().isEmpty
      ? AppHelpers.getTranslation(CollectKeys.driverTaskRow)
      : driverName!.trim();

  @override
  Widget build(BuildContext context) {
    final Color feeAccent = driverAssigned ? AppStyle.rate : AppStyle.green;
    return Dialog(
      backgroundColor: AppStyle.cardDark,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppStyle.cardDarkAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppStyle.strokeDark),
                  ),
                  child: Column(children: _ledger(feeAccent)),
                ),
                const SizedBox(height: 20),
                _actions(context),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    driverAssigned
                        ? '${AppHelpers.getTranslation(CollectKeys.feeComesBackIfNoDriverWasOnItYet)} '
                              '${AppHelpers.getTranslation(CollectKeys.thisOneHadADriverOnItSoItDoesNot)}'
                        : AppHelpers.getTranslation(
                            CollectKeys.feeComesBackIfNoDriverWasOnItYet,
                          ),
                    textAlign: TextAlign.center,
                    style: AppStyle.interNormal(
                      size: 11,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppStyle.primary.withValues(alpha: 0.18),
        ),
        child: Icon(
          FlutterRemix.shopping_bag_3_line,
          size: 20,
          color: AppStyle.primary,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppHelpers.getTranslation(
                CollectKeys.handOverAndConvertToPickup,
              ),
              style: AppStyle.interSemi(
                size: 19,
                color: AppStyle.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$customerName · №$orderId · $totalText',
              style: AppStyle.interNormal(
                size: 12.5,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  List<Widget> _ledger(Color feeAccent) => [
    CollectLedgerRow(
      glyph: FlutterRemix.check_line,
      accent: AppStyle.green,
      label: AppHelpers.getTranslation(CollectKeys.goods),
      strong: AppHelpers.getTranslation(CollectKeys.handedToTheCustomerNow),
      plain: AppHelpers.getTranslation(
        CollectKeys.neverWithheldNeverForfeited,
      ),
    ),
    CollectLedgerRow(
      glyph: FlutterRemix.shopping_bag_3_line,
      accent: AppStyle.primary,
      label: AppHelpers.getTranslation(CollectKeys.deliveryTypeRow),
      strong:
          '${AppHelpers.getTranslation(BoardRules.deliveryType)} → '
          '${AppHelpers.getTranslation(TrKeys.pickup)}',
      plain: AppHelpers.getTranslation(CollectKeys.onThisOrder),
    ),
    CollectLedgerRow(
      glyph: FlutterRemix.bank_card_line,
      accent: feeAccent,
      label:
          '${AppHelpers.getTranslation(CollectKeys.deliveryFeeRow)}\n$feeText',
      strong: AppHelpers.getTranslation(
        driverAssigned
            ? CollectKeys.keptNotRefunded
            : CollectKeys.refundedToHerWallet,
      ),
      plain: AppHelpers.getTranslation(
        driverAssigned
            ? CollectKeys.itCoversTheDriversCallout
            : CollectKeys.noDriverWasEverOnIt,
      ),
    ),
    CollectLedgerRow(
      glyph: FlutterRemix.truck_line,
      accent: BoardStatus.onWay.color,
      label: AppHelpers.getTranslation(CollectKeys.driverTaskRow),
      strong: driverAssigned
          ? _driver
          : AppHelpers.getTranslation(CollectKeys.nobodyToStandDown),
      plain: driverAssigned
          ? AppHelpers.getTranslation(
              CollectKeys.isUnassignedAndHisTaskCancels,
            )
          : '',
      last: true,
    ),
  ];

  /// 819 — Cancel ghost at flex 1, the affirmative primary at flex 1.6.
  /// The wider one is deliberately the one that hands the goods over:
  /// that is never the risky choice, and the money outcome is what the
  /// ledger above just disclosed.
  Widget _actions(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 10,
        child: SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppStyle.strokeDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Text(
              AppHelpers.getTranslation(TrKeys.cancel),
              style: AppStyle.interSemi(
                size: 14,
                color: AppStyle.textPrimary,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 16,
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FlutterRemix.check_line,
                  size: 18,
                  color: AppStyle.white,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    AppHelpers.getTranslation(
                      CollectKeys.handOverAndConvert,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interSemi(
                      size: 14,
                      color: AppStyle.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
