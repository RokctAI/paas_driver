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

/// What happened to the delivery fee when a delivery order was collected
/// in person (design strip section 43). The seller has to be told which
/// of the two it will be BEFORE the tap, and which of the two it was
/// after — the board card renders the difference at a glance.
enum CollectFeeOutcome {
  /// No driver had been dispatched: the fee went back to the customer's
  /// wallet and the order's total dropped by it.
  refunded,

  /// A driver had already been dispatched: the fee is kept and paid to
  /// him as a callout, the total is unchanged.
  kept,

  /// The order carried no delivery fee at all, so nothing moved either
  /// way and the surface promises nothing about money.
  none;

  static CollectFeeOutcome fromWire(String? wire) {
    switch (wire) {
      case 'refunded':
        return CollectFeeOutcome.refunded;
      case 'kept':
        return CollectFeeOutcome.kept;
      default:
        return CollectFeeOutcome.none;
    }
  }
}

/// The `convert_delivery_to_collected` envelope: what the one atomic
/// seller endpoint did. Deliberately flat — the till shows it and moves
/// on; the authoritative order row comes back through the ordinary
/// queue refetch.
class CollectConversion {
  final bool converted;
  final bool alreadyConverted;
  final bool driverWasAssigned;
  final String? unassignedDeliveryman;
  final String? deliveryType;
  final num deliveryFee;
  final CollectFeeOutcome feeOutcome;
  final num refundedToWallet;
  final num totalPrice;
  final num totalPriceBefore;

  /// True when the till took the hand-over offline and the conversion
  /// itself is queued for the next sync (frame 43e). Never set by the
  /// backend — the repository sets it when it queues the op.
  final bool deferred;

  const CollectConversion({
    this.converted = false,
    this.alreadyConverted = false,
    this.driverWasAssigned = false,
    this.unassignedDeliveryman,
    this.deliveryType,
    this.deliveryFee = 0,
    this.feeOutcome = CollectFeeOutcome.none,
    this.refundedToWallet = 0,
    this.totalPrice = 0,
    this.totalPriceBefore = 0,
    this.deferred = false,
  });

  /// Queued offline: the goods are already with the customer, but the
  /// branch (fee back vs fee kept) is server state the till cannot know,
  /// so nothing is claimed about the money.
  const CollectConversion.deferred()
      : converted = false,
        alreadyConverted = false,
        driverWasAssigned = false,
        unassignedDeliveryman = null,
        deliveryType = null,
        deliveryFee = 0,
        feeOutcome = CollectFeeOutcome.none,
        refundedToWallet = 0,
        totalPrice = 0,
        totalPriceBefore = 0,
        deferred = true;

  factory CollectConversion.fromJson(Map<String, dynamic> json) {
    final data = json['message'] is Map
        ? (json['message'] as Map).cast<String, dynamic>()
        : json;
    return CollectConversion(
      converted: data['converted'] == true,
      alreadyConverted: data['already_converted'] == true,
      driverWasAssigned: data['driver_was_assigned'] == true,
      unassignedDeliveryman: data['unassigned_deliveryman']?.toString(),
      deliveryType: data['delivery_type']?.toString(),
      deliveryFee: (data['delivery_fee'] as num?) ?? 0,
      feeOutcome: CollectFeeOutcome.fromWire(
        data['fee_outcome']?.toString(),
      ),
      refundedToWallet: (data['refunded_to_wallet'] as num?) ?? 0,
      totalPrice: (data['total_price'] as num?) ?? 0,
      totalPriceBefore: (data['total_price_before'] as num?) ?? 0,
    );
  }
}
