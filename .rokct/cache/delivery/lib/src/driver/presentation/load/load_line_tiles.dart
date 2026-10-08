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

// The two ways a load line is drawn: as a fact (the load list) and as a
// choice (the sell and return screens).
//
// Both start from the SAME four numbers, because that is the only way a
// driver can check his van against his phone: issued, sold, returned,
// remaining. The row never derives one from the others — remaining is the
// server's figure, and a client that recomputed it would eventually
// disagree with the figure the server validates the next sale against.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';

/// A quantity as a driver counts it: whole when it is whole.
String loadQtyText(num quantity) {
  if (quantity == quantity.roundToDouble()) return quantity.toInt().toString();
  return quantity.toString();
}

/// "Still water 5L" plus the unit word when the product carries one.
String loadLineTitle(DriverLoadLine line) {
  final title = line.title ?? line.productUuid ?? '';
  final unit = line.unitTitle;
  if (unit == null || unit.isEmpty) return title;
  return '$title · $unit';
}

/// One line as a FACT — what the load list shows.
class LoadLineFactRow extends StatelessWidget {
  const LoadLineFactRow({super.key, required this.line});

  final DriverLoadLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  loadLineTitle(line),
                  style: AppStyle.interSemi(
                    size: 14,
                    color: AppStyle.inkFor(Theme.of(context).brightness),
                  ),
                ),
              ),
              8.horizontalSpace,
              Text(
                AppHelpers.numberFormat(number: line.unitPrice),
                style: AppStyle.interRegular(
                  size: 13,
                  color: AppStyle.secondaryInkFor(Theme.of(context).brightness),
                ),
              ),
            ],
          ),
          6.verticalSpace,
          // The four quantities, in the order they happen.
          Wrap(
            spacing: 14.w,
            runSpacing: 4.h,
            children: [
              _Figure(
                label: AppHelpers.getTranslation('issued'),
                value: loadQtyText(line.issuedQty),
              ),
              _Figure(
                label: AppHelpers.getTranslation('sold'),
                value: loadQtyText(line.soldQty),
              ),
              _Figure(
                label: AppHelpers.getTranslation('returned'),
                value: loadQtyText(line.returnedQty),
              ),
              _Figure(
                label: AppHelpers.getTranslation('remaining'),
                value: loadQtyText(line.remainingQty),
                strong: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One line as a CHOICE — the stepper the sell and return screens use.
///
/// The plus goes inert AT the cap rather than complaining past it: the
/// server refuses a quantity above remaining, so a stepper that let the
/// driver dial past it would be setting him up for a refusal.
class LoadLineStepperRow extends StatelessWidget {
  const LoadLineStepperRow({
    super.key,
    required this.line,
    required this.quantity,
    required this.cap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final DriverLoadLine line;
  final int quantity;
  final int cap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final atCap = quantity >= cap;
    return Container(
      key: Key('loadStepperRow-${line.stockId ?? line.itemId ?? ''}'),
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppStyle.cardAltFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppStyle.subtleStrokeFor(Theme.of(context).brightness),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loadLineTitle(line),
                  style: AppStyle.interSemi(
                    size: 14,
                    color: AppStyle.inkFor(Theme.of(context).brightness),
                  ),
                ),
                4.verticalSpace,
                Text(
                  '${AppHelpers.getTranslation('remaining')} '
                  '${loadQtyText(line.remainingQty)} · '
                  '${AppHelpers.numberFormat(number: line.unitPrice)}',
                  style: AppStyle.interRegular(
                    size: 12,
                    color: AppStyle.secondaryInkFor(
                      Theme.of(context).brightness,
                    ),
                  ),
                ),
              ],
            ),
          ),
          10.horizontalSpace,
          _StepButton(
            icon: Remix.subtract_line,
            enabled: quantity > 0,
            semanticLabel: AppHelpers.getTranslation('less'),
            stockKey: 'loadStepMinus-${line.stockId ?? ''}',
            onTap: onDecrement,
          ),
          SizedBox(
            width: 40.w,
            child: Text(
              quantity.toString(),
              key: Key('loadStepQty-${line.stockId ?? ''}'),
              textAlign: TextAlign.center,
              style: AppStyle.interSemi(
                size: 17,
                color: AppStyle.inkFor(Theme.of(context).brightness),
              ),
            ),
          ),
          _StepButton(
            icon: Remix.add_line,
            enabled: !atCap,
            semanticLabel: AppHelpers.getTranslation('more'),
            stockKey: 'loadStepPlus-${line.stockId ?? ''}',
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.semanticLabel,
    required this.stockKey,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final String semanticLabel;
  final String stockKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: Key(stockKey),
      onPressed: enabled ? onTap : null,
      tooltip: semanticLabel,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        icon,
        size: 20.r,
        color: enabled
            ? AppStyle.inkFor(Theme.of(context).brightness)
            : AppStyle.faintFor(Theme.of(context).brightness),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppStyle.interRegular(
            size: 10,
            letterSpacing: 0.8,
            color: AppStyle.faintFor(Theme.of(context).brightness),
          ),
        ),
        4.horizontalSpace,
        Text(
          value,
          style: strong
              ? AppStyle.interSemi(
                  size: 13,
                  color: AppStyle.inkFor(Theme.of(context).brightness),
                )
              : AppStyle.interRegular(
                  size: 13,
                  color: AppStyle.inkFor(Theme.of(context).brightness),
                ),
        ),
      ],
    );
  }
}
