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

/// Models for the server-ordered driver route
/// (`paas.api.driver_order.driver_order.get_driver_route` and
/// `paas.api.dispatch_route.dispatch_route.get_my_dispatch_route`).
///
/// The server is authoritative for stop ordering: `sequence` is the drive
/// order, pickups always precede their own drop-offs and coordinate-less
/// stops ride at the tail flagged [missingCoordinates].
class RouteStopData {
  final String? stopType;
  final String? refDoctype;
  final String? refName;
  final String? label;
  final double? latitude;
  final double? longitude;
  final num? quantity;
  final String? unit;
  final int? sequence;
  final String? status;
  final bool missingCoordinates;
  final double? distanceFromPreviousKm;
  final Map<String, dynamic> meta;

  const RouteStopData({
    this.stopType,
    this.refDoctype,
    this.refName,
    this.label,
    this.latitude,
    this.longitude,
    this.quantity,
    this.unit,
    this.sequence,
    this.status,
    this.missingCoordinates = false,
    this.distanceFromPreviousKm,
    this.meta = const {},
  });

  bool get isDispatchStop => refDoctype == 'Dispatch Route Stop';

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      !(latitude == 0 && longitude == 0);

  bool get isPending => (status ?? 'Pending') == 'Pending';

  String? get routeId {
    final id = meta['route_id'];
    return id?.toString();
  }

  String? get paymentTag {
    final tag = meta['payment_tag'];
    return tag?.toString();
  }

  num? get totalPrice => meta['total_price'] is num
      ? meta['total_price'] as num
      : num.tryParse('${meta['total_price']}');

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  factory RouteStopData.fromJson(Map<String, dynamic> json) {
    return RouteStopData(
      stopType: json['stop_type']?.toString(),
      refDoctype: json['ref_doctype']?.toString(),
      refName: json['ref_name']?.toString(),
      label: json['label']?.toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      quantity: json['quantity'] is num
          ? json['quantity'] as num
          : num.tryParse('${json['quantity']}'),
      unit: json['unit']?.toString(),
      sequence: json['sequence'] is int
          ? json['sequence'] as int
          : int.tryParse('${json['sequence']}'),
      status: json['status']?.toString(),
      missingCoordinates: json['missing_coordinates'] == true,
      distanceFromPreviousKm: _toDouble(json['distance_from_previous_km']),
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : const {},
    );
  }

  static List<RouteStopData> listFromJson(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map>()
        .map((e) => RouteStopData.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// Header info of the driver's active admin-composed Dispatch Route.
class DispatchRouteInfo {
  final String? name;
  final String? mode;
  final String? status;
  final String? notes;
  final int? totalStops;
  final int? pendingStops;

  const DispatchRouteInfo({
    this.name,
    this.mode,
    this.status,
    this.notes,
    this.totalStops,
    this.pendingStops,
  });

  factory DispatchRouteInfo.fromJson(Map<String, dynamic> json) {
    return DispatchRouteInfo(
      name: json['name']?.toString(),
      mode: json['mode']?.toString(),
      status: json['status']?.toString(),
      notes: json['notes']?.toString(),
      totalStops: int.tryParse('${json['total_stops']}'),
      pendingStops: int.tryParse('${json['pending_stops']}'),
    );
  }
}

/// Response of `get_my_dispatch_route`: header + resolved, ordered stops.
class DispatchRouteResponse {
  final DispatchRouteInfo? route;
  final List<RouteStopData> stops;

  const DispatchRouteResponse({this.route, this.stops = const []});

  factory DispatchRouteResponse.fromJson(dynamic json) {
    if (json is! Map) return const DispatchRouteResponse();
    final route = json['route'];
    return DispatchRouteResponse(
      route: route is Map
          ? DispatchRouteInfo.fromJson(Map<String, dynamic>.from(route))
          : null,
      stops: RouteStopData.listFromJson(json['stops']),
    );
  }
}
