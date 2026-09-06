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

// FRAME 53e of design strip section 53 (approved, Ray 2026-09-01) - the
// driver window on the launcher canvas: one window, no money.
//
// What this widget IS: the content of the launcher's driver window. The
// launcher owns the placement and the chrome (design frame 53g); this
// file owns only what sits inside. It reaches the launcher through the
// manifest (integrations under launch_sdk's `// @launcher-windows`
// marker), never through an import: delivery_sdk's lib/ imports only
// base_sdk (ADR-005).
//
// The four things a later edit could quietly undo:
//
//   * NO MONEY. Ray, 2026-09-01: "on duty showing is fine but not
//     exposing earnings and balance to everyone that opens that phone".
//     The launcher is the device home screen and has no auth in front of
//     it. The job's fee and the cash it carries are NOT drawn - not
//     masked, not blurred, absent - and the amount lives inside the app.
//     [DriverLaunchJob] has no fee field on purpose.
//   * NO PERSON. The frame shows a shop and a suburb and no customer:
//     a name, a street address or a phone number carries the same
//     exposure as a balance and Ray has not ruled on them (53e, chip
//     1290). The drop is the suburb only.
//   * ONE WINDOW, "as minimal as possible": the next job or the no-job
//     state, and one action. Nothing else grows here.
//   * A DATALESS STATE THAT STILL WORKS. Ray: "data dont show on
//     launcher when another mode is active". [DriverLaunchWindow.dataless]
//     renders the action and nothing about any job, so the window is
//     "useful and tappable without data" (53g) by construction.

import 'dart:math' as math;

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/domain/interface/orders.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_orders_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Translation wire keys owned by this window. Referenced by string, not
/// through composer-injected `TrKeys` constants, because lib/ analyzes and
/// tests against raw base_sdk where those constants do not exist
/// (orders_sdk's `seller_form_helpers` precedent); `AppHelpers.getTranslation`
/// humanizes them until the translation store carries rows. Declared in
/// manifest.json `tr_keys` so the composed app seeds them.
abstract final class DriverLaunchWindowKeys {
  static const String orderWaiting = 'order.waiting';
  static const String jobInHand = 'job.in.hand';
  static const String noJobRightNow = 'no.job.right.now';
  static const String pickUp = 'pick.up';
  static const String drop = 'drop';
}

/// The one job the window shows, flattened out of `OrderDetailData` so the
/// widget stays free of the SDK's models and testable on plain values.
///
/// No fee, no total, no cash amount, no customer: see the file header.
class DriverLaunchJob {
  const DriverLaunchJob({
    required this.id,
    required this.shopName,
    this.dropSuburb,
    this.pickupKm,
    this.dropKm,
    this.inHand = false,
  });

  final String id;

  /// The pick-up: the shop's own name.
  final String shopName;

  /// The drop: a suburb, never a person or a street. Built through
  /// [suburbOf], which keeps only the last segment of the order's address.
  final String? dropSuburb;

  /// Driver's last known position to the shop. Null when unknown - the
  /// line then omits the distance rather than showing a guess.
  final double? pickupKm;

  /// Shop to drop. Null when either point is unknown.
  final double? dropKm;

  /// True when this is the job the driver is already working (the app's
  /// current order); false when it is waiting to be claimed.
  final bool inHand;

  /// `OrderDetailData` -> job. [driverLatitude]/[driverLongitude] are the
  /// courier's last known position, when the app has one.
  static DriverLaunchJob fromOrder(
    OrderDetailData order, {
    required bool inHand,
    double? driverLatitude,
    double? driverLongitude,
  }) {
    final double? shopLat = _parse(order.shop?.location?.latitude);
    final double? shopLng = _parse(order.shop?.location?.longitude);
    final double? dropLat = _parse(order.location?.latitude);
    final double? dropLng = _parse(order.location?.longitude);
    return DriverLaunchJob(
      id: '${order.id ?? ''}',
      shopName: order.shop?.translation?.title ?? '',
      dropSuburb: suburbOf(order.address?.address),
      pickupKm: _km(driverLatitude, driverLongitude, shopLat, shopLng),
      dropKm: _km(shopLat, shopLng, dropLat, dropLng),
      inHand: inHand,
    );
  }

  /// The suburb out of a full address line - its last comma-separated
  /// segment ("12 Cradock Avenue, Rosebank" -> "Rosebank"). A street
  /// address on the home screen carries the exposure chip 1290 names,
  /// so the number and the street never reach the canvas. Null when the
  /// address is empty.
  static String? suburbOf(String? address) {
    if (address == null) return null;
    final List<String> parts = address
        .split(',')
        .map((String part) => part.trim())
        .where((String part) => part.isNotEmpty)
        .toList();
    return parts.isEmpty ? null : parts.last;
  }

  static double? _parse(String? raw) =>
      raw == null ? null : double.tryParse(raw);

  /// Great-circle distance in km, or null when a point is missing.
  static double? _km(double? lat1, double? lng1, double? lat2, double? lng2) {
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return null;
    }
    const double r = 6371.0;
    double rad(double deg) => deg * math.pi / 180;
    final double dLat = rad(lat2 - lat1);
    final double dLng = rad(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

/// Reads the next job through the same facade the driver home reads - the
/// `CourierOrdersRepositoryFacade` the driver DI hook registers, which in
/// demo builds is the seeded `DemoCourierOrdersRepository`. A composition
/// that never registered the facade (the launcher composes no driver DI)
/// gets the demo repository when the build is a demo build and nothing
/// otherwise; a failing call is a null job, never an exception - the
/// launcher canvas must not crash because a backend is away.
abstract final class DriverLaunchWindowLoader {
  static Future<DriverLaunchJob?> load({
    CourierOrdersRepositoryFacade? repository,
  }) async {
    final CourierOrdersRepositoryFacade? repo = repository ?? _resolve();
    if (repo == null) return null;
    try {
      double? lat;
      double? lng;
      try {
        lat = LocalStorage.getAddressSelected()?.latitude;
        lng = LocalStorage.getAddressSelected()?.longitude;
      } catch (_) {
        // No storage yet: distances simply stay unknown.
      }
      final OrderDetailData? inHand = switch (await repo.fetchCurrentOrder()) {
        Success(:final data) =>
          (data.data ?? const <OrderDetailData>[]).firstOrNull,
        Failure() => null,
      };
      if (inHand != null) {
        return DriverLaunchJob.fromOrder(
          inHand,
          inHand: true,
          driverLatitude: lat,
          driverLongitude: lng,
        );
      }
      final OrderDetailData? waiting =
          switch (await repo.getAvailableOrders(1)) {
        Success(:final data) => data.firstOrNull,
        Failure() => null,
      };
      return waiting == null
          ? null
          : DriverLaunchJob.fromOrder(
              waiting,
              inHand: false,
              driverLatitude: lat,
              driverLongitude: lng,
            );
    } catch (_) {
      return null;
    }
  }

  static CourierOrdersRepositoryFacade? _resolve() {
    final GetIt getIt = GetIt.instance;
    if (getIt.isRegistered<CourierOrdersRepositoryFacade>()) {
      return getIt.get<CourierOrdersRepositoryFacade>();
    }
    return AppConstants.isDemo ? DemoCourierOrdersRepository() : null;
  }
}

/// The driver window's content (frame 53e).
///
/// With data: the next job - "Order waiting" with its pick-up and drop and
/// an Accept that opens the app, or "Job in hand" with an Open, or "No job
/// right now" with an Open. Dataless ([DriverLaunchWindow.dataless]): the
/// Open affordance alone.
///
/// Dark first, through AppStyle's tokens (the same card/ink/stroke roles
/// the driver home uses), so the window follows the launcher's theme.
class DriverLaunchWindow extends StatefulWidget {
  /// The window with data. [job] short-circuits the loader (tests, a host
  /// that already holds the job); otherwise [load] runs once on mount and
  /// defaults to [DriverLaunchWindowLoader.load].
  const DriverLaunchWindow({
    super.key,
    required this.onOpen,
    this.job,
    this.load,
  }) : showData = true;

  /// The window without data, for a mode that is not the active one.
  const DriverLaunchWindow.dataless({super.key, required this.onOpen})
      : showData = false,
        job = null,
        load = null;

  /// Opens the driver app - the launcher's own way of starting it.
  final VoidCallback onOpen;

  final bool showData;
  final DriverLaunchJob? job;
  final Future<DriverLaunchJob?> Function()? load;

  static const Key acceptKey = ValueKey<String>('driver-launch-window-accept');
  static const Key openKey = ValueKey<String>('driver-launch-window-open');

  @override
  State<DriverLaunchWindow> createState() => _DriverLaunchWindowState();
}

class _DriverLaunchWindowState extends State<DriverLaunchWindow> {
  DriverLaunchJob? _job;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.showData) return;
    if (widget.job != null) {
      _job = widget.job;
      _loaded = true;
      return;
    }
    (widget.load ?? DriverLaunchWindowLoader.load)().then((job) {
      if (!mounted) return;
      setState(() {
        _job = job;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showData) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _Pill(
          key: DriverLaunchWindow.openKey,
          label: AppHelpers.getTranslation(TrKeys.open),
          onTap: widget.onOpen,
        ),
      );
    }
    if (!_loaded) return const SizedBox.shrink();
    final DriverLaunchJob? job = _job;
    if (job == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Headline(AppHelpers.getTranslation(
            DriverLaunchWindowKeys.noJobRightNow,
          )),
          const SizedBox(height: 10),
          _Pill(
            key: DriverLaunchWindow.openKey,
            label: AppHelpers.getTranslation(TrKeys.open),
            onTap: widget.onOpen,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Headline(AppHelpers.getTranslation(
          job.inHand
              ? DriverLaunchWindowKeys.jobInHand
              : DriverLaunchWindowKeys.orderWaiting,
        )),
        const SizedBox(height: 8),
        _Leg(
          label: AppHelpers.getTranslation(DriverLaunchWindowKeys.pickUp),
          value: job.shopName,
          km: job.pickupKm,
        ),
        if (job.dropSuburb != null && job.dropSuburb!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          _Leg(
            label: AppHelpers.getTranslation(DriverLaunchWindowKeys.drop),
            value: job.dropSuburb!,
            km: job.dropKm,
          ),
        ],
        const SizedBox(height: 10),
        // The action. Accepting is done inside the app, where the fee is:
        // the canvas has no auth in front of it, so the tap opens the app
        // on this job rather than claiming it from the home screen.
        _Pill(
          key: job.inHand
              ? DriverLaunchWindow.openKey
              : DriverLaunchWindow.acceptKey,
          label: AppHelpers.getTranslation(
            job.inHand ? TrKeys.open : TrKeys.accept,
          ),
          onTap: widget.onOpen,
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppStyle.interSemi(size: 14, color: AppStyle.textPrimary),
    );
  }
}

/// One leg of the job: a label, a place, and the distance when known.
class _Leg extends StatelessWidget {
  const _Leg({required this.label, required this.value, this.km});

  final String label;
  final String value;
  final double? km;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 64,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.interNormal(size: 13, color: AppStyle.textPrimary),
          ),
        ),
        if (km != null) ...<Widget>[
          const SizedBox(width: 8),
          Text(
            '${km!.toStringAsFixed(1)} '
            '${AppHelpers.getTranslation(TrKeys.km).toLowerCase()}',
            style: AppStyle.interNormal(
              size: 12,
              color: AppStyle.textDarkSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

/// The single action, in the brand colour so it is the one thing on the
/// window that asks for a tap.
class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppStyle.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: AppStyle.interSemi(size: 13, color: AppStyle.blackColor),
          ),
        ),
      ),
    );
  }
}
