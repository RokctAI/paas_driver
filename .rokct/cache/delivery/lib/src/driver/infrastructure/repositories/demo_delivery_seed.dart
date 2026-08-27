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

import 'package:base_sdk/src/constants/app_constants.dart';

/// Shared seed data for the delivery demo repositories
/// (`--dart-define=IS_DEMO=true` builds only — DemoLmsRepository precedent).
///
/// Everything here is obviously fictional: "Demo" names, `@demo.rokct.ai` /
/// `@example.com` addresses, `+27 10 000 xxxx` phone numbers and coordinates
/// derived from the app's configured demo anchor (`AppConstants.demoLatitude`
/// / `demoLongitude`, the same fallback the courier home map already
/// centres on) — never a real person or a real person's location.
///
/// Payload maps deliberately mirror the shapes the HTTP repositories parse
/// (`OrderDetailData.fromJson`, `ParcelOrder.fromJson`,
/// `RouteStopData.fromJson`, `DeliveryResponse.fromJson`), so the demo path
/// exercises the exact same model code as production.
///
/// A tiny in-memory status overlay makes the demo interactive: accepting,
/// delivering or cancelling an order/parcel updates the overlay, so the
/// lists re-sort themselves the way the real backend would for the rest of
/// the session. Never persisted; resets on every launch.
class DemoDeliverySeed {
  DemoDeliverySeed._();

  /// Demo map anchor. Falls back to a generic Johannesburg city-centre
  /// coordinate when the host build did not define DEMO_LATITUDE /
  /// DEMO_LONGITUDE (AppConstants parses those defines eagerly and throws
  /// on absence).
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

  // ---------------------------------------------------------------------
  // Session-local status overlays (order id -> status). Seed statuses live
  // in _orders/_parcels below; demo actions mutate these maps only.
  // ---------------------------------------------------------------------
  static final Map<String, String> orderStatusOverlay = {};
  static final Map<String, String> parcelStatusOverlay = {};

  /// The order the driver is currently working (home-map bottom sheet).
  /// Ids are strings, like real Frappe Order docnames.
  static String? currentOrderId = '900001';
  static String? currentParcelId;

  static void reset() {
    orderStatusOverlay.clear();
    parcelStatusOverlay.clear();
    currentOrderId = '900001';
    currentParcelId = null;
  }

  static String _iso(Duration ago) =>
      DateTime.now().subtract(ago).toIso8601String();

  static String _date(Duration ago) {
    final d = DateTime.now().subtract(ago);
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------
  // Building blocks
  // ---------------------------------------------------------------------

  static Map<String, dynamic> currency() => {
        'id': 1,
        'symbol': 'R',
        'title': 'ZAR',
        'rate': 1,
        'active': true,
      };

  static Map<String, dynamic> _location(double dLat, double dLng) => {
        'latitude': '${anchorLatitude + dLat}',
        'longitude': '${anchorLongitude + dLng}',
      };

  static Map<String, dynamic> _shop({
    required int id,
    required String title,
    required String address,
    required double dLat,
    required double dLng,
  }) =>
      {
        'id': id,
        'uuid': 'demo-shop-$id',
        'user_id': 9000,
        'price': 25,
        'price_per_km': 6,
        'tax': 15,
        'phone': '+27 10 000 0400',
        'visibility': true,
        'background_img': null,
        'logo_img': null,
        'min_amount': 50,
        'status': 'approved',
        'type': 'shop',
        'delivery_time': {'from': '15', 'to': '45', 'type': 'minute'},
        'location': _location(dLat, dLng),
        'translation': {
          'id': id,
          'locale': 'en',
          'title': title,
          'description': 'Fictional demo merchant — not a real business.',
          'address': address,
        },
        'locales': ['en'],
      };

  static Map<String, dynamic> shopDemoDiner() => _shop(
        id: 9101,
        title: 'Demo Diner',
        address: '1 Placeholder Plaza, Demoville',
        dLat: 0.0042,
        dLng: -0.0031,
      );

  static Map<String, dynamic> shopSampleSpaza() => _shop(
        id: 9102,
        title: 'Sample Spaza',
        address: '7 Fictional Road, Demoville',
        dLat: -0.0058,
        dLng: 0.0049,
      );

  static Map<String, dynamic> _customer({
    required int id,
    required String firstname,
    required String lastname,
    required String phoneSuffix,
  }) =>
      {
        'id': id,
        'uuid': 'demo-user-$id',
        'firstname': firstname,
        'lastname': lastname,
        'email':
            '${firstname.toLowerCase()}.${lastname.toLowerCase()}@example.com',
        'phone': '+27 10 000 $phoneSuffix',
        'active': true,
        'img': null,
        'role': 'user',
      };

  static Map<String, dynamic> customerThandi() => _customer(
      id: 8101, firstname: 'Thandi', lastname: 'Demo', phoneSuffix: '0101');

  static Map<String, dynamic> customerSipho() => _customer(
      id: 8102, firstname: 'Sipho', lastname: 'Example', phoneSuffix: '0102');

  static Map<String, dynamic> customerLerato() => _customer(
      id: 8103, firstname: 'Lerato', lastname: 'Sample', phoneSuffix: '0103');

  static Map<String, dynamic> _detail({
    required int id,
    required int orderId,
    required String product,
    required num price,
    required int quantity,
  }) =>
      {
        'id': id,
        // Order docnames are strings on the wire.
        'order_id': '$orderId',
        'stock_id': id,
        'origin_price': price,
        'total_price': price * quantity,
        'tax': 0,
        'discount': 0,
        'quantity': quantity,
        'bonus': false,
        'stock': {
          'id': id,
          'countable_id': id,
          'price': price,
          'quantity': quantity,
          'tax': 0,
          'total_price': price * quantity,
          'product': {
            'id': id,
            'uuid': 'demo-product-$id',
            'shop_id': 9101,
            'active': true,
            'img': null,
            'translation': {
              'id': id,
              'locale': 'en',
              'title': product,
            },
            'locales': ['en'],
          },
        },
      };

  static Map<String, dynamic> _transaction({
    required int orderId,
    required num price,
    required String tag,
    required String status,
  }) =>
      {
        'id': orderId + 50000,
        'payable_id': orderId,
        'price': price,
        'note': 'demo transaction',
        'status': status,
        'created_at': _iso(const Duration(hours: 1)),
        'payment_system': {'id': tag == 'cash' ? 1 : 2, 'tag': tag, 'active': true},
      };

  // ---------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------

  /// Base order seeds. `status` here is the seed value; the overlay (demo
  /// accept/deliver/cancel actions) wins when present.
  static List<Map<String, dynamic>> _orders() => [
        // The driver's current job: collected from Demo Diner, cash on
        // delivery so the COD confirmation flow has something to show.
        {
          'id': '900001',
          'user_id': 8101,
          'total_price': 189.90,
          'origin_price': 164.90,
          'service_fee': 0,
          'tax': 10,
          'delivery_fee': 15,
          'commission_fee': 0,
          'status': 'accepted',
          'current': true,
          'km': 3.2,
          'otp': 4321,
          'note': 'Gate code 1234 — demo note.',
          'location': _location(0.0121, 0.0084),
          'address': {
            'address': '12 Fictional Lane, Demoville',
            'house': '12',
            'office': null,
            'floor': null,
          },
          'delivery_type': 'delivery',
          'delivery_date': _date(Duration.zero),
          'delivery_time': '13:30',
          'created_at': _iso(const Duration(minutes: 42)),
          'updated_at': _iso(const Duration(minutes: 12)),
          'shop': shopDemoDiner(),
          'currency': currency(),
          'user': customerThandi(),
          'details': [
            _detail(
                id: 700011,
                orderId: 900001,
                product: 'Family Feast Combo',
                price: 74.95,
                quantity: 2),
            _detail(
                id: 700012,
                orderId: 900001,
                product: 'Sparkling Demo Cooldrink',
                price: 15.00,
                quantity: 1),
          ],
          'transaction': _transaction(
              orderId: 900001, price: 189.90, tag: 'cash', status: 'progress'),
        },
        {
          'id': '900002',
          'user_id': 8102,
          'total_price': 74.50,
          'origin_price': 59.50,
          'service_fee': 0,
          'tax': 5,
          'delivery_fee': 10,
          'commission_fee': 0,
          'status': 'ready',
          'current': false,
          'km': 1.8,
          'otp': 8765,
          'location': _location(-0.0093, 0.0117),
          'address': {
            'address': '34 Example Avenue, Demoville',
            'house': '34',
            'office': null,
            'floor': null,
          },
          'delivery_type': 'delivery',
          'delivery_date': _date(Duration.zero),
          'delivery_time': '14:15',
          'created_at': _iso(const Duration(minutes: 25)),
          'updated_at': _iso(const Duration(minutes: 8)),
          'shop': shopSampleSpaza(),
          'currency': currency(),
          'user': customerSipho(),
          'details': [
            _detail(
                id: 700021,
                orderId: 900002,
                product: 'Demo Deli Sandwich',
                price: 49.50,
                quantity: 1),
            _detail(
                id: 700022,
                orderId: 900002,
                product: 'Fruit Juice (Sample)',
                price: 10.00,
                quantity: 1),
          ],
          'transaction': _transaction(
              orderId: 900002, price: 74.50, tag: 'wallet', status: 'paid'),
        },
        // Available: ready, no deliveryman assigned yet.
        {
          'id': '900101',
          'user_id': 8103,
          'total_price': 129.00,
          'origin_price': 109.00,
          'service_fee': 0,
          'tax': 8,
          'delivery_fee': 12,
          'status': 'ready',
          'current': false,
          'km': 2.4,
          'deliveryman': null,
          'location': _location(0.0066, -0.0102),
          'address': {
            'address': '56 Sample Street, Demoville',
            'house': '56',
            'office': '2B',
            'floor': '2',
          },
          'delivery_type': 'delivery',
          'delivery_date': _date(Duration.zero),
          'delivery_time': '15:00',
          'created_at': _iso(const Duration(minutes: 9)),
          'updated_at': _iso(const Duration(minutes: 9)),
          'shop': shopDemoDiner(),
          'currency': currency(),
          'user': customerLerato(),
          'details': [
            _detail(
                id: 701011,
                orderId: 900101,
                product: 'Placeholder Pizza (Large)',
                price: 109.00,
                quantity: 1),
          ],
          'transaction': _transaction(
              orderId: 900101, price: 129.00, tag: 'cash', status: 'progress'),
        },
        {
          'id': '900102',
          'user_id': 8101,
          'total_price': 245.40,
          'origin_price': 215.40,
          'service_fee': 0,
          'tax': 12,
          'delivery_fee': 18,
          'status': 'ready',
          'current': false,
          'km': 4.7,
          'deliveryman': null,
          'location': _location(-0.0138, -0.0059),
          'address': {
            'address': '78 Demo Drive, Demoville',
            'house': '78',
            'office': null,
            'floor': null,
          },
          'delivery_type': 'delivery',
          'delivery_date': _date(Duration.zero),
          'delivery_time': '15:30',
          'created_at': _iso(const Duration(minutes: 4)),
          'updated_at': _iso(const Duration(minutes: 4)),
          'shop': shopSampleSpaza(),
          'currency': currency(),
          'user': customerThandi(),
          'details': [
            _detail(
                id: 701021,
                orderId: 900102,
                product: 'Weekly Groceries Box (Demo)',
                price: 215.40,
                quantity: 1),
          ],
          'transaction': _transaction(
              orderId: 900102, price: 245.40, tag: 'wallet', status: 'paid'),
        },
        // History: delivered earlier this week.
        {
          'id': '899901',
          'user_id': 8102,
          'total_price': 96.00,
          'origin_price': 84.00,
          'tax': 4,
          'delivery_fee': 8,
          'status': 'delivered',
          'current': false,
          'km': 2.1,
          'location': _location(0.0035, 0.0022),
          'delivery_type': 'delivery',
          'delivery_date': _date(const Duration(days: 1)),
          'delivery_time': '12:10',
          'created_at': _iso(const Duration(days: 1, hours: 3)),
          'updated_at': _iso(const Duration(days: 1, hours: 2)),
          'shop': shopDemoDiner(),
          'currency': currency(),
          'user': customerSipho(),
          'details': [
            _detail(
                id: 699011,
                orderId: 899901,
                product: 'Breakfast Basket (Demo)',
                price: 84.00,
                quantity: 1),
          ],
          'transaction': _transaction(
              orderId: 899901, price: 96.00, tag: 'cash', status: 'paid'),
        },
        {
          'id': '899902',
          'user_id': 8103,
          'total_price': 158.75,
          'origin_price': 138.75,
          'tax': 8,
          'delivery_fee': 12,
          'status': 'delivered',
          'current': false,
          'km': 3.9,
          'location': _location(-0.0044, 0.0091),
          'delivery_type': 'delivery',
          'delivery_date': _date(const Duration(days: 2)),
          'delivery_time': '17:45',
          'created_at': _iso(const Duration(days: 2, hours: 5)),
          'updated_at': _iso(const Duration(days: 2, hours: 4)),
          'shop': shopSampleSpaza(),
          'currency': currency(),
          'user': customerLerato(),
          'details': [
            _detail(
                id: 699021,
                orderId: 899902,
                product: 'Dinner-for-Two (Sample)',
                price: 138.75,
                quantity: 1),
          ],
          'transaction': _transaction(
              orderId: 899902, price: 158.75, tag: 'wallet', status: 'paid'),
        },
      ];

  /// All order maps with the session overlay applied.
  static List<Map<String, dynamic>> orders() => _orders().map((o) {
        final id = o['id'] as String;
        final overlay = orderStatusOverlay[id];
        if (overlay != null) o['status'] = overlay;
        o['current'] = id == currentOrderId;
        return o;
      }).toList();

  static Map<String, dynamic>? orderById(String id) {
    for (final o in orders()) {
      if (o['id'] == id) return o;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Parcels
  // ---------------------------------------------------------------------

  static Map<String, dynamic> _parcelType() => {
        'id': '1',
        'type': 'Documents',
        'img': null,
        'price': 30,
        'price_per_km': 5,
      };

  static List<Map<String, dynamic>> _parcels() => [
        {
          'id': '77001',
          'user_id': '8101',
          'total_price': 45,
          'status': 'accepted',
          'note': 'Signed demo contracts — handle flat.',
          'phone_from': '+27 10 000 0101',
          'username_from': 'Thandi Demo',
          'phone_to': '+27 10 000 0102',
          'username_to': 'Sipho Example',
          'address_from': {
            'address': '1 Placeholder Plaza, Demoville',
            'latitude': anchorLatitude + 0.0042,
            'longitude': anchorLongitude - 0.0031,
          },
          'address_to': {
            'address': '34 Example Avenue, Demoville',
            'latitude': anchorLatitude - 0.0093,
            'longitude': anchorLongitude + 0.0117,
          },
          'type_id': '1',
          'delivery_fee': 45,
          'delivery_date': _date(Duration.zero),
          'delivery_time': '16:00',
          'current': false,
          'created_at': _iso(const Duration(minutes: 55)),
          'updated_at': _iso(const Duration(minutes: 20)),
          'km': 2.6,
          'currency': currency(),
          'user': customerThandi(),
          'type': _parcelType(),
        },
        {
          'id': '77101',
          'user_id': '8103',
          'total_price': 60,
          'status': 'ready',
          'note': 'Birthday gift — demo parcel.',
          'phone_from': '+27 10 000 0103',
          'username_from': 'Lerato Sample',
          'phone_to': '+27 10 000 0101',
          'username_to': 'Thandi Demo',
          'address_from': {
            'address': '56 Sample Street, Demoville',
            'latitude': anchorLatitude + 0.0066,
            'longitude': anchorLongitude - 0.0102,
          },
          'address_to': {
            'address': '12 Fictional Lane, Demoville',
            'latitude': anchorLatitude + 0.0121,
            'longitude': anchorLongitude + 0.0084,
          },
          'type_id': '1',
          'delivery_fee': 60,
          'delivery_date': _date(Duration.zero),
          'delivery_time': '17:30',
          'current': false,
          'created_at': _iso(const Duration(minutes: 15)),
          'updated_at': _iso(const Duration(minutes: 15)),
          'km': 3.4,
          'currency': currency(),
          'user': customerLerato(),
          'type': _parcelType(),
        },
        {
          'id': '76901',
          'user_id': '8102',
          'total_price': 38,
          'status': 'delivered',
          'phone_from': '+27 10 000 0102',
          'username_from': 'Sipho Example',
          'phone_to': '+27 10 000 0103',
          'username_to': 'Lerato Sample',
          'address_from': {
            'address': '34 Example Avenue, Demoville',
            'latitude': anchorLatitude - 0.0093,
            'longitude': anchorLongitude + 0.0117,
          },
          'address_to': {
            'address': '56 Sample Street, Demoville',
            'latitude': anchorLatitude + 0.0066,
            'longitude': anchorLongitude - 0.0102,
          },
          'type_id': '1',
          'delivery_fee': 38,
          'delivery_date': _date(const Duration(days: 1)),
          'delivery_time': '11:20',
          'current': false,
          'created_at': _iso(const Duration(days: 1, hours: 6)),
          'updated_at': _iso(const Duration(days: 1, hours: 5)),
          'km': 1.9,
          'currency': currency(),
          'user': customerSipho(),
          'type': _parcelType(),
        },
      ];

  static List<Map<String, dynamic>> parcels() => _parcels().map((p) {
        final id = p['id'] as String;
        final overlay = parcelStatusOverlay[id];
        if (overlay != null) p['status'] = overlay;
        p['current'] = id == currentParcelId;
        return p;
      }).toList();

  static Map<String, dynamic>? parcelById(String id) {
    for (final p in parcels()) {
      if (p['id'] == id) return p;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Route (dispatch)
  // ---------------------------------------------------------------------

  static Map<String, dynamic> _stop({
    required int sequence,
    required String stopType,
    required String refDoctype,
    required String refName,
    required String label,
    required double dLat,
    required double dLng,
    num? quantity,
    String? unit,
    String status = 'Pending',
    double? distanceKm,
    Map<String, dynamic> meta = const {},
  }) =>
      {
        'sequence': sequence,
        'stop_type': stopType,
        'ref_doctype': refDoctype,
        'ref_name': refName,
        'label': label,
        'latitude': anchorLatitude + dLat,
        'longitude': anchorLongitude + dLng,
        'quantity': quantity,
        'unit': unit,
        'status': status,
        'missing_coordinates': false,
        'distance_from_previous_km': distanceKm,
        'meta': meta,
      };

  static List<Map<String, dynamic>> routeStops() => [
        _stop(
          sequence: 1,
          stopType: 'Pickup',
          refDoctype: 'Dispatch Route Stop',
          refName: 'DRS-DEMO-0001',
          label: 'Demo Diner — collect 2 orders',
          dLat: 0.0042,
          dLng: -0.0031,
          quantity: 2,
          unit: 'orders',
          distanceKm: 1.2,
          meta: {'route_id': 'DR-DEMO-0001'},
        ),
        _stop(
          sequence: 2,
          stopType: 'Delivery',
          refDoctype: 'Order',
          refName: '900001',
          label: 'Thandi Demo — 12 Fictional Lane',
          dLat: 0.0121,
          dLng: 0.0084,
          quantity: 1,
          unit: 'order',
          distanceKm: 2.4,
          meta: {
            'route_id': 'DR-DEMO-0001',
            'payment_tag': 'cash',
            'total_price': 189.90,
          },
        ),
        _stop(
          sequence: 3,
          stopType: 'Delivery',
          refDoctype: 'Order',
          refName: '900002',
          label: 'Sipho Example — 34 Example Avenue',
          dLat: -0.0093,
          dLng: 0.0117,
          quantity: 1,
          unit: 'order',
          distanceKm: 3.1,
          meta: {'route_id': 'DR-DEMO-0001', 'payment_tag': 'wallet'},
        ),
        _stop(
          sequence: 4,
          stopType: 'Delivery',
          refDoctype: 'Parcel Order',
          refName: '77001',
          label: 'Parcel — Sipho Example, 34 Example Avenue',
          dLat: -0.0090,
          dLng: 0.0119,
          quantity: 1,
          unit: 'parcel',
          distanceKm: 0.3,
          meta: {'route_id': 'DR-DEMO-0001'},
        ),
      ];

  static Map<String, dynamic> dispatchRoute() => {
        'route': {
          'name': 'DR-DEMO-0001',
          'mode': 'Delivery',
          'status': 'In Progress',
          'notes': 'Demo dispatch route — four fictional stops.',
          'total_stops': 4,
          'pending_stops': 4,
        },
        'stops': routeStops(),
      };

  // ---------------------------------------------------------------------
  // Courier profile / vehicle
  // ---------------------------------------------------------------------

  static Map<String, dynamic> driverDetails() => {
        'timestamp': _iso(Duration.zero),
        'status': true,
        'message': 'OK',
        'data': {
          'id': 7001,
          'user_id': 8001,
          'type_of_technique': 'motorbike',
          'brand': 'Demo Motors',
          'model': 'Runabout 125',
          'number': 'DEMO 123 GP',
          'color': 'Green',
          'width': '60',
          'height': '110',
          'kg': '12',
          'length': '190',
          'price': 25,
          'price_per_km': 6,
          'online': true,
          'location': _location(0, 0),
          'created_at': _iso(const Duration(days: 180)),
          'updated_at': _iso(const Duration(hours: 2)),
          'deliveryMan': {
            'id': 8001,
            'uuid': 'demo-driver-8001',
            'firstname': 'Dumi',
            'lastname': 'Driver',
            'email': 'driver@demo.rokct.ai',
            'phone': '+27 10 000 0200',
            'active': true,
            'img': null,
            'role': 'deliveryman',
          },
          'galleries': [],
        },
      };

  static List<Map<String, dynamic>> vehicleTypes() => [
        {
          'id': 1,
          'key': 'bicycle',
          'name': 'Bicycle',
          'max_weight_kg': 8,
          'base_rate': 15,
          'description': 'Light and quick around the block.',
          'active': true,
          'sort_order': 1,
        },
        {
          'id': 2,
          'key': 'motorbike',
          'name': 'Motorbike',
          'max_weight_kg': 20,
          'base_rate': 25,
          'description': 'The everyday courier workhorse.',
          'active': true,
          'sort_order': 2,
        },
        {
          'id': 3,
          'key': 'car',
          'name': 'Car',
          'max_weight_kg': 80,
          'base_rate': 40,
          'description': 'Bigger loads and longer trips.',
          'active': true,
          'sort_order': 3,
        },
      ];

  static Map<String, dynamic> deliverymanSettings() => {
        'can_convert_cod_to_credit': 1,
      };

  static Map<String, dynamic> profileData() => {
        'id': 8001,
        'uuid': 'demo-driver-8001',
        'firstname': 'Dumi',
        'lastname': 'Driver',
        'email': 'driver@demo.rokct.ai',
        'phone': '+27 10 000 0200',
        'active': true,
        'img': null,
        'role': 'deliveryman',
      };

  /// A tight fictional polygon around the demo anchor — the courier's zone
  /// on the home map.
  static List<List<double>> deliveryZone() => [
        [anchorLatitude + 0.030, anchorLongitude - 0.030],
        [anchorLatitude + 0.030, anchorLongitude + 0.030],
        [anchorLatitude - 0.030, anchorLongitude + 0.030],
        [anchorLatitude - 0.030, anchorLongitude - 0.030],
        [anchorLatitude + 0.030, anchorLongitude - 0.030],
      ];
}
