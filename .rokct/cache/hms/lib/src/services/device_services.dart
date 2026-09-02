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

// This file makes no outgoing HTTP calls: GMS/HMS availability is probed via
// platform-channel plugins only. Flagged solely because its path contains
// 'services'; there is no request to attach a trace header to.
// compliance-ignore-file: obs-flutter-trace

import 'package:flutter/foundation.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:huawei_hmsavailability/huawei_hmsavailability.dart';

/// Which mobile-services stack this device actually has.
///
/// `gms` doubles as the fail-open default: every non-Android platform and
/// every detection error resolves to it, so the existing comms_sdk
/// FCM path stays the owner of push everywhere except a device that is
/// POSITIVELY GMS-free and HMS-capable (Huawei/Honor without Play
/// Services).
enum DeviceServicesAvailability { gms, hms, neither }

/// Answers "GMS, HMS or neither?" for this device, once, then caches.
///
/// Detection order mirrors the fleet's push ownership: Google Play
/// Services wins whenever it is present (or whenever we cannot prove it
/// absent - fail-open), Huawei Mobile Services is only reported for
/// devices where GMS is definitively missing, and `neither` is the
/// degraded remainder (no push either way; the app still runs).
class DeviceServices {
  DeviceServices._();

  static final DeviceServices instance = DeviceServices._();

  DeviceServicesAvailability? _cached;

  /// Resolves (and caches) the device's mobile-services availability.
  ///
  /// Never throws: any plugin/platform failure resolves to
  /// [DeviceServicesAvailability.gms] so the default FCM path is never
  /// hijacked by a detection bug.
  Future<DeviceServicesAvailability> resolve() async {
    final cached = _cached;
    if (cached != null) {
      return cached;
    }
    final resolved = await _detect();
    _cached = resolved;
    return resolved;
  }

  Future<DeviceServicesAvailability> _detect() async {
    // GMS/HMS is an Android question. iOS/macOS push via APNs behind the
    // firebase_messaging plugin and desktop/web have no services stack at
    // all - report gms so callers treat them as "not the HMS path".
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return DeviceServicesAvailability.gms;
    }

    try {
      final availability = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability();
      if (!_gmsDefinitivelyAbsent(availability)) {
        // Present, updating, temporarily disabled, or unknown: keep the
        // FCM path. Only a device with NO usable Play Services at all
        // falls through to the HMS probe.
        return DeviceServicesAvailability.gms;
      }
    } catch (e) {
      debugPrint('==> GMS availability check failed, assuming gms: $e');
      return DeviceServicesAvailability.gms;
    }

    try {
      // HmsApiAvailability returns HMS Core status codes; 0 is
      // HMS_CORE_APK_AVAILABLE.
      final int hmsStatus = await HmsApiAvailability().isHMSAvailable();
      return hmsStatus == 0
          ? DeviceServicesAvailability.hms
          : DeviceServicesAvailability.neither;
    } catch (e) {
      debugPrint('==> HMS availability check failed, assuming gms: $e');
      return DeviceServicesAvailability.gms;
    }
  }

  // GooglePlayServicesAvailability is a value class, not an enum - compare
  // against its consts. Only states meaning "no usable Play Services on
  // this device, ever" count as absent; transient states (updating, update
  // required, disabled, unknown) stay on the fail-open gms path.
  bool _gmsDefinitivelyAbsent(GooglePlayServicesAvailability availability) {
    return availability == GooglePlayServicesAvailability.serviceMissing ||
        availability == GooglePlayServicesAvailability.serviceInvalid ||
        availability == GooglePlayServicesAvailability.notAvailableOnPlatform;
  }

  /// Test seam: clears the cached answer so the next [resolve] re-detects.
  @visibleForTesting
  void resetCache() {
    _cached = null;
  }
}
