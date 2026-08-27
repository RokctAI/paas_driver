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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:delivery_sdk/src/driver/application/route/route_state.dart';
import 'package:delivery_sdk/src/driver/domain/interface/route.dart';

class RouteNotifier extends StateNotifier<RouteState> {
  final CourierRouteRepositoryFacade _routeRepository;

  RouteNotifier(this._routeRepository) : super(const RouteState());

  /// Fetches the merged server-ordered route and the dispatch-route
  /// header. The optimizer is seeded with the courier's last known map
  /// position when one is stored.
  Future<void> fetchRoute(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (!connected) {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    state = state.copyWith(isLoading: true);
    final address = LocalStorage.getAddressSelected();
    final response = await _routeRepository.getDriverRoute(
      latitude: address?.latitude,
      longitude: address?.longitude,
    );
    response.when(
      success: (stops) {
        state = state.copyWith(stops: stops, isLoading: false);
      },
      failure: (failure, status) {
        state = state.copyWith(isLoading: false);
        if (context.mounted) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        }
        debugPrint('==> get driver route failure: $failure');
      },
    );

    final dispatch = await _routeRepository.getMyDispatchRoute();
    dispatch.when(
      success: (data) {
        state = state.copyWith(
          dispatchRoute: data.route,
          clearDispatchRoute: data.route == null,
        );
      },
      failure: (failure, status) {
        debugPrint('==> get dispatch route failure: $failure');
      },
    );
  }

  /// Marks a dispatch stop Done/Skipped, then re-fetches so the server
  /// re-orders what remains.
  Future<void> completeStop(
    BuildContext context, {
    required String routeId,
    required String stopName,
    String status = 'Done',
    VoidCallback? onSuccess,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (!connected) {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
      return;
    }
    state = state.copyWith(isCompleting: true);
    final response = await _routeRepository.completeDispatchStop(
      routeId: routeId,
      stopName: stopName,
      status: status,
    );
    bool completed = false;
    response.when(
      success: (data) {
        completed = true;
      },
      failure: (failure, statusCode) {
        if (context.mounted) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        }
        debugPrint('==> complete dispatch stop failure: $failure');
      },
    );
    state = state.copyWith(isCompleting: false);
    if (completed) {
      onSuccess?.call();
      if (context.mounted) {
        // Re-fetch so the server re-orders the remaining stops.
        await fetchRoute(context);
      }
    }
  }
}
