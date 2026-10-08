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

import 'dart:math' as math;

import 'package:base_sdk/base_sdk.dart'
    show
        LiveActivities,
        LiveActivityAction,
        LiveActivityKind,
        LiveActivitySnapshot,
        LiveActivityState,
        LiveActivityTracker;
import 'package:base_sdk/src/models/data/order_active_model.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';

/// Customer order tracking live activity (design section 2, approved
/// 2026-09-26). Maps the order the progress screen already polls, plus the
/// driver location, onto base_sdk's [LiveActivities].
///
/// Five segments: Placed, Preparing, Picked up, On the way, Arriving. The
/// backend has no "picked up" status, so an order that is on its way but
/// whose driver location is not known yet reads "Picked up". The car moves
/// with `1 - distance left / distance when first seen on the way`, and
/// stays put while the location is unknown. There is no ETA field yet, so
/// the end time is the delivery time chosen at checkout, marked "about".
class OrderLiveActivity {
  OrderLiveActivity(this.activities);

  final LiveActivities activities;

  /// Within this distance the entry reads "Arriving now".
  static const double arrivingMeters = 200;

  static const List<String> segments = <String>[
    'Placed',
    'Preparing',
    'Picked up',
    'On the way',
    'Arriving',
  ];

  double? _distanceAtPickup;
  double? _lastProgress;

  static String keyFor(String orderId) => 'order:$orderId';

  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Straight-line metres between two points (haversine).
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLon = rad(lon2 - lon1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.min(1, math.sqrt(a)));
  }

  /// The checkout delivery time as a clock time: `deliveryDate` plus the
  /// first `HH:mm` in `deliveryTime` ("12:30" or "12:30 - 13:00").
  static DateTime? chosenDeliveryTime(OrderActiveModel order) {
    final date = order.deliveryDate;
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(order.deliveryTime ?? '');
    if (date == null || m == null) return null;
    return DateTime(date.year, date.month, date.day, int.parse(m.group(1)!),
        int.parse(m.group(2)!));
  }

  static String _km(double meters) =>
      '${(meters / 1000).toStringAsFixed(1)} km away';

  /// Build the snapshot for [order]. [driverLatitude]/[driverLongitude]
  /// are the last known driver position, or null.
  LiveActivitySnapshot? snapshotFor(
    OrderActiveModel order, {
    double? driverLatitude,
    double? driverLongitude,
    required String appName,
  }) {
    final id = order.id;
    if (id == null || id.isEmpty) return null;
    // The customer checkout writes "Pickup", the till 'pickup'.
    if ((order.deliveryType ?? '').trim().toLowerCase() == 'pickup') {
      return null;
    }
    final status = AppHelpers.getOrderStatus(order.status);
    final shop = order.shop?.translation?.title ?? '';
    final driver = order.deliveryMan?.firstname ?? '';
    final chosen = chosenDeliveryTime(order);
    final callDriver = (order.deliveryMan?.phone ?? '').isNotEmpty;
    final track = LiveActivityAction(
      id: 'track_order',
      label: 'Track order',
      deepLink: '/order_progress?orderId=$id',
    );
    final call = LiveActivityAction(
      id: 'call_driver',
      label: 'Call driver',
      deepLink: 'tel:${order.deliveryMan?.phone ?? ''}',
    );

    LiveActivitySnapshot snap({
      required String title,
      required String subtitle,
      required double progress,
      LiveActivityState state = LiveActivityState.live,
      bool withCall = false,
      DateTime? endsAt,
      bool approximate = true,
      List<LiveActivityAction>? actions,
    }) =>
        LiveActivitySnapshot(
          key: keyFor(id),
          kind: LiveActivityKind.orderTracking,
          title: title,
          subtitle: subtitle,
          progress: progress,
          segments: segments,
          trackerIcon: LiveActivityTracker.car,
          endsAt: endsAt ?? chosen,
          endsAtLabel: 'Arrives',
          endsAtApproximate: approximate,
          deepLink: '/order_progress?orderId=$id',
          actions: actions ?? [track, if (withCall && callDriver) call],
          state: state,
          appName: appName,
        );

    switch (status) {
      case OrderStatus.open:
        return snap(
          title: 'Order placed',
          subtitle: shop.isEmpty ? 'Waiting to be accepted' : 'Waiting for $shop to accept',
          progress: 0.04,
        );
      case OrderStatus.accepted:
        return snap(title: 'Preparing your order', subtitle: shop, progress: 0.3);
      case OrderStatus.ready:
        return snap(
          title: 'Preparing your order',
          subtitle: shop.isEmpty ? 'Ready for pickup' : '$shop · ready for pickup',
          progress: 0.38,
        );
      case OrderStatus.onWay:
        final to = order.location;
        double? left;
        if (driverLatitude != null &&
            driverLongitude != null &&
            to?.latitude != null &&
            to?.longitude != null) {
          left = distanceMeters(
              driverLatitude, driverLongitude, to!.latitude!, to.longitude!);
          _distanceAtPickup ??= left;
        }
        if (left == null) {
          // Location unknown: the car does not guess.
          return snap(
            title: _lastProgress == null ? 'Picked up' : 'On the way',
            subtitle: driver,
            progress: _lastProgress ?? 0.5,
            withCall: true,
          );
        }
        if (left <= arrivingMeters) {
          _lastProgress = 0.95;
          return snap(
            title: 'Arriving now',
            subtitle: driver.isEmpty ? 'Meet your driver' : 'Meet $driver',
            progress: 0.95,
            state: LiveActivityState.ending,
            withCall: true,
          );
        }
        final start = _distanceAtPickup!;
        final done = start <= 0 ? 0.0 : (1 - left / start).clamp(0.0, 1.0);
        // Stage 4 of 5 spans 0.6 to 0.8 of the bar.
        final p = double.parse((0.6 + 0.2 * done).toStringAsFixed(3));
        _lastProgress = p;
        return snap(
          title: 'On the way',
          subtitle: driver.isEmpty ? _km(left) : '$driver · ${_km(left)}',
          progress: p,
          withCall: true,
        );
      case OrderStatus.delivered:
        final at = order.updatedAt?.toLocal();
        return snap(
          title: at == null ? 'Delivered' : 'Delivered ${_clock(at)}',
          subtitle: 'Rate your order',
          progress: 1,
          state: LiveActivityState.ended,
          actions: [
            LiveActivityAction(
              id: 'rate_order',
              label: 'Rate order',
              deepLink: '/order_progress?orderId=$id',
            ),
          ],
        );
      case OrderStatus.canceled:
        return snap(
          title: 'Order cancelled',
          subtitle: shop.isEmpty ? 'Tap for help' : '$shop cancelled the order',
          progress: _lastProgress ?? 0.3,
          state: LiveActivityState.error,
          actions: [
            LiveActivityAction(
              id: 'get_help',
              label: 'Get help',
              deepLink: '/order_progress?orderId=$id',
            ),
          ],
        );
    }
  }

  /// Build and publish. Safe to call on every poll.
  Future<void> publish(
    OrderActiveModel order, {
    double? driverLatitude,
    double? driverLongitude,
    String appName = '',
  }) async {
    final s = snapshotFor(
      order,
      driverLatitude: driverLatitude,
      driverLongitude: driverLongitude,
      appName: appName,
    );
    if (s != null) await activities.update(s);
  }
}
