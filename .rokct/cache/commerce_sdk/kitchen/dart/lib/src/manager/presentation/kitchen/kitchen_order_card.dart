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
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_clock.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// Shared card atoms of the approved kitchen frames (34a/34b).
abstract final class KitchenCardBits {
  /// Order-type glyph: bike for delivery, walking for pickup,
  /// fork-and-knife for dine-in (POS orders_info.dart:350-401).
  static IconData glyphIcon(String? deliveryType) {
    switch ((deliveryType ?? '').toLowerCase()) {
      case KitchenRules.deliveryType:
        return Icons.pedal_bike;
      case KitchenRules.dineType:
        return Icons.restaurant;
      default:
        return Icons.directions_walk;
    }
  }

  /// The delivery type's translation key IS its wire value
  /// ('delivery' / 'pickup' / 'dine_in' — legacy store keys).
  static String typeLabel(String? deliveryType) => AppHelpers.getTranslation(
    (deliveryType ?? '').isEmpty ? 'pickup' : deliveryType!.toLowerCase(),
  );

  static String placedTime(DateTime? createdAt) => createdAt == null
      ? ''
      : DateFormat('h:mm a').format(createdAt.toLocal()).toLowerCase();

  static Widget glyph(String? deliveryType, {double diameter = 26}) =>
      Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppStyle.cardDarkAlt,
          border: Border.all(color: AppStyle.strokeDark),
        ),
        child: Icon(
          glyphIcon(deliveryType),
          size: diameter * 0.54,
          color: AppStyle.textPrimary,
        ),
      );

  static Widget statusPill(KitchenStatus status, {double fontSize = 10.5}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: status.color.withValues(alpha: 0.65)),
        ),
        child: Text(
          AppHelpers.getTranslation(status.wire),
          style: AppStyle.interSemi(size: fontSize, color: status.color),
        ),
      );

  /// The orange "Just in" ping an accepted card shows instead of a clock
  /// — the moment the new-order chime plays (34a/34b).
  static Widget justIn() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppStyle.primary,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        AppHelpers.getTranslation('just_in'),
        style: AppStyle.interSemi(size: 10.5, color: AppStyle.primary),
      ),
    ],
  );

  /// "3 dishes · Beef Kota ×2, Chips…" — the dish preview line the ALL
  /// declaration's extra width buys (34a redesign: "more space means more
  /// details not zoom").
  static String dishPreview(KitchenOrderData order) {
    final count = order.dishes.length;
    if (count == 0) return '';
    final word = AppHelpers.getTranslation(count == 1 ? 'dish' : 'dishes');
    final names = [
      for (final dish in order.dishes.take(2))
        dish.quantity > 1
            ? '${dish.title ?? ''} ×${dish.quantity}'
            : (dish.title ?? ''),
    ].where((n) => n.isNotEmpty).join(', ');
    final ellipsis = count > 2 ? '…' : '';
    return '$count $word · $names$ellipsis';
  }
}

/// A queue card. [compact] renders the phone row shape (34b: glyph left,
/// number/time/pill stacked, clock right); otherwise the grid tile (34a:
/// number + glyph, dish preview, clock, time + pill footer).
class KitchenOrderCard extends StatelessWidget {
  final KitchenOrderData order;
  final bool compact;
  final bool selected;
  final VoidCallback? onTap;

  /// Injectable "now" for the clock, so tests can freeze it.
  final DateTime Function()? clock;

  const KitchenOrderCard({
    super.key,
    required this.order,
    this.compact = false,
    this.selected = false,
    this.onTap,
    this.clock,
  });

  /// "#a1b2c3" — the docname is a Frappe hash; keep it short and
  /// number-like, the way the POS showed order ids.
  String get orderLabel {
    final id = order.id ?? '';
    return '#${id.length > 8 ? id.substring(id.length - 8) : id}';
  }

  Widget _clockOrPing({required double tileWidth}) =>
      order.status == KitchenStatus.accepted
      ? KitchenCardBits.justIn()
      : KitchenFlipClock(
          status: order.status,
          createdAt: order.createdAt,
          updatedAt: order.updatedAt,
          tileWidth: tileWidth,
          clock: clock,
        );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: compact ? _compactCard() : _gridCard(),
    );
  }

  Widget _gridCard() {
    final preview = KitchenCardBits.dishPreview(order);
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppStyle.primary : AppStyle.strokeDarkSubtle,
          width: selected ? 1.3 : 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  orderLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(
                    size: 13.5,
                    color: AppStyle.textPrimary,
                  ),
                ),
              ),
              KitchenCardBits.glyph(order.deliveryType),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interNormal(
                size: 10.5,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ],
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: _clockOrPing(
              tileWidth: 26,
            ),
          ),
          const Spacer(),
          Container(height: 1, color: AppStyle.strokeDarkSubtle),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  KitchenCardBits.placedTime(order.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interNormal(
                    size: 11,
                    color: AppStyle.textDarkFaint,
                  ),
                ),
              ),
              KitchenCardBits.statusPill(order.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppStyle.primary : AppStyle.strokeDarkSubtle,
        ),
      ),
      child: Row(
        children: [
          KitchenCardBits.glyph(order.deliveryType, diameter: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderLabel,
                  style: AppStyle.interSemi(
                    size: 14,
                    color: AppStyle.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${KitchenCardBits.placedTime(order.createdAt)} · '
                  '${KitchenCardBits.typeLabel(order.deliveryType)}',
                  style: AppStyle.interNormal(
                    size: 11,
                    color: AppStyle.textDarkFaint,
                  ),
                ),
                const SizedBox(height: 8),
                KitchenCardBits.statusPill(order.status),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: _clockOrPing(tileWidth: 26),
          ),
        ],
      ),
    );
  }
}
