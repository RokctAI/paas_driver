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
