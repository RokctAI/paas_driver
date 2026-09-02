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

import 'dart:ui';

import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/enums.dart';

/// The manager order board's SEVEN-status state machine — the approved
/// "31b adopt 31a" design (Ray, 2026-08-29 12:10Z; renders approved 13:06Z
/// "33a is approved" and 13:53Z "approved: 34a , 33d,33b").
///
/// paas_pos's board (`board_view.dart` buildList) runs
/// new → accepted → cooking → ready → on_a_way → delivered (+ canceled);
/// base_sdk's [OrderStatus] has no `cooking` member (that enum is shared
/// fleet-wide), so the board carries its own status axis and maps down to
/// [OrderStatus] where one exists. `cooking` talks to the wire by its raw
/// status string instead.
enum BoardStatus {
  newOrder,
  accepted,
  cooking,
  ready,
  onWay,
  delivered,
  canceled;

  /// The legacy wire strings — identical to the POS's and to
  /// `SellerOrdersRepository._statusText`.
  String get wire => switch (this) {
    BoardStatus.newOrder => 'new',
    BoardStatus.accepted => 'accepted',
    BoardStatus.cooking => 'cooking',
    BoardStatus.ready => 'ready',
    BoardStatus.onWay => 'on_a_way',
    BoardStatus.delivered => 'delivered',
    BoardStatus.canceled => 'canceled',
  };

  /// The base_sdk [OrderStatus] this column corresponds to; null for
  /// [cooking], which base_sdk's shared enum does not model.
  OrderStatus? get orderStatus => switch (this) {
    BoardStatus.newOrder => OrderStatus.open,
    BoardStatus.accepted => OrderStatus.accepted,
    BoardStatus.cooking => null,
    BoardStatus.ready => OrderStatus.ready,
    BoardStatus.onWay => OrderStatus.onWay,
    BoardStatus.delivered => OrderStatus.delivered,
    BoardStatus.canceled => OrderStatus.canceled,
  };

  /// Per-status progress of the order-type chip (POS
  /// `drag_item.dart getProgressPercentage`): 0% new, 20% accepted,
  /// 40% cooking, 60% ready, 80% on the way, 100% done.
  double get progress => switch (this) {
    BoardStatus.newOrder => 0.0,
    BoardStatus.accepted => 0.2,
    BoardStatus.cooking => 0.4,
    BoardStatus.ready => 0.6,
    BoardStatus.onWay => 0.8,
    BoardStatus.delivered => 1.0,
    BoardStatus.canceled => 1.0,
  };

  /// Column colour. Base tokens where they exist (New = AppStyle.blue,
  /// Cooking = rate, Ready = green, Delivered = primary, Cancelled = red —
  /// as in the POS); the two approved substitutions are Accepted #7C4DFF
  /// (POS deepPurple, no base token) and On the way #26C6DA (the POS used
  /// black there, which is invisible on the dark base theme).
  Color get color => switch (this) {
    BoardStatus.newOrder => AppStyle.blue,
    BoardStatus.accepted => const Color(0xFF7C4DFF),
    BoardStatus.cooking => AppStyle.rate,
    BoardStatus.ready => AppStyle.green,
    BoardStatus.onWay => const Color(0xFF26C6DA),
    BoardStatus.delivered => AppStyle.primary,
    BoardStatus.canceled => AppStyle.red,
  };

  /// Cooking and On-the-way pills sit on light colours — their count text
  /// flips dark, as in the approved frames.
  bool get darkPillText =>
      this == BoardStatus.cooking || this == BoardStatus.onWay;

  /// History columns (no further transitions out except cancel-from-any
  /// which the flow rule already blocks past canceled).
  bool get isHistory =>
      this == BoardStatus.delivered || this == BoardStatus.canceled;

  /// From an order's raw wire status string; unknown strings read as new.
  static BoardStatus fromWire(String? wire) => BoardStatus.values.firstWhere(
    (s) => s.wire == wire,
    orElse: () => BoardStatus.newOrder,
  );
}

/// Board-level rules that are pure data-in/data-out (kept widget-free so
/// they are unit-testable).
abstract final class BoardRules {
  /// The waiter role string — POS `TrKeys.waiter` verbatim.
  static const String waiterRole = 'waiter';

  /// Delivery-type wire values (POS `TrKeys.dine` / `TrKeys.delivery`).
  static const String dineType = 'dine_in';
  static const String deliveryType = 'delivery';

  /// The columns a user sees, in flow order. A waiter login hides the
  /// On-the-way column (POS `board_view.dart` role checks, carried over
  /// unchanged).
  static List<BoardStatus> columnsFor({String? role}) => [
    BoardStatus.newOrder,
    BoardStatus.accepted,
    BoardStatus.cooking,
    BoardStatus.ready,
    if (role != waiterRole) BoardStatus.onWay,
    BoardStatus.delivered,
    BoardStatus.canceled,
  ];

  /// Drops are legal only from an earlier column to a later one (POS's
  /// `newListIndex > oldListIndex` rule) — which also permits cancelling
  /// from any active column.
  static bool canMove({required BoardStatus from, required BoardStatus to}) =>
      to.index > from.index;

  /// THE SMART SKIP (POS `board_view.dart` lines 266–273): an order whose
  /// delivery type is neither dine-in nor delivery (i.e. a pickup) never
  /// travels with a driver, so a drag onto On the way lands in Delivered
  /// instead. Every other drop keeps its target.
  static BoardStatus resolveDrop({
    required BoardStatus target,
    required String? deliveryType,
  }) {
    if (target == BoardStatus.onWay &&
        (deliveryType ?? '') != dineType &&
        (deliveryType ?? '') != BoardRules.deliveryType) {
      return BoardStatus.delivered;
    }
    return target;
  }
}
