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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:zones_sdk/src/driver/application/delivery_zone/delivery_zone_state.dart';
import 'package:zones_sdk/src/common/domain/interface/delivery_zones.dart';

class DeliveryZoneNotifier extends StateNotifier<DeliveryZoneState> {
  final DeliveryZonesFacade _zones;

  /// Whether the current user may redraw the zone, evaluated per tap.
  ///
  /// Injected rather than decided here because the restriction is
  /// flavour-specific: the driver app gates editing on the platform's
  /// `driver_can_edit_credentials` setting (see [canEditDeliveryZone]), while
  /// a merchant editing their own shop's catchment has no such concept. The
  /// default is permissive, so a flavour with no restriction supplies nothing
  /// — rather than inheriting a gate keyed on a setting that is meaningless to
  /// it and only passing because the key happens to be absent.
  final bool Function() _canEdit;

  DeliveryZoneNotifier(
    this._zones, {
    bool Function()? canEdit,
  })  : _canEdit = canEdit ?? _alwaysEditable,
        super(const DeliveryZoneState());

  static bool _alwaysEditable() => true;

  /// The drawn polygon, styled the same whether it came from the server or
  /// from taps. Kept private so both paths cannot drift apart visually.
  Set<Polygon> _polygonFor(List<LatLng> points) {
    final Set<Polygon> polygon = HashSet<Polygon>();
    if (points.isEmpty) return polygon;
    polygon.add(
      Polygon(
        polygonId: const PolygonId('1'),
        points: points,
        fillColor: AppStyle.primary.withOpacity(0.3),
        strokeColor: AppStyle.primary,
        geodesic: false,
        strokeWidth: 4,
      ),
    );
    return polygon;
  }

  Future<void> updateDeliveryZone({VoidCallback? updateSuccess}) async {
    state = state.copyWith(isSaving: true);
    final response = await _zones.updateDeliveryZones(
      points: state.tappedPoints
          .map((p) => <double>[p.latitude, p.longitude])
          .toList(),
    );
    response.when(
      success: (data) {
        state = state.copyWith(isSaving: false);
        updateSuccess?.call();
      },
      failure: (fail, status) {
        state = state.copyWith(isSaving: false);
        debugPrint('===> update delivery zone failed $fail');
      },
    );
  }

  void addTappedPoint(LatLng point) {
    if (!_canEdit()) return;
    final List<LatLng> points = List.from(state.tappedPoints)..add(point);
    state = state.copyWith(tappedPoints: points, polygon: _polygonFor(points));
  }

  Future<void> fetchDeliveryZone() async {
    state = state.copyWith(isLoading: true, tappedPoints: []);
    final response = await _zones.fetchDeliveryZones();
    response.when(
      success: (addresses) {
        if (addresses.isNotEmpty) {
          final points = addresses
              .where((a) => a.length >= 2)
              .map((a) => LatLng(a[0], a[1]))
              .toList();
          state = state.copyWith(
            deliveryZones: addresses,
            polygon: _polygonFor(points),
          );
        }
        state = state.copyWith(isLoading: false);
      },
      failure: (failure, status) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> error with fetching delivery zone $failure');
      },
    );
  }
}
