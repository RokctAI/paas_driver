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

// TelemetryClient's error lane: the logError delivery contract and its
// one-shot control-role fallback (an app can be pointed at a control-role
// site, whose gateway only resolves `control:`-prefixed cmds — the app's
// errors then land locally at control via the log_frontend_error twin,
// never in the tenant->control backend-error lane).

import 'dart:convert';

import 'package:base_sdk/src/services/telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // The transport seam is app-global; never let one test's wiring leak.
    TelemetryClient.configure(transport: null);
  });

  group('logError delivery', () {
    test('sends the wire contract under the tenant cmd', () async {
      final delivered = <Map<String, dynamic>>[];
      TelemetryClient.configure(transport: (cmd, payload) async {
        delivered.add({'cmd': cmd, ...payload});
      });

      await TelemetryClient.I.logError(
        type: 'unit_test_error',
        sessionId: 's-1',
        context: {'detail': 'value'},
      );

      expect(delivered, hasLength(1));
      expect(delivered.single['cmd'], TelemetryClient.cmd);
      expect(delivered.single['error_message'], 'unit_test_error');
      final context =
          jsonDecode(delivered.single['context'] as String) as Map;
      expect(context['type'], 'unit_test_error');
      expect(context['session_id'], 's-1');
      expect(context['context']['detail'], 'value');
    });

    test('control-role fallback: a rejected tenant cmd retries once with '
        'the control: prefix', () async {
      final cmds = <String>[];
      TelemetryClient.configure(transport: (cmd, payload) async {
        cmds.add(cmd);
        // A control-role gateway rejects the unprefixed tenant cmd; the
        // control-role key is accepted.
        if (cmd == TelemetryClient.cmd) {
          throw Exception('control gateway: unknown cmd');
        }
      });

      await TelemetryClient.I.logError(type: 'unit_test_error');

      expect(cmds, [TelemetryClient.cmd, TelemetryClient.controlCmd]);
    });

    test('a fully failed delivery is swallowed (never breaks the app)',
        () async {
      var attempts = 0;
      TelemetryClient.configure(transport: (cmd, payload) async {
        attempts++;
        throw Exception('offline');
      });

      // Must not throw: telemetry never breaks the app.
      await TelemetryClient.I.logError(type: 'unit_test_error');

      // Two attempts per failed send: the tenant cmd, then the one-shot
      // control-role fallback.
      expect(attempts, 2);
    });
  });
}
