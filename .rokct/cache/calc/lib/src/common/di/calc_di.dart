import 'package:get_it/get_it.dart';

/// Registered by the composed host's generated main.dart
/// (`CalcSdkDependencies.register(GetIt.instance)` — the installer derives
/// the class name from the SDK name, so this exact name is load-bearing).
class CalcSdkDependencies {
  /// The calculator is self-contained (Riverpod-only state, no repositories
  /// or services), so there is nothing to register — this exists solely so
  /// the composed host's generated DI wiring resolves.
  static void register(GetIt getIt) {}
}
