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

import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';

import 'collect_keys.dart';

/// 810 — the delivery-type chip, lifted out of the board card into the
/// order detail: the same 34px tinted bar (`board_card.dart`'s
/// `_typeChip`, 30%-alpha status wash) carrying the type glyph, the type
/// label, and the address trailing.
class CollectTypeChip extends StatelessWidget {
  final OrderData order;
  final BoardStatus status;

  const CollectTypeChip({super.key, required this.order, required this.status});

  bool get _isDelivery =>
      (order.deliveryType ?? '').trim().toLowerCase() ==
      BoardRules.deliveryType;

  bool get _isDineIn =>
      (order.deliveryType ?? '').trim().toLowerCase() == BoardRules.dineType;

  IconData get _glyph {
    if (_isDelivery) return FlutterRemix.e_bike_2_fill;
    if (_isDineIn) return FlutterRemix.restaurant_line;
    return FlutterRemix.shopping_bag_3_line;
  }

  String get _address =>
      order.orderAddress?.address ?? order.table?.name ?? '';

  @override
  Widget build(BuildContext context) {
    final Color wash = status.color;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: wash.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(_glyph, size: 16, color: AppStyle.textPrimary),
          const SizedBox(width: 8),
          Text(
            AppHelpers.getTranslation(order.deliveryType ?? ''),
            style: AppStyle.interSemi(size: 12.5, color: AppStyle.textPrimary),
          ),
          const Spacer(),
          if (_address.isNotEmpty)
            Flexible(
              child: Text(
                _address,
                maxLines: 1,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.interNormal(
                  size: 12,
                  color: AppStyle.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 811 / 812 — the deliveryman row. ONE component with two states, and
/// this row is what decides the branch: dashed and faint means nothing
/// has been committed to a driver, so the fee can still go back; solid
/// and cyan means somebody already drove for it.
class CollectDriverRow extends StatelessWidget {
  final String? driverName;
  final String? assignedAtLabel;

  const CollectDriverRow({super.key, this.driverName, this.assignedAtLabel});

  bool get _assigned => (driverName ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final Color accent = BoardStatus.onWay.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppStyle.cardDarkAlt,
        borderRadius: BorderRadius.circular(12),
        // Assigned: a solid hairline. Empty: nothing here, because the
        // dashed stroke below IS the border - two would double-draw.
        border: _assigned ? Border.all(color: AppStyle.strokeDark) : null,
      ),
      foregroundDecoration: _assigned
          ? null
          : _DashedBorder(color: AppStyle.strokeDark, radius: 12),
      child: Row(
        children: [
          Icon(
            FlutterRemix.truck_line,
            size: 20,
            color: _assigned ? accent : AppStyle.textDarkSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _assigned
                      ? driverName!
                      : AppHelpers.getTranslation(
                          CollectKeys.noDriverAssignedYet,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyle.interSemi(
                    size: 13,
                    color: _assigned
                        ? AppStyle.textPrimary
                        : AppStyle.textDarkSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _assigned
                      ? (assignedAtLabel ??
                            AppHelpers.getTranslation(CollectKeys.assigned))
                      : AppHelpers.getTranslation(
                          CollectKeys.nobodyDispatched,
                        ),
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
          if (_assigned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: accent.withValues(alpha: 0.55)),
              ),
              child: Text(
                AppHelpers.getTranslation(CollectKeys.onACallout).toUpperCase(),
                style: AppStyle.interSemi(size: 10, color: accent),
              ),
            ),
        ],
      ),
    );
  }
}

/// 814 / 815 — the outcome line. ONE component, two tints and two
/// copies; never both on screen. The consequence is named BEFORE the
/// tap, with the amount and where it lands, because afterwards is too
/// late for the money.
class CollectOutcomeLine extends StatelessWidget {
  /// Null renders the offline note (43e): the till cannot know which
  /// branch applies, so it promises nothing about the fee.
  final bool? driverAssigned;
  final String? driverName;
  final String feeText;

  const CollectOutcomeLine({
    super.key,
    required this.driverAssigned,
    required this.feeText,
    this.driverName,
  });

  @override
  Widget build(BuildContext context) {
    final bool? assigned = driverAssigned;
    final Color accent = assigned == null
        ? AppStyle.textDarkSecondary
        : (assigned ? AppStyle.rate : AppStyle.green);
    final double washAlpha = assigned == true ? 0.07 : 0.08;
    final double borderAlpha = assigned == true ? 0.22 : 0.26;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: assigned == null
            ? AppStyle.cardDarkAlt
            : accent.withValues(alpha: washAlpha),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: assigned == null
              ? AppStyle.strokeDark
              : accent.withValues(alpha: borderAlpha),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            assigned == null
                ? FlutterRemix.time_line
                : FlutterRemix.bank_card_line,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(child: _copy(accent)),
        ],
      ),
    );
  }

  Widget _copy(Color accent) {
    final TextStyle plain = AppStyle.interNormal(
      size: 12.5,
      color: AppStyle.textPrimary,
    );
    final TextStyle strong = AppStyle.interSemi(size: 12.5, color: accent);
    if (driverAssigned == null) {
      return Text(
        AppHelpers.getTranslation(CollectKeys.offlineHandOverNote),
        style: AppStyle.interNormal(
          size: 12.5,
          color: AppStyle.textDarkSecondary,
        ),
      );
    }
    if (driverAssigned == true) {
      return RichText(
        text: TextSpan(
          style: plain,
          children: [
            TextSpan(
              text: (driverName ?? '').trim().isEmpty
                  ? AppHelpers.getTranslation(CollectKeys.assigned)
                  : driverName!,
              style: AppStyle.interSemi(
                size: 12.5,
                color: AppStyle.textPrimary,
              ),
            ),
            TextSpan(
              text: ' '
                  '${AppHelpers.getTranslation(CollectKeys.aDriverWasAlreadyOnThisOneSoThe)} ',
            ),
            TextSpan(
              text:
                  '$feeText ${AppHelpers.getTranslation(CollectKeys.feeIsKept)}',
              style: strong,
            ),
            TextSpan(
              text: ' — '
                  '${AppHelpers.getTranslation(CollectKeys.itCoversTheCalloutHisTaskCancels)}',
            ),
          ],
        ),
      );
    }
    return RichText(
      text: TextSpan(
        style: plain,
        children: [
          TextSpan(
            text:
                '${AppHelpers.getTranslation(CollectKeys.noDriverWasOnItYetSoThe)} ',
          ),
          TextSpan(
            text: '$feeText '
                '${AppHelpers.getTranslation(CollectKeys.deliveryFeeGoesBackToTheCustomersWallet)}',
            style: strong,
          ),
          TextSpan(
            text:
                ' ${AppHelpers.getTranslation(CollectKeys.theMomentYouConvert)}',
          ),
        ],
      ),
    );
  }
}

/// 813 — the action lane. ONE verb, a bag glyph and never a truck, and
/// it is ENABLED offline too, relabelled in place (43e): refusing to
/// give the customer her goods is the one thing that must never happen.
class CollectActionLane extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool offline;
  final bool busy;

  const CollectActionLane({
    super.key,
    required this.onPressed,
    this.offline = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyle.primary,
          disabledBackgroundColor: AppStyle.primary.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FlutterRemix.shopping_bag_3_line,
                    size: 18,
                    color: AppStyle.white,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      AppHelpers.getTranslation(
                        offline
                            ? CollectKeys.handOverNowConvertWhenBackOnline
                            : CollectKeys.customerIsHereConvertToPickup,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyle.interSemi(
                        size: 14,
                        color: AppStyle.white,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// 816 — Ray's till line, unedited, gaining one resolving clause once
/// the order in hand is known to have had a driver on it.
class CollectTillLine extends StatelessWidget {
  final bool? driverAssigned;

  const CollectTillLine({super.key, this.driverAssigned});

  @override
  Widget build(BuildContext context) {
    final String base = AppHelpers.getTranslation(
      CollectKeys.feeComesBackIfNoDriverWasOnItYet,
    );
    final String resolved = driverAssigned == true
        ? '$base ${AppHelpers.getTranslation(CollectKeys.thisOneHadADriverOnItSoItDoesNot)}'
        : base;
    return Text(
      resolved,
      textAlign: TextAlign.center,
      style: AppStyle.interNormal(size: 11, color: AppStyle.textDarkSecondary),
    );
  }
}

/// The dashed stroke of the empty deliveryman row (811). Drawn rather
/// than borrowed: nothing in base_sdk paints one.
class _DashedBorder extends Decoration {
  final Color color;
  final double radius;

  const _DashedBorder({required this.color, required this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _DashedBorderPainter(color: color, radius: radius);
}

class _DashedBorderPainter extends BoxPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size size = configuration.size ?? Size.zero;
    if (size.isEmpty) return;
    final RRect rrect = RRect.fromRectAndRadius(
      offset & size,
      Radius.circular(radius),
    );
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final Path path = Path()..addRRect(rrect);
    const double dash = 5;
    const double gap = 4;
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dash),
          paint,
        );
        distance += dash + gap;
      }
    }
  }
}
