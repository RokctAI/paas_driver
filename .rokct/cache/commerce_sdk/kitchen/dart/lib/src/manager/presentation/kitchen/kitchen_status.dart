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

/// The manager KITCHEN screen's status axes — the approved kitchen design
/// (Ray 2026-08-29: 12:36Z "yes" to the proposal; 13:06Z kitchen declares
/// ALL + "approved: … 34b,34c,34d"; 13:53Z "approved: 34a …"), behaviour
/// taken from the real paas_pos KitchenPage (kitchen_page.dart,
/// kitchen_notifier.dart, order_details_item.dart).
///
/// Two axes, exactly as in the POS:
///
///  * [KitchenStatus] — the ORDER's kitchen lifecycle (the filter chips
///    All / Accepted / Cooking / Ready / Cancelled). The wire strings are
///    the fleet's legacy lowercase statuses, identical to orders_sdk's
///    board.
///  * [DishStatus] — one DISH LINE's prep state. Wire values reuse the
///    order vocabulary (the POS drove lines through the same
///    getNextOrderStatus helper); the LABELS are the approved cook-facing
///    renames: accepted/cooking/ready render as Pending / Preparing /
///    Done (34d).
enum KitchenStatus {
  accepted,
  cooking,
  ready,
  canceled;

  /// Legacy wire strings (identical to the POS's and the orders board's).
  String get wire => switch (this) {
    KitchenStatus.accepted => 'accepted',
    KitchenStatus.cooking => 'cooking',
    KitchenStatus.ready => 'ready',
    KitchenStatus.canceled => 'canceled',
  };

  /// Status colour — base tokens where they exist (Cooking = rate,
  /// Ready = green, Cancelled = red); Accepted keeps the POS deepPurple
  /// #7C4DFF, the same no-base-token judgment call the orders board made.
  Color get color => switch (this) {
    KitchenStatus.accepted => const Color(0xFF7C4DFF),
    KitchenStatus.cooking => AppStyle.rate,
    KitchenStatus.ready => AppStyle.green,
    KitchenStatus.canceled => AppStyle.red,
  };

  /// Nothing moves out of ready/cancelled inside the kitchen (the
  /// hand-over routing is a separate explicit action).
  bool get isTerminal =>
      this == KitchenStatus.ready || this == KitchenStatus.canceled;

  /// From a raw wire/DB status string, tolerating the backend's
  /// capitalized Select values and both cancel spellings. Null for
  /// anything that is not a kitchen status (new, delivered, shipped…).
  static KitchenStatus? fromWire(String? wire) {
    switch (wire?.toLowerCase()) {
      case 'accepted':
        return KitchenStatus.accepted;
      case 'cooking':
        return KitchenStatus.cooking;
      case 'ready':
        return KitchenStatus.ready;
      case 'canceled':
      case 'cancelled':
        return KitchenStatus.canceled;
    }
    return null;
  }
}

/// One dish line's prep state (approved 34d: tap walks
/// Pending → Preparing → Done; double-tap cancels from any state).
enum DishStatus {
  pending,
  preparing,
  done,
  canceled;

  /// Wire values — the order-status vocabulary the POS reused per line
  /// (pending lines were 'new'/'accepted' shaped; the backend
  /// prep_status Select stores New/Cooking/Ready/Cancelled).
  String get wire => switch (this) {
    DishStatus.pending => 'new',
    DishStatus.preparing => 'cooking',
    DishStatus.done => 'ready',
    DishStatus.canceled => 'canceled',
  };

  /// The approved cook-facing label keys (34d): dish lines say
  /// Pending / Preparing / Done where order pills keep the POS words.
  String get labelKey => switch (this) {
    DishStatus.pending => 'pending',
    DishStatus.preparing => 'preparing',
    DishStatus.done => 'done',
    DishStatus.canceled => 'canceled',
  };

  /// Pill colour: a pending dish wears the Accepted purple, preparing the
  /// Cooking amber, done the Ready green, cancelled the red — the queue
  /// and the dish lines speak one colour language (34a/34d).
  Color get color => switch (this) {
    DishStatus.pending => KitchenStatus.accepted.color,
    DishStatus.preparing => KitchenStatus.cooking.color,
    DishStatus.done => KitchenStatus.ready.color,
    DishStatus.canceled => KitchenStatus.canceled.color,
  };

  static DishStatus? fromWire(String? wire) {
    switch (wire?.toLowerCase()) {
      case 'new':
      case 'accepted':
        return DishStatus.pending;
      case 'cooking':
        return DishStatus.preparing;
      case 'ready':
      case 'ended':
        return DishStatus.done;
      case 'canceled':
      case 'cancelled':
        return DishStatus.canceled;
    }
    return null;
  }
}

/// The filter chip row over the queue (All + the four kitchen statuses,
/// with counts — approved 34a/34b).
enum KitchenFilter {
  all,
  accepted,
  cooking,
  ready,
  canceled;

  /// The wire status this chip narrows to; null for All.
  KitchenStatus? get status => switch (this) {
    KitchenFilter.all => null,
    KitchenFilter.accepted => KitchenStatus.accepted,
    KitchenFilter.cooking => KitchenStatus.cooking,
    KitchenFilter.ready => KitchenStatus.ready,
    KitchenFilter.canceled => KitchenStatus.canceled,
  };

  String get labelKey => switch (this) {
    KitchenFilter.all => 'all',
    _ => status!.wire,
  };
}

/// The kitchen's pure rules — the POS KitchenNotifier's state machine
/// (kitchen_notifier.dart) as data-in/data-out functions, kept widget-free
/// so they are unit-testable (orders_sdk BoardRules precedent).
abstract final class KitchenRules {
  /// Delivery-type wire values (POS TrKeys.dine / delivery / pickup).
  static const String dineType = 'dine_in';
  static const String deliveryType = 'delivery';

  /// TAP advances a dish one step: Pending → Preparing → Done (POS
  /// order_details_item.dart:66-75 via getNextOrderStatus). Done and
  /// Cancelled lines don't advance.
  static DishStatus? tapAdvance(DishStatus status) => switch (status) {
    DishStatus.pending => DishStatus.preparing,
    DishStatus.preparing => DishStatus.done,
    DishStatus.done => null,
    DishStatus.canceled => null,
  };

  /// DOUBLE-TAP cancels the line from any live state (POS
  /// order_details_item.dart:77-81 — canceled/ended lines are inert).
  static bool canCancelDish(DishStatus status) =>
      status != DishStatus.canceled;

  /// ALL LINES CANCELLED → the order auto-cancels (POS
  /// kitchen_notifier.dart:76-83,164-171). Empty is not "all cancelled".
  static bool allDishesCanceled(List<DishStatus> dishes) =>
      dishes.isNotEmpty && dishes.every((d) => d == DishStatus.canceled);

  /// ALL LINES DONE (or cancelled, with at least one done) while the
  /// order is COOKING → the order auto-flips Ready (POS
  /// kitchen_notifier.dart:86-98).
  static bool shouldAutoReady({
    required KitchenStatus orderStatus,
    required List<DishStatus> dishes,
  }) {
    if (orderStatus != KitchenStatus.cooking) return false;
    if (allDishesCanceled(dishes)) return false;
    if (dishes.isEmpty) return false;
    return dishes.every(
      (d) => d == DishStatus.done || d == DishStatus.canceled,
    );
  }

  /// READY GUARD: "Mark order ready" stays off until at least one dish is
  /// done (POS kitchen_notifier.dart:353-364).
  static bool canMarkReady(List<DishStatus> dishes) =>
      dishes.any((d) => d == DishStatus.done);

  /// POST-READY ROUTING (POS kitchen_notifier.dart:100-116): handing a
  /// Ready order over routes it out of the kitchen — pickup and dine-in
  /// orders go straight to delivered, a delivery order goes on its way.
  /// The POS fired this automatically once every line reached its 'ended'
  /// serving state; this backend has no per-line serving state beyond
  /// Done, so the manager screen fires it from the Ready order's explicit
  /// hand-over action instead.
  static String postReadyRouteWire(String? orderDeliveryType) {
    final type = (orderDeliveryType ?? '').toLowerCase();
    if (type == deliveryType) return 'on_a_way';
    return 'delivered';
  }
}
