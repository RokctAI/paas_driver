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

// CLOSE LOAD — the one action on this seam that costs the driver money.
//
// Everything neither sold nor returned is charged to his wallet at the
// load's unit price. So the confirm SAYS THAT, in those words, with the
// figure it will come to next to it, before the button that does it. It is
// not a "are you sure?" — it is a price tag.
//
// After the close, the summary is the receipt: what went missing per line
// and what it cost in total, read from `close_load`'s own answer
// (variance_qty / variance_amount per line, plus whatever totals the
// server sent). Nothing on this screen is computed to disagree with the
// charge the ledger actually took.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:base_sdk/src/presentation/components/buttons/custom_button.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/application/load/load_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_line_tiles.dart';

class DriverLoadCloseFlow {
  const DriverLoadCloseFlow._();

  /// The price tag, then the close, then the receipt.
  static Future<void> confirm(
    BuildContext context,
    WidgetRef ref,
    DriverLoad load,
  ) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => LoadCloseConfirmDialog(load: load),
    );
    if (agreed != true || !context.mounted) return;
    final closed =
        await ref.read(driverLoadProvider.notifier).close(load: load, context: context);
    if (closed == null || !context.mounted) return;
    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: (Theme.of(context).brightness == Brightness.dark),
      modal: LoadCloseSummarySheet(load: closed),
    );
  }
}

/// The dialog. States the charge in the words it was approved in, and puts
/// the figure it will come to next to it — the remaining stock at the load
/// price, which is exactly what the server will charge if nothing else
/// moves first.
class LoadCloseConfirmDialog extends StatelessWidget {
  const LoadCloseConfirmDialog({super.key, required this.load});

  final DriverLoad load;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('loadCloseConfirmDialog'),
      backgroundColor: AppStyle.cardFor(Theme.of(context).brightness),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Text(
        AppHelpers.getTranslation('close_load'),
        style: AppStyle.interSemi(size: 17, color: AppStyle.inkFor(Theme.of(context).brightness)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(
              'anything_not_sold_and_not_returned_is_charged_to_your_wallet_at_'
              'the_load_price',
            ),
            style: AppStyle.interRegular(
              size: 13,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
          if (load.remainingQtyTotal > 0) ...[
            14.verticalSpace,
            Text(
              '${loadQtyText(load.remainingQtyTotal)} '
              '${AppHelpers.getTranslation('still_on_the_van')}',
              style: AppStyle.interRegular(
                size: 12,
                color: AppStyle.faintFor(Theme.of(context).brightness),
              ),
            ),
            4.verticalSpace,
            Text(
              AppHelpers.numberFormat(number: load.remainingTotal),
              key: const Key('loadCloseConfirmFigure'),
              style: AppStyle.interSemi(size: 24, color: AppStyle.inkFor(Theme.of(context).brightness)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('loadCloseCancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            AppHelpers.getTranslation(TrKeys.cancel),
            style: AppStyle.interNormal(
              size: 14,
              color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
            ),
          ),
        ),
        TextButton(
          key: const Key('loadCloseAgree'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            AppHelpers.getTranslation('close_load'),
            style: AppStyle.interSemi(size: 14, color: AppStyle.primary),
          ),
        ),
      ],
    );
  }
}

/// The receipt: per-line variance and the total charge, from the server's
/// own answer.
class LoadCloseSummarySheet extends StatelessWidget {
  const LoadCloseSummarySheet({super.key, required this.load});

  final DriverLoad load;

  @override
  Widget build(BuildContext context) {
    final short = load.lines
        .where((line) => (line.varianceQty ?? 0) > 0)
        .toList(growable: false);
    return Padding(
      key: const Key('loadCloseSummarySheet'),
      padding: EdgeInsets.fromLTRB(
        16.w,
        20.h,
        16.w,
        MediaQuery.paddingOf(context).bottom + 20.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation('load_closed'),
            style: AppStyle.interSemi(size: 18, color: AppStyle.inkFor(Theme.of(context).brightness)),
          ),
          12.verticalSpace,
          if (short.isEmpty)
            Text(
              AppHelpers.getTranslation('everything_was_accounted_for'),
              key: const Key('loadCloseNoVariance'),
              style: AppStyle.interRegular(
                size: 13,
                color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
              ),
            )
          else ...[
            for (final line in short)
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        loadLineTitle(line),
                        style: AppStyle.interRegular(
                          size: 13,
                          color: AppStyle.inkFor(Theme.of(context).brightness),
                        ),
                      ),
                    ),
                    8.horizontalSpace,
                    Text(
                      loadQtyText(line.varianceQty ?? 0),
                      style: AppStyle.interSemi(
                        size: 13,
                        color: AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                    ),
                    10.horizontalSpace,
                    Text(
                      AppHelpers.numberFormat(
                        number: line.varianceAmount ?? 0,
                      ),
                      style: AppStyle.interSemi(
                        size: 13,
                        color: AppStyle.inkFor(Theme.of(context).brightness),
                      ),
                    ),
                  ],
                ),
              ),
            12.verticalSpace,
            Text(
              AppHelpers.getTranslation('charged_to_your_wallet'),
              style: AppStyle.interRegular(
                size: 12,
                color: AppStyle.faintFor(Theme.of(context).brightness),
              ),
            ),
            4.verticalSpace,
            Text(
              AppHelpers.numberFormat(number: load.varianceTotal),
              key: const Key('loadCloseVarianceTotal'),
              style: AppStyle.interSemi(size: 26, color: AppStyle.inkFor(Theme.of(context).brightness)),
            ),
          ],
          20.verticalSpace,
          CustomButton(
            key: const Key('loadCloseSummaryDone'),
            title: AppHelpers.getTranslation(TrKeys.done),
            background: AppStyle.primary,
            textColor: AppStyle.blackColor,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}
