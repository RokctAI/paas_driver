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


import 'package:base_sdk/base_sdk.dart';

import 'package:telemetry_sdk/src/common/delivery/telemetry_spool.dart';

/// Formal owner of base_sdk's telemetry injection seam (ADR-005/ADR-006).
///
/// base_sdk owns [TelemetryClient] — the one client every SDK may import —
/// and exposes exactly one delivery-override hook: `TelemetryClient.configure`
/// with a [TelemetryTransport]. This SDK is the sanctioned caller of that
/// hook. It ships no client of its own and no HTTP of its own: default
/// delivery stays base_sdk's platform-gateway POST (cmd-routed), and
/// policy plugs in HERE as an injected transport instead of a parallel
/// pipeline. The policy the composed shell applies is [enableSpool]:
/// [TelemetrySpool] sends online and queues offline, flushing the queue in
/// batches when connectivity returns. Feature SDKs extend
/// the lane the ADR-005 way — their own [TelemetryClient.track] /
/// [TelemetryClient.logError] events through the base_sdk import they
/// already have; they never inject a transport.
class TelemetryBootstrap {
  TelemetryBootstrap._();

  /// Applies telemetry_sdk's delivery policy to base_sdk's seam.
  ///
  /// The default (no [transport]) is deliberate: keep [TelemetryClient]'s
  /// built-in gateway delivery, byte-for-byte the behavior of a composition
  /// without telemetry_sdk. Passing a [transport] swaps the delivery lane
  /// for BOTH the error and the tracking cmds; per the client's contract the
  /// caller-facing API never throws either way.
  static void configure({TelemetryTransport? transport}) {
    TelemetryClient.configure(transport: transport);
  }

  /// Installs [TelemetrySpool] ([spool], default its process-wide
  /// instance) as the transport and starts its connectivity-driven flush.
  /// Online events still leave through the same platform-gateway POST;
  /// offline ones are kept on the device and sent later instead of lost.
  /// Called by `TelemetrySdkDependencies.register`. Fail-open: telemetry
  /// must never break boot.
  static void enableSpool({TelemetrySpool? spool}) {
    final TelemetrySpool target = spool ?? TelemetrySpool.instance;
    configure(transport: target.deliver);
    try {
      target.start();
    } catch (_) {
      // Live sends still work; the queue flushes after the next send.
    }
  }
}
