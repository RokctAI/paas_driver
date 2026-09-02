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
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:kitchen_sdk/src/manager/application/kitchen/kitchen_provider.dart';
import 'package:kitchen_sdk/src/manager/infrastructure/models/data/kitchen_order_data.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_clock.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_order_card.dart';
import 'package:kitchen_sdk/src/manager/presentation/kitchen/kitchen_status.dart';

/// The selected order's detail (approved 34a plane 3 / 34c phone push):
/// order header with status pill and the small clock; the dish-by-dish
/// prep pills — TAP advances a line, DOUBLE-TAP cancels it (34d), with
/// the affordance hint as real microcopy; the cook-visible customer note;
/// and the one-tap flow — Start cooking / Mark order ready (guarded) /
/// hand-over on a Ready order — with the confirm-guarded Cancel.
class KitchenDetailPane extends ConsumerWidget {
  final KitchenOrderData order;

  const KitchenDetailPane({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = order.createdAt == null
        ? ''
        : DateFormat('d MMM').format(order.createdAt!.toLocal());
    return ColoredBox(
      color: AppStyle.surfaceDark,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppHelpers.getTranslation(TrKeys.order)} '
                    '#${_shortId(order.id)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interBold(
                      size: 17,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                ),
                KitchenCardBits.statusPill(order.status, fontSize: 11),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$dateLabel · ${KitchenCardBits.placedTime(order.createdAt)}'
                    ' · ${KitchenCardBits.typeLabel(order.deliveryType)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyle.interNormal(
                      size: 11.5,
                      color: AppStyle.textDarkSecondary,
                    ),
                  ),
                ),
                KitchenFlipClock(
                  status: order.status,
                  createdAt: order.createdAt,
                  updatedAt: order.updatedAt,
                  tileWidth: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: AppStyle.strokeDarkSubtle),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    '${AppHelpers.getTranslation('dishes').toUpperCase()}'
                    ' · ${order.dishes.length}',
                    style: AppStyle.interBold(
                      size: 10.5,
                      color: AppStyle.textDarkFaint,
                    ),
                  ),
                  const SizedBox(height: 11),
                  for (final dish in order.dishes)
                    _DishLine(order: order, dish: dish),
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 12,
                        color: AppStyle.textDarkFaint,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          AppHelpers.getTranslation(
                            'tap_a_dish_to_advance_double_tap_cancels',
                          ),
                          style: AppStyle.interNormal(
                            size: 10.5,
                            color: AppStyle.textDarkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if ((order.note ?? '').isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _noteCard(order.note!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            _actions(context, ref),
          ],
        ),
      ),
    );
  }

  String _shortId(String? id) {
    final value = id ?? '';
    return value.length > 8 ? value.substring(value.length - 8) : value;
  }

  Widget _noteCard(String note) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppStyle.rate.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppStyle.rate.withValues(alpha: 0.45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.sticky_note_2_outlined, size: 16, color: AppStyle.rate),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppHelpers.getTranslation('customer_note'),
                style: AppStyle.interBold(size: 10.5, color: AppStyle.rate),
              ),
              const SizedBox(height: 3),
              Text(
                note,
                style: AppStyle.interNormal(
                  size: 12,
                  color: AppStyle.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _actions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(kitchenProvider.notifier);
    final isUpdating = ref.watch(kitchenProvider.select((s) => s.isUpdating));
    final children = <Widget>[];

    switch (order.status) {
      case KitchenStatus.accepted:
        children.add(
          _primaryButton(
            label: AppHelpers.getTranslation('start_cooking'),
            enabled: !isUpdating,
            onTap: notifier.startCooking,
          ),
        );
      case KitchenStatus.cooking:
        children.add(
          _primaryButton(
            label: AppHelpers.getTranslation('mark_order_ready'),
            enabled:
                !isUpdating && KitchenRules.canMarkReady(order.dishStatuses),
            onTap: notifier.markReady,
          ),
        );
      case KitchenStatus.ready:
        children.add(
          _primaryButton(
            label: AppHelpers.getTranslation('hand_over'),
            enabled: !isUpdating,
            onTap: notifier.handOver,
          ),
        );
      case KitchenStatus.canceled:
        break;
    }

    if (order.status != KitchenStatus.canceled) {
      children.add(const SizedBox(height: 10));
      children.add(_cancelButton(context, ref));
    }
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _primaryButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(100),
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: AppStyle.primary,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              label,
              style: AppStyle.interSemi(size: 14, color: AppStyle.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  /// "Cancel order…" — the ellipsis signals the confirm step; the dialog
  /// is the guard the POS carried (order_info.dart:223-267).
  Widget _cancelButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _confirmCancel(context, ref),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppStyle.red.withValues(alpha: 0.7)),
        ),
        child: Center(
          child: Text(
            '${AppHelpers.getTranslation(TrKeys.cancelOrder)}…',
            style: AppStyle.interSemi(size: 13, color: AppStyle.red),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(kitchenProvider.notifier);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppStyle.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppStyle.strokeDark),
        ),
        content: Text(
          AppHelpers.getTranslation(TrKeys.areYouSure),
          style: AppStyle.interNormal(size: 14, color: AppStyle.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              AppHelpers.getTranslation(TrKeys.cancel),
              style: AppStyle.interSemi(
                size: 13,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              AppHelpers.getTranslation(TrKeys.cancelOrder),
              style: AppStyle.interSemi(size: 13, color: AppStyle.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.cancelOrder();
    }
  }
}

/// One dish line: name ×qty (struck through when cancelled) with its
/// tappable status pill — Pending / Preparing / Done / Cancelled (34d).
class _DishLine extends ConsumerWidget {
  final KitchenOrderData order;
  final KitchenDishData dish;

  const _DishLine({required this.order, required this.dish});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(kitchenProvider.notifier);
    final status = dish.status;
    final bool editable =
        KitchenRules.tapAdvance(status) != null && !order.status.isTerminal;
    final bool cancellable =
        KitchenRules.canCancelDish(status) && !order.status.isTerminal;
    final bool struck = status == DishStatus.canceled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              dish.quantity > 1
                  ? '${dish.title ?? ''}  ×${dish.quantity}'
                  : (dish.title ?? ''),
              style: AppStyle.interSemi(
                size: 13.5,
                color: struck ? AppStyle.textDarkFaint : AppStyle.textPrimary,
              ).copyWith(
                decoration: struck
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppStyle.textDarkFaint,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: editable ? () => notifier.tapDish(dish) : null,
            onDoubleTap: cancellable ? () => notifier.cancelDish(dish) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: status.color.withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppHelpers.getTranslation(status.labelKey),
                    style: AppStyle.interSemi(size: 11.5, color: status.color),
                  ),
                  if (editable) ...[
                    const SizedBox(width: 5),
                    Icon(
                      Icons.touch_app_outlined,
                      size: 13,
                      color: status.color,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
