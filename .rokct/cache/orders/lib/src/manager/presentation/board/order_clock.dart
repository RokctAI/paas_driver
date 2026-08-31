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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'board_status.dart';

/// The per-card elapsed clock (POS `drag_item.dart` OrderTimerNotifier,
/// Timer.periodic 1s) as pure functions plus one small ticking widget.
abstract final class OrderClock {
  /// `4m` / `1h` / `2d` — POS `_calculateTimeDifference` verbatim.
  static String elapsed(Duration difference) {
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    }
    return '${difference.inMinutes}m';
  }

  /// `11:59am - 12:08pm` — POS `_formatTimeRange` verbatim.
  static String range(DateTime start, DateTime end) {
    final startFormat = DateFormat(
      'h:mma',
    ).format(start.toLocal()).toLowerCase();
    final endFormat = DateFormat('h:mma').format(end.toLocal()).toLowerCase();
    return '$startFormat - $endFormat';
  }

  /// The FREEZE rule: once an order reaches Ready its clock stops at
  /// [updatedAt] so the kitchen's actual turnaround stays readable (POS:
  /// `endTime` only when status == ready). The history columns freeze the
  /// same way — a delivered order's range is its lifetime, not
  /// "until now" (matches the approved frames; the POS let history tick
  /// on, which is meaningless on a delivered card).
  static DateTime? frozenEnd({
    required BoardStatus status,
    DateTime? updatedAt,
  }) {
    switch (status) {
      case BoardStatus.ready:
      case BoardStatus.delivered:
      case BoardStatus.canceled:
        return updatedAt;
      case BoardStatus.newOrder:
      case BoardStatus.accepted:
      case BoardStatus.cooking:
      case BoardStatus.onWay:
        return null;
    }
  }
}

/// The card's bottom row: bold elapsed clock at the start, start–end time
/// range at the end. Ticks every second while the order is live; frozen at
/// [OrderClock.frozenEnd] once the status freezes it.
class OrderClockRow extends StatefulWidget {
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final BoardStatus status;

  /// Injectable "now" so tests can drive the tick; defaults to the wall
  /// clock.
  final DateTime Function()? clock;

  const OrderClockRow({
    super.key,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.clock,
  });

  @override
  State<OrderClockRow> createState() => _OrderClockRowState();
}

class _OrderClockRowState extends State<OrderClockRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(OrderClockRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.createdAt != widget.createdAt) {
      _configure();
    }
  }

  DateTime? get _frozen =>
      OrderClock.frozenEnd(status: widget.status, updatedAt: widget.updatedAt);

  void _configure() {
    _timer?.cancel();
    _timer = null;
    if (_frozen == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.createdAt;
    if (start == null) return const SizedBox.shrink();
    final end = _frozen ?? (widget.clock ?? DateTime.now)();
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 13, color: AppStyle.textPrimary),
        const SizedBox(width: 4),
        Text(
          OrderClock.elapsed(end.difference(start)),
          style: AppStyle.interBold(size: 11.5, color: AppStyle.textPrimary),
        ),
        const Spacer(),
        Text(
          OrderClock.range(start, end),
          style: AppStyle.interNormal(size: 10, color: AppStyle.textDarkFaint),
        ),
      ],
    );
  }
}
