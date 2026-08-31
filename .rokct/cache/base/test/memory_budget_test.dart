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


import 'package:flutter_test/flutter_test.dart';

import 'package:base_sdk/src/services/memory_pressure_service.dart';

/// Flutter's built-in default, which every app in the fleet was running on
/// every device before this. No tier may exceed it.
const int _flutterDefaultBytes = 100 << 20;

void main() {
  const int mb = 1024 * 1024;
  const int gb = 1024 * 1024 * 1024;

  group('MemoryPressureService.budgetFor', () {
    test('unknown RAM falls back to the ~4GB tier, never to a bigger one', () {
      final budget = MemoryPressureService.budgetFor(null);
      expect(budget.maximumSizeBytes, 48 * mb);
      expect(budget.maximumSize, 300);
      expect(budget.totalPhysicalMemoryBytes, isNull);
    });

    test('a nonsense reading is treated as unknown', () {
      expect(MemoryPressureService.budgetFor(0).maximumSizeBytes, 48 * mb);
      expect(MemoryPressureService.budgetFor(-1).maximumSizeBytes, 48 * mb);
    });

    test('low-RAM devices get the smallest tier', () {
      expect(MemoryPressureService.budgetFor(2 * gb).maximumSizeBytes, 32 * mb);
      expect(MemoryPressureService.budgetFor(2 * gb).maximumSize, 200);
    });

    test('a 4GB device reporting ~3.7GB lands in the 4GB tier', () {
      // ActivityManager reports less than the nominal figure, which is why
      // the boundary sits below 4GB.
      final budget = MemoryPressureService.budgetFor(3700 * mb);
      expect(budget.maximumSizeBytes, 48 * mb);
      expect(budget.maximumSize, 300);
    });

    test('a 6GB device reporting ~5.7GB lands in the 6GB tier', () {
      final budget = MemoryPressureService.budgetFor(5700 * mb);
      expect(budget.maximumSizeBytes, 72 * mb);
      expect(budget.maximumSize, 400);
    });

    test('an 8GB device reporting ~7.4GB lands in the top tier', () {
      final budget = MemoryPressureService.budgetFor(7400 * mb);
      expect(budget.maximumSizeBytes, 96 * mb);
      expect(budget.maximumSize, 500);
    });

    test('12GB does not exceed the top tier', () {
      final budget = MemoryPressureService.budgetFor(12 * gb);
      expect(budget.maximumSizeBytes, 96 * mb);
    });

    test('no tier is above Flutter default, and tiers rise with RAM', () {
      final samples = <int>[1 * gb, 2 * gb, 3700 * mb, 5700 * mb, 7400 * mb, 16 * gb];
      var previous = 0;
      for (final ram in samples) {
        final budget = MemoryPressureService.budgetFor(ram);
        expect(
          budget.maximumSizeBytes,
          lessThanOrEqualTo(_flutterDefaultBytes),
          reason: 'a tier must never raise the ceiling above Flutter default',
        );
        expect(budget.maximumSizeBytes, greaterThanOrEqualTo(previous));
        expect(budget.totalPhysicalMemoryBytes, ram);
        previous = budget.maximumSizeBytes;
      }
    });

    test('the background bitmap ceiling is not approached by the cache alone', () {
      // Play treats more than 200MB of bitmap memory in background as a
      // violation. Flutter's fixed 100MB default put half of that budget
      // against the image cache on the smallest device we ship to.
      for (final ram in <int>[2 * gb, 3700 * mb, 5700 * mb, 7400 * mb]) {
        expect(
          MemoryPressureService.budgetFor(ram).maximumSizeBytes,
          lessThan(100 * mb),
        );
      }
    });
  });
}
