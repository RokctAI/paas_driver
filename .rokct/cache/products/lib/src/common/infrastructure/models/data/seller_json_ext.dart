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
