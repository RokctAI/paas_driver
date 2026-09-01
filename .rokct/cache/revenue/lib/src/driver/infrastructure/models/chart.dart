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
