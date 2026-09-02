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

import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/services/app_connectivity.dart';

/// The POS checkout's connectivity probe, with a debug seam.
///
/// The checkout flips into its offline inversion (frames 11e/11f: offline
/// banner, straight-to-code entry) on this probe's answer. Tests and
/// headless tours can't reach the connectivity_plus platform channel, so
/// [debugConnectivityOverride] pins the answer — the same widget code then
/// renders both flows honestly.
class PosConnectivity {
  PosConnectivity._();

  /// Debug/test seam: non-null pins the probe's answer. Never set in
  /// production code.
  @visibleForTesting
  static bool? debugConnectivityOverride;

  /// True when the till can reach a network. Radio-level probe
  /// (base_sdk's [AppConnectivity.connectivity]) — the offline inversion
  /// is a counter-flow decision, not a backend-health one.
  static Future<bool> check() async {
    final override = debugConnectivityOverride;
    if (override != null) return override;
    try {
      return await AppConnectivity.connectivity();
    } catch (_) {
      // No platform channel (headless harness) — treat as offline: the
      // code path still lets the sale complete.
      return false;
    }
  }
}
