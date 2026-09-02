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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';

import 'kitchen_status.dart';

/// What the kitchen flip clock is showing (approved 34a/34b; POS
/// orders_info.dart FlipNumber + startTimer).
enum KitchenClockMode {
  /// No clock — an accepted order shows the "Just in" ping instead.
  none,

  /// White digits: cooking, under 30 minutes.
  normal,

  /// Amber digits + amber tile border: cooking >= 30 minutes (POS
  /// AppStyle.rate threshold, orders_info.dart:230-235).
  warn,

  /// Red digits + the red "Delayed" tag: cooking >= 60 minutes. The POS
  /// swapped the whole clock for the word (orders_info.dart:216-225); the
  /// approved design keeps the red clock visible AND adds the tag, so the
  /// cook still sees how late it actually is (captions.md judgment call).
  delayed,

  /// Ready/Cancelled: frozen at the order's actual span, dimmed (POS
  /// orders_info.dart:179-192 — Ready freezes at created→updated and dims
  /// 50%).
  frozen,
}

/// The clock's pure rules, kept widget-free for unit tests (orders_sdk
/// OrderClock precedent).
abstract final class KitchenClock {
  static const Duration warnAfter = Duration(minutes: 30);
  static const Duration delayAfter = Duration(minutes: 60);

  /// Mode from the order's kitchen status and elapsed time.
  ///
  /// The POS ticked from the cooking-start timestamp; this backend's
  /// `modified` moves on every save (a dish tap would reset the clock), so
  /// the kitchen ticks from the order's CREATION — the time the customer
  /// has actually been waiting — and freezes at creation→modified when the
  /// order reaches Ready/Cancelled. Same freeze rule, honest baseline.
  static KitchenClockMode mode({
    required KitchenStatus status,
    required Duration elapsed,
  }) {
    switch (status) {
      case KitchenStatus.accepted:
        return KitchenClockMode.none;
      case KitchenStatus.cooking:
        if (elapsed >= delayAfter) return KitchenClockMode.delayed;
        if (elapsed >= warnAfter) return KitchenClockMode.warn;
        return KitchenClockMode.normal;
      case KitchenStatus.ready:
      case KitchenStatus.canceled:
        return KitchenClockMode.frozen;
    }
  }

  /// The end instant of the visible span: frozen orders stop at
  /// [updatedAt]; live orders read "now". Null means keep ticking.
  static DateTime? frozenEnd({
    required KitchenStatus status,
    DateTime? updatedAt,
  }) {
    switch (status) {
      case KitchenStatus.ready:
      case KitchenStatus.canceled:
        return updatedAt;
      case KitchenStatus.accepted:
      case KitchenStatus.cooking:
        return null;
    }
  }

  /// hh (empty when zero-hours, as in the POS which only showed the hours
  /// tile when > 0), mm, ss faces for a duration.
  static ({String hh, String mm, String ss}) faces(Duration elapsed) {
    final clamped = elapsed.isNegative ? Duration.zero : elapsed;
    final h = clamped.inHours;
    final m = clamped.inMinutes % 60;
    final s = clamped.inSeconds % 60;
    return (
      hh: h > 0 ? h.toString().padLeft(2, '0') : '',
      mm: m.toString().padLeft(2, '0'),
      ss: s.toString().padLeft(2, '0'),
    );
  }
}

/// The split-flap clock of the approved frames: mono digits on dark tiles
/// with a seam line, hours tile only when > 0, amber at 30 minutes, red +
/// "Delayed" tag at the hour, frozen and dimmed once the order is done.
/// Ticks every second only while the order is live.
class KitchenFlipClock extends StatefulWidget {
  final KitchenStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Tile width in logical pixels (the frames use 26 on cards, 20 in the
  /// detail header).
  final double tileWidth;

  /// Injectable "now" so tests can drive the tick; defaults to the wall
  /// clock.
  final DateTime Function()? clock;

  const KitchenFlipClock({
    super.key,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.tileWidth = 26,
    this.clock,
  });

  @override
  State<KitchenFlipClock> createState() => _KitchenFlipClockState();
}

class _KitchenFlipClockState extends State<KitchenFlipClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(KitchenFlipClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.createdAt != widget.createdAt) {
      _configure();
    }
  }

  DateTime? get _frozen =>
      KitchenClock.frozenEnd(status: widget.status, updatedAt: widget.updatedAt);

  void _configure() {
    _timer?.cancel();
    _timer = null;
    if (_frozen == null && widget.status == KitchenStatus.cooking) {
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
    final elapsed = end.difference(start);
    final mode = KitchenClock.mode(status: widget.status, elapsed: elapsed);
    if (mode == KitchenClockMode.none) return const SizedBox.shrink();

    final faces = KitchenClock.faces(elapsed);
    final Color digit;
    final Color border;
    switch (mode) {
      case KitchenClockMode.warn:
        digit = AppStyle.rate;
        border = AppStyle.rate.withValues(alpha: 0.55);
      case KitchenClockMode.delayed:
        digit = AppStyle.red;
        border = AppStyle.red.withValues(alpha: 0.6);
      default:
        digit = AppStyle.textPrimary;
        border = AppStyle.strokeDark;
    }

    final w = widget.tileWidth;
    Widget colon() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Text(
        ':',
        style: _mono(w * 0.5, AppStyle.textDarkSecondary),
      ),
    );

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (faces.hh.isNotEmpty) ...[_tile(faces.hh, digit, border), colon()],
        _tile(faces.mm, digit, border),
        colon(),
        _tile(faces.ss, digit, border),
        if (mode == KitchenClockMode.delayed) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppStyle.red.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppStyle.red.withValues(alpha: 0.65)),
            ),
            child: Text(
              AppHelpers.getTranslation('delayed'),
              style: AppStyle.interBold(size: 9.5, color: AppStyle.red),
            ),
          ),
        ],
      ],
    );
    if (mode == KitchenClockMode.frozen) {
      return Opacity(opacity: 0.45, child: row);
    }
    return row;
  }

  TextStyle _mono(double size, Color color) => TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: const ['Courier', 'monospace'],
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    decoration: TextDecoration.none,
  );

  Widget _tile(String value, Color digit, Color border) {
    final w = widget.tileWidth;
    return Container(
      width: w,
      height: w * 1.18,
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Stack(
        children: [
          Center(child: Text(value, style: _mono(w * 0.5, digit))),
          // The split-flap seam.
          Positioned(
            left: 2,
            right: 2,
            top: w * 1.18 / 2,
            child: Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
