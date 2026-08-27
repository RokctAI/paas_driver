// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import 'package:base_sdk/base_sdk.dart';

/// Formal owner of base_sdk's telemetry injection seam (ADR-005/ADR-006).
///
/// base_sdk owns [TelemetryClient] — the one client every SDK may import —
/// and exposes exactly one delivery-override hook: `TelemetryClient.configure`
/// with a [TelemetryTransport]. This SDK is the sanctioned caller of that
/// hook. It ships no client of its own and no HTTP of its own: default
/// delivery stays base_sdk's platform-gateway POST (cmd-routed), and any
/// future policy (batching, sampling, offline spooling) plugs in HERE as an
/// injected transport instead of a parallel pipeline. Feature SDKs extend
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
}
