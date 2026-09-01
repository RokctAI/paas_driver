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

library corporate_sdk;

// Import concrete files via package:corporate_sdk/src/...
export 'src/common/di/corporate_di.dart';
// Policy / terms pages — host apps wire these into EmbeddedWidgets
// (auth's login footer links call policyPage()/termPage()).
export 'src/common/presentation/pages/policy_term/policy_page.dart';
export 'src/common/presentation/pages/policy_term/term_page.dart';
