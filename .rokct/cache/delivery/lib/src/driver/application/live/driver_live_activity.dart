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

import 'package:base_sdk/base_sdk.dart'
    show
        LiveActivities,
        LiveActivityAction,
        LiveActivityKind,
        LiveActivitySnapshot,
        LiveActivityTracker;

import '../../infrastructure/models/data/order_detail.dart';
import '../home/home_state.dart';

/// Driver active delivery live activity (design section 3a, approved
/// 2026-09-26).
///
/// One entry under ONE key for the whole shift, so the driver never sees
/// two: it is the active delivery while there is one, "Online · waiting
/// for orders" (still ongoing, no bar) between deliveries, and gone when
/// the driver goes offline. It cannot be swiped away while online.
///
/// Three segments from [HomeState]'s stages: go to restaurant, collect, go
/// to customer. The home state has no "at the restaurant" flag, so the
/// collect segment is passed when the driver sets off to the customer.
/// The distance is left out: `OrderDetailData.distance` has no documented
/// unit, and a wrong "2.1 km" is worse than none.
/// "Delivered" only opens the app on the proof-of-delivery screen; it
/// never completes the order from the shade. "Due" is the delivery time
/// the customer chose, never a red timer.
class DriverLiveActivity {
  DriverLiveActivity(this.activities);

  final LiveActivities activities;

  static const String key = 'driver:active';
  static const List<String> segments = <String>[
    'To restaurant',
    'Collect',
    'To customer',
  ];

  static String _money(num v, String? symbol) =>
      '${symbol ?? ''}${symbol == null ? '' : ' '}${v.toStringAsFixed(2)}';

  static bool _isCash(OrderDetailData o) {
    final tag = o.transaction?.paymentSystem?.tag?.toLowerCase() ?? '';
    return tag == 'cash' || tag == 'cod' || tag.contains('cash');
  }

  /// "Due 12:52": the first HH:mm in the checkout delivery time.
  static String? _due(OrderDetailData o) =>
      RegExp(r'\d{1,2}:\d{2}').firstMatch(o.deliveryTime ?? '')?.group(0);

  static DateTime? _dueAt(OrderDetailData o) {
    final t = _due(o);
    final d = DateTime.tryParse(o.deliveryDate ?? '');
    if (t == null || d == null) return null;
    final p = t.split(':');
    return DateTime(d.year, d.month, d.day, int.parse(p[0]), int.parse(p[1]));
  }

  /// The snapshot for [state], or null when the driver is offline.
  static LiveActivitySnapshot? snapshotFor(
    HomeState state, {
    required bool online,
    String appName = 'Driver',
  }) {
    if (!online) return null;
    final order = state.orderDetail;
    final active =
        order != null && (state.isGoRestaurant || state.isGoUser);
    if (!active) {
      return LiveActivitySnapshot(
        key: key,
        kind: LiveActivityKind.driverDelivery,
        title: 'Online · waiting for orders',
        showProgress: false,
        dismissible: false,
        appName: appName,
      );
    }
    final toCustomer = state.isGoUser;
    final number = order.id == null ? '' : ' · order #${order.id}';
    final where = toCustomer
        ? (order.address?.address ?? '')
        : (order.shop?.translation?.title ?? '');
    final parts = <String>[
      if (where.isNotEmpty) where,
      if (_isCash(order) && order.totalPrice != null)
        'cash ${_money(order.totalPrice!, order.currency?.symbol)}',
    ];
    final orderLink = '/driver/order?orderId=${order.id ?? ''}';
    return LiveActivitySnapshot(
      key: key,
      kind: LiveActivityKind.driverDelivery,
      title: toCustomer ? 'Go to customer$number' : 'Go to restaurant$number',
      subtitle: parts.join(' · '),
      progress: toCustomer ? 2 / 3 : 0,
      segments: segments,
      trackerIcon: LiveActivityTracker.scooter,
      endsAt: _dueAt(order),
      endsAtLabel: 'Due',
      deepLink: orderLink,
      actions: [
        LiveActivityAction(
          id: 'navigate',
          label: 'Navigate',
          deepLink: orderLink,
        ),
        if (toCustomer)
          LiveActivityAction(
            id: 'delivered',
            label: 'Delivered',
            // Opens the proof-of-delivery step; never completes the order.
            deepLink: '$orderLink&step=proof',
          ),
      ],
      dismissible: false,
      appName: appName,
    );
  }

  /// Publish for [state]; ends the entry when the driver is offline.
  Future<void> publish(HomeState state, {required bool online}) async {
    final s = snapshotFor(state, online: online);
    if (s == null) {
      if (activities.isActive(key)) await activities.end(key);
      activities.reset(key);
      return;
    }
    if (!activities.isActive(key)) activities.reset(key);
    await activities.update(s);
  }
}
