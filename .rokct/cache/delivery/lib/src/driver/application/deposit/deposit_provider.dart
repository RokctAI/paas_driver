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

import 'package:delivery_sdk/src/driver/application/deposit/deposit_notifier.dart';
import 'package:delivery_sdk/src/driver/application/deposit/deposit_state.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';

/// The deposit slice (frames 49g/49h/49i).
///
/// Deliberately NOT auto-disposed: the chooser pre-reads the destination,
/// the capture sheet sends, and the status plane that follows must still
/// hold the row just sent — three surfaces, one slice.
///
/// Tests override it whole:
/// `depositProvider.overrideWith((ref) => DepositNotifier(fake, isOnline: ...))`.
final depositProvider = StateNotifierProvider<DepositNotifier, DepositState>(
  (ref) => DepositNotifier(depositRepository),
);
