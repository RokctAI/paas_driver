// Copyright (c) 2026 RokctAI
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

/// Chart row for the driver income page's earnings bar chart.
///
/// Straight port of `paas_driver`'s `lib/infrastructure/models/data/chart.dart`.
/// Deliberately a plain model with no `charts_flutter` import: this SDK stays
/// chart-library-agnostic (the same stance [CourierStatisticsRepositoryFacade]
/// documents), so [StatisticsNotifier] emits `List<OrdinalSales>` and the
/// installed income template maps them into `charts_flutter` `Series` HOST-side,
/// where the host pubspec's `charts_flutter` dependency lives.
class OrdinalSales {
  final String day;
  final int sales;

  OrdinalSales({required this.day, required this.sales});
}
