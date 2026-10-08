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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/data/poi_data.dart';

/// The customer map's read of the admin-approved points of interest around
/// a map centre.
///
/// Zone-local (delivery_sdk's `DriverLoadRepositoryFacade` precedent):
/// base_sdk owns the [POIData] the map draws, but the call that fills it
/// belongs to the SDK that owns the page.
///
/// One method, one direction. The customer map is a read surface: a
/// shopper cannot add, edit or approve a point of interest from it, so
/// there is nothing else on this facade.
abstract class CustomerPoiRepositoryFacade {
  /// Points of interest within [radiusKm] of ([latitude], [longitude]).
  ///
  /// Answers an empty list rather than a failure when the area simply has
  /// none - an empty map is a fact, not an error.
  Future<ApiResult<List<POIData>>> getCustomerPois({
    required double latitude,
    required double longitude,
    double radiusKm,
  });
}
