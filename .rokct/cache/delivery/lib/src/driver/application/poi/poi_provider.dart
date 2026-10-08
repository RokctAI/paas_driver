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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_sdk/src/driver/application/poi/poi_notifier.dart';
import 'package:delivery_sdk/src/driver/application/poi/poi_state.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';

/// The points-of-interest slice.
///
/// Deliberately NOT auto-disposed, for the same reason the van-sales slice
/// is not: the home map draws its pins, the sell screen names the point the
/// sale was made at, the add sheet files one and the route reads them —
/// four surfaces, one slice, and the point selected on one of them must
/// still be selected on the next.
///
/// Tests override it whole:
/// `driverPoiProvider.overrideWith((ref) => DriverPoiNotifier(fake, isOnline: ...))`.
final driverPoiProvider =
    StateNotifierProvider<DriverPoiNotifier, DriverPoiState>(
  (ref) => DriverPoiNotifier(poiRepository),
);
