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

import 'package:base_sdk/base_sdk.dart' show LiveActivities, PushMessages;
import 'package:base_sdk/src/application/orders_list/orders_list_provider.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/orders.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orders_sdk/src/common/application/live/order_live_activity.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/orders_repository.dart';

/// Reads the customer's active orders: the non-terminal statuses plus
/// "new" (an order just placed at checkout).
typedef ActiveOrdersFetcher = Future<List<OrderActiveModel>> Function();

/// The app-wide poller behind the customer order live activity (design
/// section 2). Before this, only [OrderProgressPage] polled, so the entry
/// started only once that screen was opened and froze when it closed.
///
/// * It starts from [attach] (orders' customer DI hook, so at app start),
///   after checkout ([sync]), on every resume, when the home glance card
///   loads active orders ([activeOrderTrackerProvider] listens to
///   `ordersListProvider`), and on an `order_status` push.
/// * Each tracked order is polled on its own timer: every [onWayPoll]
///   while it is on its way (with the driver location), every [idlePoll]
///   otherwise.
/// * It never polls in the background: every timer is cancelled when the
///   app leaves the foreground and [sync] runs again on resume.
/// * An order stops being tracked once it is delivered, cancelled, paid
///   or failed (its final snapshot is published first), or when it turns
///   out to be a pickup order (no entry) that no screen has pinned.
/// * [OrderProgressPage] pins its order ([track] with `pin: true`) and
///   listens to [updates] instead of running its own poll.
class ActiveOrderTracker with WidgetsBindingObserver {
  ActiveOrderTracker({
    OrdersRepositoryFacade Function()? repository,
    ActiveOrdersFetcher? fetchActive,
    LiveActivities? activities,
    PushMessages? pushMessages,
    bool Function()? signedIn,
    this.appName = '',
  })  : _repository = repository ?? (() => getIt<OrdersRepositoryFacade>()),
        _fetchActiveOverride = fetchActive,
        _activities = activities ?? LiveActivities.instance,
        _push = pushMessages ?? PushMessages.instance,
        _signedIn = signedIn ?? (() => LocalStorage.getToken().isNotEmpty);

  /// The app-wide instance ([activeOrderTrackerProvider] hands it out).
  static final ActiveOrderTracker instance = ActiveOrderTracker();

  static const Duration idlePoll = Duration(seconds: 120);
  static const Duration onWayPoll = Duration(seconds: 15);

  /// The push `data['type']` the backend sends on a status change.
  static const String pushType = 'order_status';

  /// Statuses the tracker lists: [OrdersRepository.activeStatuses] plus
  /// "new", so an order placed a moment ago is picked up.
  static const String trackedStatuses =
      'new,${OrdersRepository.activeStatuses}';

  final OrdersRepositoryFacade Function() _repository;
  final ActiveOrdersFetcher? _fetchActiveOverride;
  final LiveActivities _activities;
  final PushMessages _push;
  final bool Function() _signedIn;
  final String appName;

  final Map<String, _Tracked> _orders = <String, _Tracked>{};
  final Set<String> _pinned = <String>{};
  final StreamController<OrderActiveModel> _updates =
      StreamController<OrderActiveModel>.broadcast();

  bool _attached = false;
  bool _foreground = true;

  /// Every order the tracker polled, after each poll.
  Stream<OrderActiveModel> get updates => _updates.stream;

  bool get foreground => _foreground;

  Set<String> get trackedIds => Set<String>.unmodifiable(_orders.keys);

  bool isTracking(String orderId) => _orders.containsKey(orderId);

  /// The last polled order, or null.
  OrderActiveModel? orderFor(String orderId) => _orders[orderId]?.last;

  /// The poll interval currently armed for [orderId], or null (not
  /// tracked, or in the background).
  @visibleForTesting
  Duration? intervalFor(String orderId) {
    final t = _orders[orderId];
    return t?.timer == null ? null : t!.every;
  }

  /// Observe the app lifecycle, take `order_status` pushes, and [sync].
  /// Idempotent.
  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    _push.register(pushType, onPush);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    unawaited(sync());
  }

  /// Stop everything (tests, sign-out).
  void detach() {
    if (_attached) {
      WidgetsBinding.instance.removeObserver(this);
      _push.unregister(pushType);
    }
    _attached = false;
    for (final t in _orders.values) {
      t.timer?.cancel();
    }
    _orders.clear();
    _pinned.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setForeground(state == AppLifecycleState.resumed);
  }

  /// Foreground: poll. Background: cancel every timer, no polling.
  @visibleForTesting
  void setForeground(bool foreground) {
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (!foreground) {
      for (final t in _orders.values) {
        t.timer?.cancel();
        t.timer = null;
      }
    } else {
      unawaited(sync());
    }
  }

  Future<List<OrderActiveModel>> _fetchActive() async {
    final override = _fetchActiveOverride;
    if (override != null) return override();
    final repo = _repository();
    final res = repo is OrdersRepository
        ? await repo.getOrders(page: 1, status: trackedStatuses)
        : await repo.getActiveOrders(1);
    return res.when(
      success: (data) => data.data ?? <OrderActiveModel>[],
      failure: (_, __) => <OrderActiveModel>[],
    );
  }

  /// List the active orders and track each one, and poll every tracked
  /// order now. Call after checkout, on home load and on resume. Does
  /// nothing in the background or when signed out.
  Future<void> sync() async {
    if (!_foreground || !_signedIn()) return;
    List<OrderActiveModel> active;
    try {
      active = await _fetchActive();
    } catch (e) {
      debugPrint('==> active order tracker: list: $e');
      active = <OrderActiveModel>[];
    }
    trackAll(active, pollNow: false);
    await Future.wait(_orders.keys.toList().map(refresh));
  }

  /// Track every non-terminal order in [orders] (the glance card's
  /// active list).
  void trackAll(Iterable<OrderActiveModel> orders, {bool pollNow = true}) {
    for (final o in orders) {
      final id = o.id;
      if (id == null || id.isEmpty || _isTerminal(o.status)) continue;
      track(id, pollNow: pollNow);
    }
  }

  /// Start tracking [orderId]. [pin] keeps a pickup order polled for the
  /// screen that asked (no entry is shown for it).
  void track(String orderId, {bool pin = false, bool pollNow = true}) {
    if (orderId.isEmpty) return;
    if (pin) _pinned.add(orderId);
    final known = _orders.containsKey(orderId);
    _orders.putIfAbsent(
        orderId, () => _Tracked(OrderLiveActivity(_activities)));
    if (!known && pollNow) unawaited(refresh(orderId));
  }

  /// A screen no longer needs [orderId] kept; a pickup order stops.
  void release(String orderId) {
    _pinned.remove(orderId);
    final last = _orders[orderId]?.last;
    if (last != null && _isPickup(last)) _stop(orderId);
  }

  /// An `order_status` push: start or refresh that order's entry.
  Future<void> onPush(Map<String, dynamic> data) async {
    final id = data['order_id']?.toString() ?? '';
    if (id.isEmpty) return;
    track(id, pollNow: false);
    await refresh(id);
  }

  /// Poll [orderId] now and re-arm its timer. Foreground only.
  Future<void> refresh(String orderId) async {
    final t = _orders[orderId];
    if (t == null || !_foreground) return;
    if (!_signedIn()) {
      // Signed out: nothing of this user's is polled any more.
      _stop(orderId);
      return;
    }
    if (t.inFlight) return;
    t.inFlight = true;
    try {
      await _poll(orderId, t);
    } finally {
      t.inFlight = false;
    }
  }

  Future<void> _poll(String orderId, _Tracked t) async {
    final repo = _repository();
    OrderActiveModel? order;
    try {
      final res = await repo.getSingleOrder(orderId);
      order = res.when(success: (o) => o, failure: (_, __) => null);
    } catch (e) {
      debugPrint('==> active order tracker: order $orderId: $e');
    }
    if (!identical(_orders[orderId], t)) return; // stopped meanwhile
    if (order == null) {
      _arm(orderId, t);
      return;
    }
    final normalized = order.copyWith(status: wireStatus(order.status));
    t.last = normalized;
    final onWay = AppHelpers.getOrderStatus(normalized.status) ==
        OrderStatus.onWay;
    final pickup = _isPickup(normalized);
    if (!pickup) {
      double? lat;
      double? lng;
      final driverId = normalized.deliveryMan?.id;
      if (onWay && driverId != null && driverId.isNotEmpty) {
        try {
          final loc = await repo.getDriverLocation(driverId);
          loc.when(
            success: (l) {
              lat = l.latitude;
              lng = l.longitude;
            },
            failure: (_, __) {},
          );
        } catch (e) {
          debugPrint('==> active order tracker: driver location: $e');
        }
      }
      try {
        await t.live.publish(normalized,
            driverLatitude: lat, driverLongitude: lng, appName: appName);
      } catch (e) {
        debugPrint('==> active order tracker: publish: $e');
      }
    }
    if (!_updates.isClosed) _updates.add(normalized);
    if (_isTerminal(order.status) ||
        (pickup && !_pinned.contains(orderId))) {
      _stop(orderId);
      return;
    }
    t.every = onWay ? onWayPoll : idlePoll;
    _arm(orderId, t);
  }

  void _arm(String orderId, _Tracked t) {
    t.timer?.cancel();
    t.timer = null;
    if (!_foreground) return;
    t.timer = Timer(t.every, () {
      t.timer = null;
      unawaited(refresh(orderId));
    });
  }

  void _stop(String orderId) {
    _orders.remove(orderId)?.timer?.cancel();
    _pinned.remove(orderId);
  }

  static bool _isPickup(OrderActiveModel o) =>
      (o.deliveryType ?? '').trim().toLowerCase() == 'pickup';

  static const Set<String> _terminal = <String>{
    'delivered',
    'canceled',
    'cancelled',
    'paid',
    'failed',
  };

  static bool _isTerminal(String? status) =>
      _terminal.contains((status ?? '').trim().toLowerCase());

  /// The dart wire status for a backend status: the doctype's own
  /// options ("Shipped", "Cancelled", "Cooking") and the wire strings
  /// both map to what [OrderLiveActivity] reads. "Paid" (settled after
  /// delivery) reads as delivered, "Failed" as cancelled.
  static String wireStatus(String? status) {
    final s = (status ?? '').trim().toLowerCase();
    if (s == 'paid') return 'delivered';
    if (s == 'failed') return 'canceled';
    return AppHelpers.getOrderStatusText(AppHelpers.getOrderStatus(s));
  }
}

class _Tracked {
  _Tracked(this.live);

  final OrderLiveActivity live;
  Duration every = ActiveOrderTracker.idlePoll;
  Timer? timer;
  OrderActiveModel? last;
  bool inFlight = false;
}

/// The app-wide [ActiveOrderTracker], attached on first read. It also
/// tracks whatever the home glance card's active-orders fetch returns.
final activeOrderTrackerProvider = Provider<ActiveOrderTracker>((ref) {
  final tracker = ActiveOrderTracker.instance..attach();
  ref.listen(
    ordersListProvider,
    (_, next) => tracker.trackAll(next.activeOrders),
    fireImmediately: true,
  );
  return tracker;
});
