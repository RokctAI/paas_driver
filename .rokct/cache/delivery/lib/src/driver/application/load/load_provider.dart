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

import 'package:delivery_sdk/src/driver/application/load/load_notifier.dart';
import 'package:delivery_sdk/src/driver/application/load/load_state.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';

/// The van-sales slice.
///
/// Deliberately NOT auto-disposed, for the same reason the deposit slice is
/// not: the home tile reads it, the load list works it, and the sell and
/// return screens push over that list and must come back to the SAME
/// remaining figures the write they just made left behind — four surfaces,
/// one slice.
///
/// Tests override it whole:
/// `driverLoadProvider.overrideWith((ref) => DriverLoadNotifier(fake, isOnline: ...))`.
final driverLoadProvider =
    StateNotifierProvider<DriverLoadNotifier, DriverLoadState>(
  (ref) => DriverLoadNotifier(loadRepository),
);
