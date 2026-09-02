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

import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';

/// Plain immutable state (no freezed: keeps the slice analyzable without
/// codegen, matching the pure-Dart models in infrastructure/models).
class RouteState {
  final bool isLoading;
  final bool isCompleting;
  final List<RouteStopData> stops;
  final DispatchRouteInfo? dispatchRoute;

  const RouteState({
    this.isLoading = false,
    this.isCompleting = false,
    this.stops = const [],
    this.dispatchRoute,
  });

  /// Index of the stop the driver should head to next: the first
  /// pending stop (order/parcel stops are always pending while listed).
  int get nextStopIndex {
    for (int i = 0; i < stops.length; i++) {
      if (stops[i].isPending) return i;
    }
    return -1;
  }

  RouteState copyWith({
    bool? isLoading,
    bool? isCompleting,
    List<RouteStopData>? stops,
    DispatchRouteInfo? dispatchRoute,
    bool clearDispatchRoute = false,
  }) {
    return RouteState(
      isLoading: isLoading ?? this.isLoading,
      isCompleting: isCompleting ?? this.isCompleting,
      stops: stops ?? this.stops,
      dispatchRoute: clearDispatchRoute
          ? null
          : (dispatchRoute ?? this.dispatchRoute),
    );
  }
}
