/// The one helper the ported seller models needed from `paas_manager`'s
/// `infrastructure/services/extension.dart`.
///
/// That file is not brought across: it is a ~200-line date/time utility set
/// measured at 5.7% similar to `base_sdk`'s same-named `extension.dart`, i.e. a
/// different file that happens to share a name. Only `toBool()` was actually
/// used by these models, so only `toBool()` moves.
extension SellerBoolParsing on String {
  bool toBool() => this == 'true' || this == '1';
}
