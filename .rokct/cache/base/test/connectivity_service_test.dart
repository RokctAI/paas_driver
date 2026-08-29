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


import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/services/connectivity_service.dart';

void main() {
  final service = ConnectivityService.I;

  var probeCalls = 0;
  var drainCalls = 0;
  var probeAnswer = true;

  setUp(() async {
    // stop() resets the pessimistic _wasOnline baseline between tests.
    await service.stop();
    probeCalls = 0;
    drainCalls = 0;
    probeAnswer = true;
    service.backendProbe = () async {
      probeCalls++;
      return probeAnswer;
    };
    service.onBackendRegained = () async {
      drainCalls++;
    };
  });

  test('regain with backend answering kicks the drain', () async {
    await service.handleConnectivityChange([ConnectivityResult.wifi]);
    expect(probeCalls, 1);
    expect(drainCalls, 1);
  });

  test('regain with backend unreachable does NOT kick the drain', () async {
    probeAnswer = false;
    await service.handleConnectivityChange([ConnectivityResult.wifi]);
    expect(probeCalls, 1);
    expect(drainCalls, 0);
  });

  test('staying online never re-probes or re-kicks', () async {
    await service.handleConnectivityChange([ConnectivityResult.wifi]);
    await service.handleConnectivityChange([ConnectivityResult.wifi]);
    await service.handleConnectivityChange([ConnectivityResult.mobile]);
    expect(probeCalls, 1);
    expect(drainCalls, 1);
  });

  test('going offline is silent; the NEXT regain probes again', () async {
    await service.handleConnectivityChange([ConnectivityResult.wifi]);
    await service.handleConnectivityChange([ConnectivityResult.none]);
    expect(probeCalls, 1);
    await service.handleConnectivityChange([ConnectivityResult.ethernet]);
    expect(probeCalls, 2);
    expect(drainCalls, 2);
  });

  test('offline results never probe or kick', () async {
    await service.handleConnectivityChange([ConnectivityResult.none]);
    await service.handleConnectivityChange([ConnectivityResult.bluetooth]);
    expect(probeCalls, 0);
    expect(drainCalls, 0);
  });
}
