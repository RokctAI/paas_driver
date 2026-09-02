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

import 'package:delivery_sdk/src/driver/application/home/driver_home_notifier.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';

/// The driver home composition's state (design strip section 49).
///
/// Sits alongside `homeProvider` rather than inside it: `homeProvider`
/// owns the MAP and the live job, this owns the SHEET's day figures and
/// the wallet floor. Keeping them apart means the map's 10-second
/// routing poll never rebuilds the money on screen and vice versa.
final driverHomeProvider =
    StateNotifierProvider<DriverHomeNotifier, DriverHomeState>(
      (ref) => DriverHomeNotifier(orderRepository),
    );
