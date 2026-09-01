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
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

import 'package:orders_sdk/src/manager/presentation/collect/collect_keys.dart';

import 'board_status.dart';
import 'order_clock.dart';

/// The approved order card (frames 33a/33b/33d): customer + order number,
/// info rows (date, total, payment, deliveryman/table), the order-type chip
/// whose colour fill tracks the status progress, and the live clock row.
/// Map-pin affordance on delivery cards; POS drag treatment (slight
/// rotation, shadow, brand border) when [lifted]; brand border when
/// [selected] (the tapped card while its detail holds the last plane).
class BoardOrderCard extends StatelessWidget {
  final OrderData order;
  final BoardStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onMapTap;
  final bool lifted;
  final bool selected;

  const BoardOrderCard({
    super.key,
    required this.order,
    required this.status,
    this.onTap,
    this.onMapTap,
    this.lifted = false,
    this.selected = false,
  });

  bool get _isDelivery => (order.deliveryType ?? '') == BoardRules.deliveryType;

  /// Wire key through getTranslation, the POS's own approach — 'dine_in',
  /// 'delivery' and 'pickup' are store keys (getTranslation prettifies
  /// unknowns, so this never renders a raw key ugly).
  String get _typeLabel => AppHelpers.getTranslation(order.deliveryType ?? '');

  IconData get _typeIcon {
    final type = order.deliveryType ?? '';
    if (type == BoardRules.deliveryType) return FlutterRemix.e_bike_2_fill;
    if (type == BoardRules.dineType) return FlutterRemix.restaurant_line;
    // Pickup reads as a BAG, never a truck and never a walker (section
    // 43, frame 43d): it is the same glyph the convert action and the
    // confirm guard use, so a converted card and the action that made it
    // are recognisably the same thing.
    return FlutterRemix.shopping_bag_3_line;
  }

  String get _initials {
    final first = (order.user?.firstname ?? '').trim();
    final last = (order.user?.lastname ?? '').trim();
    final a = first.isNotEmpty ? first[0] : '';
    final b = last.isNotEmpty ? last[0] : '';
    final joined = '$a$b'.toUpperCase();
    return joined.isEmpty ? '№' : joined;
  }

  String get _name {
    // 'no_name' is a manifest-declared key; lib/ references it by wire
    // string (products_sdk seller_form_helpers precedent — see manifest).
    final first = order.user?.firstname ?? AppHelpers.getTranslation('no_name');
    final last = order.user?.lastname ?? '';
    return '$first $last'.trim();
  }

  DateTime? get _createdAt =>
      order.createdAt == null ? null : DateTime.tryParse(order.createdAt!);

  DateTime? get _updatedAt =>
      order.updatedAt == null ? null : DateTime.tryParse(order.updatedAt!);

  /// Section 43: this order was placed for delivery and collected over
  /// the counter, and the fee went back to the customer's wallet. The
  /// STRUCK fee and the dropped total are the visible proof — fee-kept
  /// versus fee-returned is legible from the card alone, without
  /// opening the order.
  bool get _feeRefunded =>
      order.collectedInPerson && order.collectFeeRefunded > 0;

  /// The same conversion, the other branch: a driver was already on it,
  /// so the fee is kept to cover his callout and nothing is struck.
  bool get _feeKept =>
      order.collectedInPerson && order.collectFeeRefunded <= 0 &&
      (order.deliveryFee ?? 0) > 0;

  String _money(num? value) => AppHelpers.numberFormat(
    number: value ?? 0,
    symbol: order.currency?.symbol,
  );

  @override
  Widget build(BuildContext context) {
    final Color statusColor = status.color;
    final body = Container(
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: lifted
              ? AppStyle.primary.withValues(alpha: 0.75)
              : (selected ? AppStyle.primary : AppStyle.strokeDarkSubtle),
          width: selected ? 1.3 : 1,
        ),
        boxShadow: lifted
            ? const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(11),
      margin: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: 0.20),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: AppStyle.interBold(size: 11.5, color: statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.interSemi(
                        size: 12.5,
                        color: AppStyle.textPrimary,
                      ),
                    ),
                    Text(
                      '№${order.id ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.interNormal(
                        size: 11.5,
                        color: AppStyle.textDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isDelivery && onMapTap != null)
                InkWell(
                  onTap: onMapTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      FlutterRemix.map_pin_2_line,
                      size: 16,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppStyle.strokeDarkSubtle),
          const SizedBox(height: 9),
          _infoRow(
            FlutterRemix.calendar_2_line,
            _createdAt == null
                ? '--'
                : DateFormat('d MMM yy').format(_createdAt!.toLocal()),
          ),
          _infoRow(
            FlutterRemix.money_dollar_circle_line,
            _money(order.totalPrice),
            // 820: the total dropped by the returned fee, and says so.
            struckPrefix: _feeRefunded
                ? _money((order.totalPrice ?? 0) + order.collectFeeRefunded)
                : null,
          ),
          if ((order.deliveryFee ?? 0) > 0 || _feeRefunded)
            _infoRow(
              FlutterRemix.e_bike_2_fill,
              _feeRefunded ? '' : _money(order.deliveryFee),
              label: AppHelpers.getTranslation(CollectKeys.deliveryFeeRow),
              // 820: struck, because it is not on this order any more.
              struckPrefix:
                  _feeRefunded ? _money(order.collectFeeRefunded) : null,
            ),
          _infoRow(
            FlutterRemix.bank_card_line,
            order.transaction?.paymentSystem?.tag ?? '- -',
          ),
          if ((order.table?.name ?? '').isNotEmpty)
            _infoRow(Icons.table_restaurant_outlined, order.table?.name ?? ''),
          const SizedBox(height: 4),
          _typeChip(statusColor),
          if (order.collectedInPerson) ...[
            const SizedBox(height: 8),
            _collectNote(),
          ],
          const SizedBox(height: 8),
          OrderClockRow(
            createdAt: _createdAt,
            updatedAt: _updatedAt,
            status: status,
          ),
        ],
      ),
    );
    final interactive = onTap == null
        ? body
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: body,
          );
    if (!lifted) return interactive;
    // POS drag treatment: the lifted card tilts slightly.
    return Transform.rotate(angle: 0.03, child: interactive);
  }

  /// [label] prefixes the value ("Delivery fee R35.00"); [struckPrefix]
  /// renders an amount that no longer applies, struck through, ahead of
  /// the value that replaced it — the one structural difference between
  /// the two converted card states (820 / 821).
  Widget _infoRow(
    IconData icon,
    String value, {
    String? label,
    String? struckPrefix,
  }) {
    final TextStyle base = AppStyle.interNormal(
      size: 12,
      color: AppStyle.textDarkSecondary,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppStyle.textDarkSecondary),
          const SizedBox(width: 7),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: base,
                children: [
                  if (label != null) TextSpan(text: '$label '),
                  if (struckPrefix != null)
                    TextSpan(
                      text: struckPrefix,
                      style: base.copyWith(
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppStyle.textDarkSecondary,
                      ),
                    ),
                  if (struckPrefix != null && value.isNotEmpty)
                    const TextSpan(text: ' '),
                  if (value.isNotEmpty) TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 820 / 821 — the note slot. ONE component with a two-value note:
  /// green when the fee went back to the customer, amber when it was
  /// kept to cover a driver's callout. Nothing else about the card
  /// changes between the two.
  Widget _collectNote() {
    final Color accent = _feeKept ? AppStyle.rate : AppStyle.green;
    final String text = AppHelpers.getTranslation(
      _feeKept
          ? CollectKeys.feeKeptCoversTheDriversCallout
          : (_feeRefunded
                ? CollectKeys.feeRefundedToWallet
                : CollectKeys.collectedInPerson),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interSemi(size: 11, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  /// The order-type chip: label + progress % over a partial colour fill,
  /// with the type glyph in a circle at the end (POS
  /// `buildDeliveryTypeContainer` in the approved dark clothing).
  Widget _typeChip(Color statusColor) {
    final progress = status.progress;
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppStyle.strokeDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: progress == 0 ? 0.001 : progress,
            child: Container(color: statusColor.withValues(alpha: 0.30)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(
                      size: 11.5,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppStyle.interSemi(
                    size: 10.5,
                    color: AppStyle.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppStyle.surfaceDark,
                    border: Border.all(color: AppStyle.strokeDark),
                  ),
                  child: Icon(_typeIcon, size: 14, color: AppStyle.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
