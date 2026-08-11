/// The one helper the ported manager order models needed from `paas_manager`'s
/// `infrastructure/services/extension.dart`.
///
/// Same reasoning as products_sdk's `seller_json_ext.dart`: that legacy file is
/// a ~200-line date/chart utility set measured at 5.7% similar to base_sdk's
/// same-named `extension.dart` — a different file sharing a name. Only
/// `toBool()` is used by these models, so only `toBool()` moves.
extension OrderBoolParsing on String {
  bool toBool() => this == 'true' || this == '1';
}
