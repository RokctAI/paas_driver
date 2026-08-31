// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:orders_sdk/src/manager/application/orders/accepted/accepted_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/cooking/cooking_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/new/new_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/on_a_way/on_a_way_orders_provider.dart';
import 'package:orders_sdk/src/manager/application/orders/ready/ready_orders_provider.dart';

import 'board_prefs.dart';
import 'board_refresh.dart';
import 'board_sound.dart';

/// The approved workspace header (frames 33a/33b): title + open-order
/// count, the sound-alert bell with its orange activity dot, the
/// date-range filter chip (compact: icon button) and the board/list view
/// toggle. Also hosts the new-order chime: it observes the NEW and
/// ACCEPTED queue sizes (POS `_checkAndPlaySound`) and rings/marks the
/// bell when either grows.
class OrdersBoardHeader extends ConsumerStatefulWidget {
  final bool compact;

  /// Hidden on phones when the board mode makes no sense? No — the toggle
  /// ships on both per the approved frames; the phone simply defaults to
  /// list.
  const OrdersBoardHeader({super.key, this.compact = false});

  @override
  ConsumerState<OrdersBoardHeader> createState() => _OrdersBoardHeaderState();
}

class _OrdersBoardHeaderState extends ConsumerState<OrdersBoardHeader> {
  final NewOrderChime _chime = NewOrderChime();

  void _checkChime() {
    final int newCount = ref.read(newOrdersProvider).orders.length;
    final int acceptedCount = ref.read(acceptedOrdersProvider).orders.length;
    final bool ring = _chime.register(
      newCount: newCount,
      acceptedCount: acceptedCount,
    );
    if (!ring) return;
    final prefs = ref.read(boardPrefsProvider);
    if (prefs.soundEnabled) _chime.play();
    ref.read(boardPrefsProvider.notifier).markActivity();
  }

  Future<void> _pickRange() async {
    final prefs = ref.read(boardPrefsProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: prefs.from == null || prefs.to == null
          ? null
          : DateTimeRange(start: prefs.from!, end: prefs.to!),
    );
    if (picked == null || !mounted) return;
    ref.read(boardPrefsProvider.notifier).setRange(picked.start, picked.end);
    refreshBoardColumns(ref, context, role: LocalStorage.getUser()?.role);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(boardPrefsProvider);
    // Observe the two alert queues so arrivals re-run the chime check.
    ref.watch(newOrdersProvider.select((s) => s.orders.length));
    ref.watch(acceptedOrdersProvider.select((s) => s.orders.length));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkChime();
    });

    final int openCount =
        ref.watch(newOrdersProvider).totalCount +
        ref.watch(acceptedOrdersProvider).totalCount +
        ref.watch(cookingOrdersProvider).totalCount +
        ref.watch(readyOrdersProvider).totalCount +
        ref.watch(onAWayOrdersProvider).totalCount;

    final double sidePadding = widget.compact ? 16 : 20;
    return Padding(
      padding: EdgeInsets.fromLTRB(sidePadding, 14, sidePadding, 10),
      child: Row(
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.orders),
            style: AppStyle.interBold(
              size: widget.compact ? 20 : 23,
              color: AppStyle.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppStyle.strokeDark),
            ),
            child: Text(
              '$openCount ${AppHelpers.getTranslation(TrKeys.open).toLowerCase()}',
              style: AppStyle.interNormal(
                size: 11,
                color: AppStyle.textDarkSecondary,
              ),
            ),
          ),
          const Spacer(),
          _bell(prefs),
          const SizedBox(width: 8),
          _dateChip(prefs),
          const SizedBox(width: 8),
          _viewToggle(prefs),
        ],
      ),
    );
  }

  Widget _bell(BoardPrefsState prefs) {
    return InkWell(
      onTap: () => ref.read(boardPrefsProvider.notifier).toggleSound(),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppStyle.strokeDark),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                prefs.soundEnabled
                    ? FlutterRemix.notification_2_line
                    : FlutterRemix.notification_off_line,
                size: 17,
                color: AppStyle.textPrimary,
              ),
            ),
            if (prefs.hasActivity)
              Positioned(
                right: 7,
                top: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppStyle.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip(BoardPrefsState prefs) {
    if (widget.compact) {
      return InkWell(
        onTap: _pickRange,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppStyle.cardDark,
            shape: BoxShape.circle,
            border: Border.all(
              color: prefs.from != null
                  ? AppStyle.primary
                  : AppStyle.strokeDark,
            ),
          ),
          child: Icon(
            FlutterRemix.calendar_line,
            size: 16,
            color: AppStyle.textDarkSecondary,
          ),
        ),
      );
    }
    final String label = prefs.from == null || prefs.to == null
        ? AppHelpers.getTranslation('start_end')
        : '${DateFormat('d MMM').format(prefs.from!)} – '
              '${DateFormat('d MMM').format(prefs.to!)}';
    return InkWell(
      onTap: _pickRange,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppStyle.cardDark,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppStyle.strokeDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FlutterRemix.calendar_line,
              size: 15,
              color: AppStyle.textDarkSecondary,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppStyle.interNormal(
                size: 12,
                color: AppStyle.textPrimary,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down,
              size: 15,
              color: AppStyle.textDarkFaint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewToggle(BoardPrefsState prefs) {
    Widget seg({
      required IconData icon,
      required bool active,
      required VoidCallback onTap,
    }) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 40,
        height: 32,
        decoration: BoxDecoration(
          color: active ? AppStyle.primary : AppStyle.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? const Color(0xFFFFFFFF) : AppStyle.textDarkSecondary,
        ),
      ),
    );
    final notifier = ref.read(boardPrefsProvider.notifier);
    final bool listActive = prefs.listView(compact: widget.compact);
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppStyle.cardDark,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppStyle.strokeDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(
            icon: FlutterRemix.layout_column_line,
            active: !listActive,
            onTap: () => notifier.setListView(false),
          ),
          seg(
            icon: FlutterRemix.list_check_2,
            active: listActive,
            onTap: () => notifier.setListView(true),
          ),
        ],
      ),
    );
  }
}
