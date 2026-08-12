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
