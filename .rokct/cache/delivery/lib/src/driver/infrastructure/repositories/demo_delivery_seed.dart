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

import 'package:base_sdk/src/constants/app_constants.dart';

/// What is left of the driver demo seed after demo moved onto the REAL
/// repositories and base_sdk's DemoGatewayInterceptor (every platform cmd
/// is answered from `templates/assets/demo/delivery/<cmd>.json`).
///
/// Only the calls that are NOT platform-gateway cmds stay here, because the
/// interceptor answers `POST /api/v1/method/rokct.platform.api` only:
/// the legacy REST vehicle-type list (`GET /api/v1/rest/delivery-vehicle-types`)
/// and the legacy parcel marketplace (`GET /api/v1/dashboard/deliveryman/
/// parcel-orders/paginate` and `.../parcel-orders<id>`). The real
/// repositories answer those from here while `DemoSession.demoActive`.
/// Also the demo map anchor, which the pinned demo location reads.
class DemoDeliverySeed {
  DemoDeliverySeed._();

  /// Demo map anchor. Falls back to a generic Johannesburg city-centre
  /// coordinate when the build did not define DEMO_LATITUDE / DEMO_LONGITUDE
  /// (AppConstants parses those defines eagerly and throws on absence). The
  /// gateway fixtures are laid out around that fallback.
  static double get anchorLatitude {
    try {
      return AppConstants.demoLatitude;
    } catch (_) {
      return -26.2041;
    }
  }

  static double get anchorLongitude {
    try {
      return AppConstants.demoLongitude;
    } catch (_) {
      return 28.0473;
    }
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();

  /// `GET /api/v1/rest/delivery-vehicle-types` rows.
  static List<Map<String, dynamic>> vehicleTypes() => [
    {
      "id": 1,
      "key": "bicycle",
      "name": "Bicycle",
      "max_weight_kg": 8,
      "base_rate": 15,
      "description": "Light and quick around the block.",
      "active": true,
      "sort_order": 1,
    },
    {
      "id": 2,
      "key": "motorbike",
      "name": "Motorbike",
      "max_weight_kg": 20,
      "base_rate": 25,
      "description": "The everyday courier workhorse.",
      "active": true,
      "sort_order": 2,
    },
    {
      "id": 3,
      "key": "car",
      "name": "Car",
      "max_weight_kg": 80,
      "base_rate": 40,
      "description": "Bigger loads and longer trips.",
      "active": true,
      "sort_order": 3,
    },
  ];

  /// The legacy parcel marketplace: ready parcels with no courier yet.
  static List<Map<String, dynamic>> availableParcels() => [
        {
          "id": "77101",
          "user_id": "8103",
          "total_price": 60,
          "status": "ready",
          "note": "Birthday gift, handle with care.",
          "phone_from": "+27 10 000 0103",
          "username_from": "Lerato Mahlangu",
          "phone_to": "+27 10 000 0101",
          "username_to": "Thandi Nkosi",
          "address_from": {
            "address": "56 Rivonia Road, Sandton",
            "latitude": -26.1975,
            "longitude": 28.0371,
          },
          "address_to": {
            "address": "12 Cradock Avenue, Rosebank",
            "latitude": -26.192,
            "longitude": 28.0557,
          },
          "type_id": "1",
          "delivery_fee": 60,
          "delivery_date": _now(),
          "delivery_time": "17:30",
          "current": false,
          "created_at": _now(),
          "updated_at": _now(),
          "km": 3.4,
          "currency": {
            "id": 1,
            "symbol": "R",
            "title": "ZAR",
            "rate": 1,
            "active": true,
          },
          "user": {
            "id": 8103,
            "uuid": "demo-user-8103",
            "firstname": "Lerato",
            "lastname": "Mahlangu",
            "email": "lerato.mahlangu@rokct.ai",
            "phone": "+27 10 000 0103",
            "active": true,
            "img": null,
            "role": "user",
          },
          "type": {
            "id": "1",
            "type": "Documents",
            "img": null,
            "price": 30,
            "price_per_km": 5,
          },
        },
      ];

  /// A parcel by id, across the marketplace and the courier's own parcels.
  static Map<String, dynamic>? parcelById(String id) {
    for (final p in [...availableParcels(), ..._ownParcels()]) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  static List<Map<String, dynamic>> _ownParcels() => [
    {
      "id": "77001",
      "user_id": "8101",
      "total_price": 45,
      "status": "accepted",
      "note": "Signed contracts, keep flat.",
      "phone_from": "+27 10 000 0101",
      "username_from": "Thandi Nkosi",
      "phone_to": "+27 10 000 0102",
      "username_to": "Sipho Dlamini",
      "address_from": {
        "address": "42 Marula Avenue, Sandton",
        "latitude": -26.1999,
        "longitude": 28.0442,
      },
      "address_to": {
        "address": "34 Jan Smuts Avenue, Rosebank",
        "latitude": -26.2134,
        "longitude": 28.059,
      },
      "type_id": "1",
      "delivery_fee": 45,
      "delivery_date": _now(),
      "delivery_time": "16:00",
      "current": false,
      "created_at": _now(),
      "updated_at": _now(),
      "km": 2.6,
      "currency": {
        "id": 1,
        "symbol": "R",
        "title": "ZAR",
        "rate": 1,
        "active": true,
      },
      "user": {
        "id": 8101,
        "uuid": "demo-user-8101",
        "firstname": "Thandi",
        "lastname": "Nkosi",
        "email": "thandi.nkosi@rokct.ai",
        "phone": "+27 10 000 0101",
        "active": true,
        "img": null,
        "role": "user",
      },
      "type": {
        "id": "1",
        "type": "Documents",
        "img": null,
        "price": 30,
        "price_per_km": 5,
      },
    },
    {
      "id": "76901",
      "user_id": "8102",
      "total_price": 38,
      "status": "delivered",
      "phone_from": "+27 10 000 0102",
      "username_from": "Sipho Dlamini",
      "phone_to": "+27 10 000 0103",
      "username_to": "Lerato Mahlangu",
      "address_from": {
        "address": "34 Jan Smuts Avenue, Rosebank",
        "latitude": -26.2134,
        "longitude": 28.059,
      },
      "address_to": {
        "address": "56 Rivonia Road, Sandton",
        "latitude": -26.1975,
        "longitude": 28.0371,
      },
      "type_id": "1",
      "delivery_fee": 38,
      "delivery_date": _now(),
      "delivery_time": "11:20",
      "current": false,
      "created_at": _now(),
      "updated_at": _now(),
      "km": 1.9,
      "currency": {
        "id": 1,
        "symbol": "R",
        "title": "ZAR",
        "rate": 1,
        "active": true,
      },
      "user": {
        "id": 8102,
        "uuid": "demo-user-8102",
        "firstname": "Sipho",
        "lastname": "Dlamini",
        "email": "sipho.dlamini@rokct.ai",
        "phone": "+27 10 000 0102",
        "active": true,
        "img": null,
        "role": "user",
      },
      "type": {
        "id": "1",
        "type": "Documents",
        "img": null,
        "price": 30,
        "price_per_km": 5,
      },
    },
  ];
}
