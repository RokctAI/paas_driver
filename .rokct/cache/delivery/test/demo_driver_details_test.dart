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

// The demo driver-details fixture is parsed by the SAME model the HTTP
// path uses (base_sdk's DeliveryResponse), and that model assigns most
// String? fields straight through with no toString() normalisation. A
// number where the model declares String? therefore does not degrade —
// it throws "type 'int' is not a subtype of type 'String?'" inside
// Data.fromJson, which is exactly how the guided tour lost the driver
// home (`price: 25` / `price_per_km: 6`) and, with it, every later step.
//
// The per-key type sweep below is the point of this file: asserting only
// the two fields that broke would let the NEXT mistyped key reach a
// build. Every key the model reads is checked against the type the model
// declares, so a fixture edit that reintroduces the shape fails here
// instead of at driver_home initState.

import 'package:base_sdk/src/models/response/driver_show_response.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_courier_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/demo_delivery_seed.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keys base_sdk's `Data` declares as `String?` and assigns straight from
/// the map (no `toString()` in `Data.fromJson`), so the fixture must
/// already carry a String.
const _dataStringKeys = <String>[
  'type_of_technique',
  'brand',
  'model',
  'number',
  'color',
  'price',
  'price_per_km',
  'created_at',
  'updated_at',
];

/// Keys `Data` declares as `int?`.
const _dataIntKeys = <String>['id', 'user_id'];

/// Keys `DeliveryMan` declares as `String?`, likewise unnormalised.
const _deliveryManStringKeys = <String>[
  'uuid',
  'firstname',
  'lastname',
  'email',
  'phone',
  'img',
  'role',
  'email_verified_at',
  'registered_at',
];

void _expectNullOr<T>(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    expect(
      value,
      anyOf(isNull, isA<T>()),
      reason: '$key is ${value.runtimeType}, but the model declares $T? — '
          'a mismatch throws inside fromJson rather than degrading',
    );
  }
}

void main() {
  group('DemoDeliverySeed.driverDetails', () {
    test('every key matches the type the model declares', () {
      final payload = DemoDeliverySeed.driverDetails();
      _expectNullOr<String>(payload, ['timestamp', 'message']);
      expect(payload['status'], isA<bool>());

      final data = Map<String, dynamic>.from(payload['data'] as Map);
      _expectNullOr<String>(data, _dataStringKeys);
      _expectNullOr<int>(data, _dataIntKeys);
      // width/height/kg/length ARE normalised by the model, so they are
      // not swept here; the seed still states them as strings.

      final deliveryMan = Map<String, dynamic>.from(data['deliveryMan'] as Map);
      _expectNullOr<String>(deliveryMan, _deliveryManStringKeys);
      _expectNullOr<int>(deliveryMan, ['id']);
    });

    test('parses through DeliveryResponse.fromJson without throwing', () {
      final response =
          DeliveryResponse.fromJson(DemoDeliverySeed.driverDetails());

      expect(response.status, isTrue);
      final data = response.data;
      expect(data, isNotNull);
      // The two fields that used to arrive as ints.
      expect(data!.price, '25');
      expect(data.pricePerKm, '6');
      // ...and the neighbours that must keep working.
      expect(data.id, 7001);
      expect(data.typeOfTechnique, 'motorbike');
      expect(data.width, '60');
      expect(data.online, isTrue);
      expect(data.location?.latitude, isA<String>());
      expect(data.deliveryMan?.firstname, 'Dumi');
      expect(data.galleries, isEmpty);
    });
  });

  group('DemoCourierRepository', () {
    test('getDriverDetails resolves instead of throwing', () async {
      final result = await DemoCourierRepository().getDriverDetails();

      result.when(
        success: (response) {
          expect(response.data?.price, '25');
          expect(response.data?.pricePerKm, '6');
        },
        failure: (error, statusCode) =>
            fail('demo driver details failed: $error'),
      );
    });

    test('editCarInfo re-parses the mutated fixture', () async {
      final result = await DemoCourierRepository().editCarInfo(
        type: 'car',
        brand: 'Demo Motors',
        model: 'Hauler 300',
        number: 'DEMO 456 GP',
        color: 'Blue',
        height: '150',
        weight: '40',
        length: '400',
        width: '180',
      );

      result.when(
        success: (response) {
          expect(response.data?.model, 'Hauler 300');
          expect(response.data?.price, '25');
        },
        failure: (error, statusCode) => fail('demo editCarInfo failed: $error'),
      );
    });
  });
}
