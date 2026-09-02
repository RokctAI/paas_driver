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

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:products_sdk/src/manager/presentation/catalog/stock_grammar.dart';

/// Colors of the approved stock-state grammar (frames 35a/35f): amber for
/// low, red for out, quiet secondary grey when healthy.
Color stockLevelColor(StockLevel level) => switch (level) {
      StockLevel.healthy => AppStyle.textDarkSecondary,
      StockLevel.low => AppStyle.rate,
      StockLevel.out => AppStyle.red,
    };

/// The badge of the approved grammar — the parked paas_pos 32a low-stock
/// idea redrawn from card-tint to badge for the dark language (frame 35f's
/// inset states it): amber "⚠ Low · N left" under the threshold, red
/// "⚠ Out of stock" at zero, NOTHING when healthy (renders empty).
class StockBadge extends StatelessWidget {
  final StockLevel level;

  /// The count shown in the low badge ("Low · 7 left").
  final int quantity;

  const StockBadge({super.key, required this.level, required this.quantity});

  @override
  Widget build(BuildContext context) {
    if (level == StockLevel.healthy) return const SizedBox.shrink();
    final Color color = stockLevelColor(level);
    final String label = level == StockLevel.out
        ? AppHelpers.getTranslation('out_of_stock')
        : '${AppHelpers.getTranslation('low')} · '
            '$quantity ${AppHelpers.getTranslation('left')}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppStyle.surfaceDark.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Remix.alert_line, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppStyle.interSemi(size: 11, color: color),
          ),
        ],
      ),
    );
  }
}

/// The state-colored count text ("42 in stock" / "7 in stock" amber / "Out
/// of stock" red) — the price-side companion of the badge.
class StockCountText extends StatelessWidget {
  final StockLevel level;
  final int quantity;
  final double size;

  const StockCountText({
    super.key,
    required this.level,
    required this.quantity,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final String text = level == StockLevel.out
        ? AppHelpers.getTranslation('out_of_stock')
        : '$quantity ${AppHelpers.getTranslation('in_stock')}';
    return Text(
      text,
      style: AppStyle.interNormal(size: size, color: stockLevelColor(level)),
    );
  }
}
