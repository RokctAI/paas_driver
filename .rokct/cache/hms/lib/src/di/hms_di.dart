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

/// DI registrar the installer wires into every composed main.dart
/// (@generated-sdk-di block calls HmsSdkDependencies.register).
///
/// hms_sdk's services are process-wide singletons reached via their own
/// `instance` accessors (DeviceServices, HmsPushBootstrap) - nothing needs
/// a get_it registration yet, but the registrar must exist because the
/// installer generates the call unconditionally for every installed SDK.
class HmsSdkDependencies {
  static void register(GetIt getIt) {
    // Intentionally empty - see class comment.
  }
}
