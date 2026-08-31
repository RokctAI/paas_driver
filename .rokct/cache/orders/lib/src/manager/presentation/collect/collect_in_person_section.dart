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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:orders_sdk/src/manager/application/collect/collect_conversion_provider.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';
import 'package:orders_sdk/src/manager/presentation/board/board_status.dart';
import 'package:orders_sdk/src/manager/presentation/board/order_clock.dart';

import 'collect_confirm_sheet.dart';
import 'collect_in_person_panel.dart';
import 'collect_keys.dart';

/// The whole of "the customer turned up for a delivery order", as one
/// block the order detail mounts under its price block (design strip
/// section 43, frames 43a tablet / 43c phone / 43b the confirm guard /
/// 43e offline).
///
/// It shows only on a DELIVERY order that has not been handed over yet —
/// there is nothing to convert on a pickup, and a delivered order is
/// history. What it renders, in order: the deliveryman row (811 empty /
/// 812 assigned, the row that decides the branch), the single primary
/// action lane (813), the outcome named before the tap (814 green / 815
/// amber), and Ray's till line (816).
///
/// Offline (43e) the lane is RELABELLED IN PLACE and stays ENABLED —
/// refusing to give the customer her goods is the one thing that must
/// never happen — and 814/815 are replaced by a neutral note, because
/// the driver check and the wallet credit both live on the server and
/// the till cannot know which branch applies. The confirm guard is not
/// shown then either: it exists to disclose a money outcome, and offline
/// there is no outcome yet to disclose.
class CollectInPersonSection extends ConsumerStatefulWidget {
  final OrderData order;

  /// Fired once the conversion has landed (or been queued), so the host
  /// can refetch its queues — the order has moved to Delivered.
  final VoidCallback? onConverted;

  /// Injectable "now" so the assigned-since label is testable.
  final DateTime Function()? clock;

  /// Injectable connectivity probe (defaults to the radio check).
  final Future<bool> Function()? connectivity;

  const CollectInPersonSection({
    super.key,
    required this.order,
    this.onConverted,
    this.clock,
    this.connectivity,
  });

  @override
  ConsumerState<CollectInPersonSection> createState() =>
      _CollectInPersonSectionState();
}

class _CollectInPersonSectionState
    extends ConsumerState<CollectInPersonSection> {
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    // On demand, once, never polled (AppConnectivity's own rule). A
    // false negative only costs a relabel: the endpoint is idempotent
    // and the queued op converges on the same conversion.
    final probe = widget.connectivity ?? AppConnectivity.connectivity;
    final online = await probe();
    if (mounted) setState(() => _online = online);
  }

  OrderData get _order => widget.order;

  String? get _orderId => _order.id;

  bool get _isDelivery =>
      (_order.deliveryType ?? '').trim().toLowerCase() ==
      BoardRules.deliveryType;

  bool get _driverAssigned =>
      (_order.deliveryman?.toString() ?? '').trim().isNotEmpty;

  String? get _driverName {
    final named = (_order.deliverymanName ?? '').trim();
    if (named.isNotEmpty) return named;
    final id = (_order.deliveryman?.toString() ?? '').trim();
    return id.isEmpty ? null : id;
  }

  String get _feeText => AppHelpers.numberFormat(
    number: _order.deliveryFee ?? 0,
    symbol: _order.currency?.symbol,
  );

  String get _totalText => AppHelpers.numberFormat(
    number: _order.totalPrice ?? 0,
    symbol: _order.currency?.symbol,
  );

  String get _customerName {
    final first = _order.user?.firstname ?? '';
    final last = _order.user?.lastname ?? '';
    final joined = '$first $last'.trim();
    return joined.isEmpty
        ? AppHelpers.getTranslation('no_name')
        : joined;
  }

  /// "assigned · 6m" — the driver has had it that long. Frozen off the
  /// order's own updated_at, the same source the board's clock reads.
  String? get _assignedLabel {
    if (!_driverAssigned) return null;
    final updated = _order.updatedAt == null
        ? null
        : DateTime.tryParse(_order.updatedAt!);
    final assigned = AppHelpers.getTranslation(CollectKeys.assigned);
    if (updated == null) return assigned;
    final now = (widget.clock ?? DateTime.now)();
    final elapsed = now.difference(updated.toLocal());
    if (elapsed.isNegative) return assigned;
    return '$assigned · ${AppHelpers.getTranslation(CollectKeys.pickedUp)} '
        '${OrderClock.elapsed(elapsed)}';
  }

  Future<void> _convert() async {
    final id = _orderId;
    if (id == null || id.isEmpty) return;
    if (_online) {
      final confirmed = await CollectConfirmSheet.show(
        context,
        CollectConfirmSheet(
          customerName: _customerName,
          orderId: id,
          totalText: _totalText,
          feeText: _feeText,
          driverAssigned: _driverAssigned,
          driverName: _driverName,
          onConfirm: () {},
        ),
      );
      if (!confirmed) return;
    }
    if (!mounted) return;
    await ref
        .read(collectConversionProvider(id).notifier)
        .convert(orderId: id, onSuccess: (_) => widget.onConverted?.call());
  }

  @override
  Widget build(BuildContext context) {
    final id = _orderId;
    if (id == null || id.isEmpty) return const SizedBox.shrink();
    // Nothing to convert: not a delivery order, or already handed over.
    if (!_isDelivery || _order.collectedInPerson) {
      return const SizedBox.shrink();
    }
    final state = ref.watch(collectConversionProvider(id));
    final result = state.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        CollectDriverRow(
          driverName: _driverAssigned ? _driverName : null,
          assignedAtLabel: _assignedLabel,
        ),
        const SizedBox(height: 12),
        if (result == null)
          CollectActionLane(
            onPressed: _convert,
            offline: !_online,
            busy: state.isConverting,
          )
        else
          _outcomeBanner(result),
        const SizedBox(height: 10),
        if (result == null)
          CollectOutcomeLine(
            driverAssigned: _online ? _driverAssigned : null,
            driverName: _driverName,
            feeText: _feeText,
          ),
        if (state.error != null) ...[
          const SizedBox(height: 10),
          Text(
            state.error!,
            textAlign: TextAlign.center,
            style: AppStyle.interNormal(size: 11.5, color: AppStyle.red),
          ),
        ],
        const SizedBox(height: 10),
        CollectTillLine(
          driverAssigned: _online && result == null ? _driverAssigned : null,
        ),
      ],
    );
  }

  /// Once it has happened the lane is spent: what is left is what it
  /// did, in the same two tints the outcome line used.
  Widget _outcomeBanner(CollectConversion result) {
    final bool queued = result.deferred;
    final Color accent = queued
        ? AppStyle.textDarkSecondary
        : (result.feeOutcome == CollectFeeOutcome.kept
              ? AppStyle.rate
              : AppStyle.green);
    final String text = queued
        ? AppHelpers.getTranslation(CollectKeys.conversionQueuedForSync)
        : AppHelpers.getTranslation(
            result.feeOutcome == CollectFeeOutcome.kept
                ? CollectKeys.feeKeptCoversTheDriversCallout
                : (result.feeOutcome == CollectFeeOutcome.refunded
                      ? CollectKeys.feeRefundedToWallet
                      : CollectKeys.collectedInPerson),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppStyle.interSemi(size: 12.5, color: accent),
      ),
    );
  }
}
