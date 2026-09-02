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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:revenue_sdk/src/common/infrastructure/models/response/wallet_movement.dart';
import 'package:revenue_sdk/src/driver/presentation/wallet/wallet_grammar.dart';

/// Chip 972 — the movement list of the driver wallet plane (frame 49f).
///
/// It answers one question: *why is my number that*. A cash line and a fee
/// line are not a design choice, they are what the ledger contains — one
/// settlement writes BOTH, a `+delivery_fee` credit and a `-cod_collected`
/// debit, as two separate `Wallet History` rows
/// (`commerce/orders/.../settlement.py:425-490`). Folding them into one row
/// would hide the very thing that makes a negative balance make sense.
class WalletMovementList extends StatelessWidget {
  const WalletMovementList({
    super.key,
    required this.movements,
    this.foldedRowCount = 6,
    this.showAll = false,
    this.onShowAll,
    this.isLoading = false,
    this.failed = false,
    this.now,
  });

  final List<WalletMovement> movements;

  /// How many rows show before the unfold.
  final int foldedRowCount;
  final bool showAll;
  final VoidCallback? onShowAll;

  final bool isLoading;

  /// The read did not land. ONE friendly line, never the cause.
  final bool failed;

  /// Injected in tests so "Today" is deterministic.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final visible =
        showAll ? movements : movements.take(foldedRowCount).toList();
    final bool hasMore = !showAll && movements.length > foldedRowCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('walletMovementList'),
          decoration: BoxDecoration(
            color: AppStyle.cardDark,
            borderRadius: BorderRadius.circular(14.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Column(
            children: [
              if (failed)
                _note(
                  AppHelpers.getTranslation(
                    'we_could_not_load_your_recent_movements',
                  ),
                  const Key('walletMovementsFailed'),
                )
              else if (isLoading && movements.isEmpty)
                _note(
                  AppHelpers.getTranslation('loading'),
                  const Key('walletMovementsLoading'),
                )
              else if (visible.isEmpty)
                _note(
                  AppHelpers.getTranslation('no_movements_yet'),
                  const Key('walletMovementsEmpty'),
                )
              else
                for (var i = 0; i < visible.length; i++) ...[
                  _row(visible[i]),
                  if (i != visible.length - 1)
                    Divider(height: 1, color: AppStyle.strokeDarkSubtle),
                ],
            ],
          ),
        ),
        if (hasMore) ...[
          12.verticalSpace,
          GestureDetector(
            key: const Key('walletShowAllMovements'),
            onTap: onShowAll,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Text(
                AppHelpers.getTranslation('see_all_movements'),
                style: AppStyle.interNoSemi(
                  size: 11.5,
                  color: AppStyle.textDarkSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _note(String text, Key key) => Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Text(
          text,
          key: key,
          style: AppStyle.interRegular(
            size: 12,
            color: AppStyle.textDarkFaint,
          ),
        ),
      );

  Widget _row(WalletMovement movement) {
    final credit = movement.isCredit;
    final label = movementDescription(movement) ??
        AppHelpers.getTranslation(movementTypeKey(movement));
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interNoSemi(size: 12.5),
                ),
                4.verticalSpace,
                Text(
                  _when(movement.at),
                  style: AppStyle.interRegular(
                    size: 10,
                    color: AppStyle.textDarkFaint,
                  ),
                ),
              ],
            ),
          ),
          12.horizontalSpace,
          Text(
            '${credit ? '+' : '−'} '
            '${AppHelpers.numberFormat(number: movement.magnitude)}',
            style: AppStyle.interSemi(
              size: 13,
              color: credit ? AppStyle.green : AppStyle.red,
            ),
          ),
        ],
      ),
    );
  }

  /// "Today 16:42" / "Yesterday 09:12" / "28 Aug 11:40" — frame 49f's own
  /// three forms.
  String _when(DateTime? at) {
    if (at == null) return '';
    final clock = DateFormat('HH:mm').format(at);
    switch (classifyDay(at, now ?? DateTime.now())) {
      case MovementDay.today:
        return '${AppHelpers.getTranslation('today')} $clock';
      case MovementDay.yesterday:
        return '${AppHelpers.getTranslation('yesterday')} $clock';
      case MovementDay.earlier:
        return '${DateFormat('d MMM').format(at)} $clock';
    }
  }
}
