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

import 'package:delivery_sdk/src/driver/application/route/route_notifier.dart';
import 'package:delivery_sdk/src/driver/application/route/route_state.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>(
  (ref) => RouteNotifier(routeRepository),
);
