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
import 'package:telemetry_sdk/src/common/di/telemetry_bootstrap.dart';

/// Composed-shell entry point: the generated main.dart sdk-di block calls
/// this (installer convention: `<PascalCase>Dependencies.register`), after
/// base_sdk's own registration. Nothing is registered into [getIt] — the
/// client stays base_sdk's singleton — this SDK's whole job at boot is
/// applying the default delivery policy through the seam.
class TelemetrySdkDependencies {
  static void register(GetIt getIt) {
    TelemetryBootstrap.configure();
  }
}
