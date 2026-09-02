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

/// Contract for the shop's kitchen (prep station) list.
///
/// Declared in this SDK's own `domain/interface/` rather than in `base_sdk`:
/// ADR-005 lets a consumer own the interface it needs, and nothing outside
/// `kitchen_sdk` consumes kitchens directly today. See
/// `docs/frappe-endpoint-contract.md` for endpoint coverage.
library;

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:kitchen_sdk/src/common/infrastructure/models/response/kitchens_paginate_response.dart';

abstract class KitchensRepositoryFacade {
  Future<ApiResult<KitchensPaginateResponse>> getKitchens({int? perPage});
}
