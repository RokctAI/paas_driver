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

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/error_presenter.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/telemetry.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_delivery_seed.dart';

/// Why the courier's own position could not be read.
enum CourierLocationDenial {
  /// The OS refused location access (or the driver declined the prompt).
  permissionDenied,

  /// Refused with "don't ask again" — no prompt can be raised any more.
  permissionDeniedForever,

  /// Permission is fine, but location services are switched off.
  serviceDisabled,

  /// Anything else the platform threw while producing a fix.
  lookupFailed,
}

/// The outcome of one attempt at a fix: either a [position], or a [denial]
/// plus the verbatim platform [detail].
///
/// [detail] is admin-grade diagnostic text (an exception's `toString()`) —
/// it is what callers hand to telemetry, and it must never reach a driver's
/// screen.
class CourierLocationResult {
  const CourierLocationResult.fix(Position this.position)
      : denial = null,
        detail = null,
        pinned = false;

  /// A position this build asserted rather than measured (see
  /// [CourierLocationFix.pinnedBuild]). It already IS the stored address,
  /// or the configured anchor when none is stored, so a caller must not
  /// write it back over the address the courier chose.
  const CourierLocationResult.pinned(Position this.position)
      : denial = null,
        detail = null,
        pinned = true;

  const CourierLocationResult.unavailable({
    required this.denial,
    required this.detail,
  })  : position = null,
        pinned = false;

  final Position? position;
  final CourierLocationDenial? denial;
  final String? detail;

  /// True when [position] came from [CourierLocationFix.pinnedPosition]
  /// rather than the platform.
  final bool pinned;

  bool get hasFix => position != null;
}

/// One never-throwing attempt at the courier's own position.
///
/// This is the driver home page's whole location story, moved out of the
/// template so it can be tested. The template used to inline it, and got it
/// wrong in a way that took the page down (paas_driver tour 33623262696):
///
///   * `initState` fires `checkPermission()` and `getMyLocation()` without
///     awaiting either, so `getMyLocation` ran with the shared `check`
///     field still null, skipped both denial branches and called
///     `getCurrentPosition()` having asked the OS for nothing;
///   * Android refuses that call outright — no dialog, nothing in logcat —
///     and the resulting `PermissionDeniedException` escaped an un-awaited
///     future, where nothing could catch it.
///
/// A driver who has no location permission is a NORMAL state, not a crash:
/// every refusal here comes back as a [CourierLocationResult] carrying the
/// verbatim platform text for telemetry, and the page keeps rendering on
/// its fallback coordinates (last saved address, else the demo pin).
///
/// Reporting is deliberately NOT done here — see [CourierLocationNotice].
/// Callers must not swallow the result.
class CourierLocationFix {
  CourierLocationFix({GeolocatorPlatform? platform, bool? pinned})
      : _injected = platform,
        _pinned = pinned ?? pinnedBuild;

  final GeolocatorPlatform? _injected;

  /// Injectable for tests; defaults to [pinnedBuild].
  final bool _pinned;

  /// Resolved per call, so a test may equally inject through the
  /// constructor or swap `GeolocatorPlatform.instance`.
  GeolocatorPlatform get _platform => _injected ?? GeolocatorPlatform.instance;

  /// Whether this build pins the courier to the stored address instead of
  /// reading the device's position.
  ///
  /// `IS_DEMO` builds run against [DemoDeliverySeed]: invented South
  /// African shops, customers and addresses laid out around the app's
  /// configured anchor, with the courier's stored address seeded among
  /// them. The device's own GPS means nothing there — an emulator sits at
  /// its default Californian coordinate, a reviewer's phone wherever the
  /// reviewer is — and a real fix used to overwrite that stored address
  /// and animate the map an ocean away from every job on it. So a pinned
  /// build never asks the platform: [current] answers with
  /// [pinnedPosition], tagged [CourierLocationResult.pinned] so the caller
  /// leaves storage alone, and the on-duty tracking lane does not start.
  static bool get pinnedBuild => AppConstants.isDemo;

  /// Where a pinned build stands: the stored address, else the seed's
  /// anchor (which is the same fallback the home map already centres on).
  static Position pinnedPosition() {
    final stored = LocalStorage.getAddressSelected();
    final latitude = stored?.latitude;
    final longitude = stored?.longitude;
    return Position(
      latitude: latitude != null && longitude != null
          ? latitude
          : DemoDeliverySeed.anchorLatitude,
      longitude: latitude != null && longitude != null
          ? longitude
          : DemoDeliverySeed.anchorLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  Future<CourierLocationResult> current() async {
    if (_pinned) return CourierLocationResult.pinned(pinnedPosition());

    LocationPermission permission;
    try {
      permission = await _platform.checkPermission();
      if (permission == LocationPermission.denied) {
        // Ask once. The old code asked from two call sites racing each
        // other, which the platform channel answers with
        // PermissionRequestInProgressException.
        permission = await _platform.requestPermission();
      }
    } catch (e) {
      // A missing manifest entry (PermissionDefinitionsNotFoundException) or
      // a request already in flight. Neither is worth losing the page over.
      return CourierLocationResult.unavailable(
        denial: CourierLocationDenial.lookupFailed,
        detail: '$e',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const CourierLocationResult.unavailable(
        denial: CourierLocationDenial.permissionDeniedForever,
        detail: 'LocationPermission.deniedForever: the driver refused with '
            '"don\'t ask again" — no prompt can be raised from the app.',
      );
    }
    if (permission == LocationPermission.denied) {
      return const CourierLocationResult.unavailable(
        denial: CourierLocationDenial.permissionDenied,
        detail: 'LocationPermission.denied after requestPermission(): the '
            'driver declined, or the platform refused without prompting.',
      );
    }

    try {
      return CourierLocationResult.fix(await _platform.getCurrentPosition());
    } on PermissionDeniedException catch (e) {
      // The state above said we were entitled to a fix and the platform
      // refused anyway — exactly what the tour's emulator did. Only the call
      // itself reports this, so no amount of state checking replaces the
      // catch.
      return CourierLocationResult.unavailable(
        denial: CourierLocationDenial.permissionDenied,
        detail: '$e',
      );
    } on LocationServiceDisabledException catch (e) {
      return CourierLocationResult.unavailable(
        denial: CourierLocationDenial.serviceDisabled,
        detail: '$e',
      );
    } catch (e) {
      // Timeouts, a dead location provider, a plugin-level failure. The page
      // survives all of them; the detail still goes to admins.
      return CourierLocationResult.unavailable(
        denial: CourierLocationDenial.lookupFailed,
        detail: '$e',
      );
    }
  }
}

/// How a refused fix is reported: one friendly translated line for the
/// driver, the verbatim platform detail for admins.
abstract class CourierLocationNotice {
  CourierLocationNotice._();

  /// Stable machine-readable event class for the `log_frontend_error` lane.
  static const String telemetryType = 'driver_home_location_unavailable';

  /// Fleet split (decision-log entry 56), applied through base_sdk's
  /// [ErrorPresenter]: the driver sees only
  /// [TrKeys.agreeLocation] — the same line base_sdk's `LocationService`
  /// shows when it cannot get a fix — while the `PermissionDeniedException`
  /// text, which is diagnostic detail and not copy written for a driver,
  /// rides telemetry to admins.
  static void show(BuildContext context, CourierLocationResult result) {
    if (result.hasFix) return;
    ErrorPresenter.showTechnical(
      context,
      type: telemetryType,
      detail: result.detail ?? '',
      friendly: AppHelpers.getTranslation(TrKeys.agreeLocation),
      extra: _extra(result),
    );
  }

  /// Telemetry-only form, for a caller with no live `BuildContext` — the
  /// page was disposed while the platform call was still in flight. The
  /// detail still has to reach admins (splash_page's precedent for the
  /// ErrorPresenter-less case), there is simply nobody left to show a line
  /// to.
  static void report(CourierLocationResult result) {
    if (result.hasFix) return;
    unawaited(
      TelemetryClient.I.logError(
        type: telemetryType,
        context: <String, dynamic>{
          'server_message': result.detail ?? '',
          ..._extra(result),
        },
      ),
    );
  }

  static Map<String, String> _extra(CourierLocationResult result) =>
      <String, String>{
        'surface': 'driver_home',
        'denial': result.denial?.name ?? '',
      };
}
