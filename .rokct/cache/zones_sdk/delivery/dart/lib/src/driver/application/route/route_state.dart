// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
