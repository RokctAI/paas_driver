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

// Gateway contract for the driver's point-of-interest calls. They travel
// the universal platform gateway under map's own `api.poi.*` aliases.
// These tests pin the cmds, the payload keys and the envelope the answers
// are read out of — the four things a backend rename would break silently.
//
// AND THEY PIN WHAT IS NOT SENT. There is no `is_platform_wide` key, no
// `created_by_deliveryman` key and no `owner_user` key on the create call,
// because the server takes all three from the session, the driver's
// admin-set profile and the owner's own number. A key added here later
// would be ignored server-side; it would still be a lie about who decides,
// so the absence is asserted.
//
// AND ONE ERROR THAT IS NOT AN ERROR. The server answers a number held
// under another first name with its own exception class, which is a
// question for the driver rather than a failure; these pin that it is read
// off the response by EXCEPTION TYPE and answered as a value.

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:delivery_sdk/src/driver/domain/interface/route.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/poi_repository.dart';
import 'package:delivery_sdk/src/driver/infrastructure/repositories/route_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/recording_http_service.dart';

T _data<T>(ApiResult<T> result) => switch (result) {
      Success(:final data) => data,
      Failure(:final error) => throw StateError('unexpected failure: $error'),
    };

String _error<T>(ApiResult<T> result) => switch (result) {
      Success() => throw StateError('unexpected success'),
      Failure(:final error) => error,
    };

Map<String, dynamic> _pointRow({String name = 'POI-1'}) => {
      'name': name,
      'label': 'Corner spaza',
      'type': 'spaza shop',
      'type_label': 'spaza shop',
      'latitude': -26.1076,
      'longitude': 28.0567,
      'shop': 'SHOP-1',
      'is_platform_wide': 0,
      'active': 1,
    };

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  group('types', () {
    test('posts api.poi.get_poi_types and types the vocabulary', () async {
      final http = RecordingHttpService.install((_) => {
            'data': [
              {
                'name': 'spaza shop',
                'location_type_name': 'spaza shop',
                'takes_custom_type': 0,
                'customer_visible': 1,
              },
            ],
          });

      final types = _data(await DriverPoiRepository().types());

      final request = http.single;
      expect(request.method, 'POST');
      expect(request.path, kPlatformGatewayPath);
      expect(request.cmd, 'api.poi.get_poi_types');
      expect(types.single.id, 'spaza shop');
      expect(types.single.customerVisible, isTrue);
    });
  });

  group('nearby', () {
    test('posts the position and reads the points', () async {
      final http = RecordingHttpService.install((_) => {
            'data': [_pointRow()],
          });

      final points = _data(
        await DriverPoiRepository().nearby(
          latitude: -26.1076,
          longitude: 28.0567,
          radiusKm: 1.5,
        ),
      );

      final request = http.single;
      expect(request.cmd, 'api.poi.get_nearby_pois');
      expect(request.payload!['latitude'], -26.1076);
      expect(request.payload!['longitude'], 28.0567);
      expect(request.payload!['radius_km'], 1.5);
      expect(points.single.id, 'POI-1');
    });

    test('a filterless read sends no filter keys at all', () async {
      final http = RecordingHttpService.install((_) => {'data': []});

      await DriverPoiRepository()
          .nearby(latitude: -26.1, longitude: 28.0, type: '  ', shop: '');

      expect(http.single.payload!.containsKey('poi_type'), isFalse);
      expect(http.single.payload!.containsKey('shop'), isFalse);
      expect(http.single.payload!.containsKey('radius_km'), isFalse);
    });

    test('a filtered read sends the trimmed filter', () async {
      final http = RecordingHttpService.install((_) => {'data': []});

      await DriverPoiRepository().nearby(
        latitude: -26.1,
        longitude: 28.0,
        type: '  spaza shop  ',
        shop: ' SHOP-1 ',
      );

      expect(http.single.payload!['poi_type'], 'spaza shop');
      expect(http.single.payload!['shop'], 'SHOP-1');
    });

    test('nothing filed here is an empty list, not a failure', () async {
      RecordingHttpService.install((_) => {'data': []});
      expect(
        _data(await DriverPoiRepository()
            .nearby(latitude: -26.1, longitude: 28.0)),
        isEmpty,
      );
    });
  });

  group('my shops', () {
    test('posts api.poi.get_my_poi_shops and reads the shops he delivers '
        'for', () async {
      final http = RecordingHttpService.install((_) => {
            'data': {
              'shops': [
                {'name': 'SHOP-1', 'shop_name': 'Depot North'},
                {'name': 'SHOP-2', 'shop_name': 'Depot South'},
              ],
              'unrestricted': 0,
            },
          });

      final choices = _data(await DriverPoiRepository().myShops());

      expect(http.single.cmd, 'api.poi.get_my_poi_shops');
      // It asks on nobody's behalf: the session IS the driver.
      expect(http.single.payload, isNull);
      expect(choices.unrestricted, isFalse);
      expect(choices.needsChoosing, isTrue);
      expect(choices.shops.map((shop) => shop.id), ['SHOP-1', 'SHOP-2']);
      expect(choices.shops.first.label, 'Depot North');
    });

    test('unrestricted means the list IS every shop', () async {
      RecordingHttpService.install((_) => {
            'data': {
              'shops': [
                {'name': 'SHOP-1', 'shop_name': 'Depot North'},
              ],
              'unrestricted': 1,
            },
          });

      final choices = _data(await DriverPoiRepository().myShops());
      expect(choices.unrestricted, isTrue);
      // One shop is still one shop: nothing to choose between.
      expect(choices.isSettled, isTrue);
      expect(choices.only?.id, 'SHOP-1');
    });

    test('a shop with no display name answers its own id', () async {
      RecordingHttpService.install((_) => {
            'data': {
              'shops': [
                {'name': 'SHOP-1'},
              ],
            },
          });

      final choices = _data(await DriverPoiRepository().myShops());
      expect(choices.shops.single.label, 'SHOP-1');
      expect(choices.unrestricted, isFalse);
    });
  });

  group('create', () {
    test('posts what the driver typed and nothing he cannot decide',
        () async {
      final http = RecordingHttpService.install((_) => {
            'data': _pointRow(),
          });

      final filing = _data(
        await DriverPoiRepository().create(
          label: '  Corner spaza  ',
          type: ' spaza shop ',
          latitude: -26.1076,
          longitude: 28.0567,
          note: '  ask at the back  ',
        ),
      );

      final payload = http.single.payload!;
      expect(http.single.cmd, 'api.poi.create_poi');
      expect(payload['label'], 'Corner spaza');
      expect(payload['type'], 'spaza shop');
      expect(payload['latitude'], -26.1076);
      expect(payload['longitude'], 28.0567);
      expect(payload['note'], 'ask at the back');
      // The two the server owns are not on the wire at all.
      expect(payload.containsKey('is_platform_wide'), isFalse);
      expect(payload.containsKey('created_by_deliveryman'), isFalse);
      // Nor is a custom type the driver did not type.
      expect(payload.containsKey('custom_type'), isFalse);
      // Nor an owner he named nobody for, nor a confirmation he never gave.
      expect(payload.containsKey('owner_first_name'), isFalse);
      expect(payload.containsKey('owner_phone'), isFalse);
      expect(payload.containsKey('owner_confirmed_user'), isFalse);
      // And there is no argument for WHICH ACCOUNT the owner is at all.
      expect(payload.containsKey('owner_user'), isFalse);
      expect(filing.point!.id, 'POI-1');
    });

    test('the catch-all types own words ride along when typed', () async {
      final http = RecordingHttpService.install((_) => {'data': _pointRow()});

      await DriverPoiRepository().create(
        label: 'Back entrance',
        type: 'other',
        latitude: -26.1,
        longitude: 28.0,
        customType: '  taxi rank  ',
      );

      expect(http.single.payload!['custom_type'], 'taxi rank');
    });

    test('a point that already stood there comes back as a selection',
        () async {
      RecordingHttpService.install((_) => {
            'data': {..._pointRow(), 'duplicate_of': 'POI-1'},
          });

      final filing = _data(
        await DriverPoiRepository().create(
          label: 'Corner spaza shop',
          type: 'spaza shop',
          latitude: -26.1076,
          longitude: 28.0567,
        ),
      );

      expect(filing.point!.wasAlreadyThere, isTrue);
      expect(filing.point!.duplicateOf, 'POI-1');
    });

    test('an empty answer is a failure, not a nameless pin', () async {
      RecordingHttpService.install((_) => {'data': {}});

      final result = await DriverPoiRepository().create(
        label: 'Corner spaza',
        type: 'spaza shop',
        latitude: -26.1,
        longitude: 28.0,
      );

      expect(_error(result), isNotEmpty);
    });
  });

  group('the place owner', () {
    test('the three owner keys ride along, trimmed', () async {
      final http = RecordingHttpService.install((_) => {'data': _pointRow()});

      await DriverPoiRepository().create(
        label: 'Corner spaza',
        type: 'spaza shop',
        latitude: -26.1,
        longitude: 28.0,
        ownerFirstName: '  Thandi  ',
        ownerLastName: '  Mokoena  ',
        ownerPhone: '  +27000000000  ',
      );

      final payload = http.single.payload!;
      expect(payload['owner_first_name'], 'Thandi');
      expect(payload['owner_last_name'], 'Mokoena');
      expect(payload['owner_phone'], '+27000000000');
      // Not confirmed is ABSENT, not a zero: nobody has been asked yet.
      expect(payload.containsKey('owner_confirmed_user'), isFalse);
    });

    test('the confirmation only travels once he has given it', () async {
      final http = RecordingHttpService.install((_) => {'data': _pointRow()});

      await DriverPoiRepository().create(
        label: 'Corner spaza',
        type: 'spaza shop',
        latitude: -26.1,
        longitude: 28.0,
        ownerFirstName: 'Sipho',
        ownerPhone: '+27000000000',
        ownerConfirmedUser: true,
      );

      expect(http.single.payload!['owner_confirmed_user'], 1);
    });

    test('the owner clash comes back as a question, not a failure',
        () async {
      RecordingHttpService.install((_) => throw gatewayError({
            'exc_type': 'PoiOwnerMismatch',
            'exception': 'paas.map.tenant.api.poi.poi.PoiOwnerMismatch: '
                'That number is already on file under Thandi. If this is '
                'the same person, confirm it.',
          }));

      final filing = _data(
        await DriverPoiRepository().create(
          label: 'Corner spaza',
          type: 'spaza shop',
          latitude: -26.1,
          longitude: 28.0,
          ownerFirstName: 'Sipho',
          ownerPhone: '+27000000000',
        ),
      );

      expect(filing.needsOwnerConfirmation, isTrue);
      expect(filing.point, isNull);
      // The name on file is what the dialog has to say.
      expect(filing.ownerClash!.firstName, 'Thandi');
    });

    test('the clash is recognised by its exception type, not its words',
        () async {
      RecordingHttpService.install((_) => throw gatewayError({
            'exc_type': 'PoiOwnerMismatch',
            'message': 'Hierdie nommer is al op rekord.',
          }));

      final filing = _data(
        await DriverPoiRepository().create(
          label: 'Corner spaza',
          type: 'spaza shop',
          latitude: -26.1,
          longitude: 28.0,
          ownerFirstName: 'Sipho',
          ownerPhone: '+27000000000',
        ),
      );

      // A sentence in another language still asks the question; it just
      // cannot name anybody.
      expect(filing.needsOwnerConfirmation, isTrue);
      expect(filing.ownerClash!.firstName, isNull);
    });

    test('any other refusal is still a failure', () async {
      RecordingHttpService.install((_) => throw gatewayError({
            'exc_type': 'ValidationError',
            'message': 'A point of interest needs a name.',
          }));

      final result = await DriverPoiRepository().create(
        label: '',
        type: 'spaza shop',
        latitude: -26.1,
        longitude: 28.0,
      );

      expect(_error(result), isNotEmpty);
    });

    test('lookupOwner posts api.poi.lookup_poi_owner and reads the answer',
        () async {
      final http = RecordingHttpService.install((_) => {
            'data': {
              'found': 1,
              'first_name': 'Thandi',
              'last_name': 'Mokoena',
              'places_count': 3,
            },
          });

      final owner = _data(
        await DriverPoiRepository().lookupOwner(phone: '  +27000000000  '),
      );

      expect(http.single.cmd, 'api.poi.lookup_poi_owner');
      expect(http.single.payload!['phone'], '+27000000000');
      expect(owner.found, isTrue);
      expect(owner.fullName, 'Thandi Mokoena');
      expect(owner.placesCount, 3);
    });

    test('a number nobody holds reads as not found', () async {
      RecordingHttpService.install((_) => {
            'data': {
              'found': 0,
              'first_name': null,
              'last_name': null,
              'places_count': 0,
            },
          });

      final owner = _data(
        await DriverPoiRepository().lookupOwner(phone: '+27000000000'),
      );

      expect(owner.found, isFalse);
      expect(owner.fullName, isEmpty);
      expect(owner.placesCount, 0);
    });
  });

  group('route', () {
    test('posts api.poi.get_poi_route and types the stops', () async {
      final http = RecordingHttpService.install((_) => [
            {
              'stop_type': 'dropoff',
              'ref_doctype': 'Point Of Interest',
              'ref_name': 'POI-1',
              'label': 'Corner spaza',
              'latitude': -26.1076,
              'longitude': 28.0567,
              'sequence': 1,
              'meta': {'type': 'spaza shop'},
            },
          ]);

      final stops = _data(
        await DriverPoiRepository().route(
          latitude: -26.1076,
          longitude: 28.0567,
        ),
      );

      expect(http.single.cmd, 'api.poi.get_poi_route');
      expect(stops.single.refDoctype, 'Point Of Interest');
      expect(stops.single.sequence, 1);
      expect(stops.single.meta['type'], 'spaza shop');
    });

    test('a positionless route sends no coordinates', () async {
      final http = RecordingHttpService.install((_) => const []);
      await DriverPoiRepository().route();
      expect(http.single.payload!.containsKey('latitude'), isFalse);
      expect(http.single.payload!.containsKey('longitude'), isFalse);
    });
  });

  group('sales', () {
    test('posts the point and reads the history', () async {
      final http = RecordingHttpService.install((_) => {
            'data': {
              'poi': _pointRow(),
              'sales': [
                {'name': 'ORD-1', 'total_price': 45},
              ],
              'count': 1,
              'total': 45,
              'last_visit': '2026-09-17 08:00:00',
            },
          });

      final sales = _data(
        await DriverPoiRepository().sales(poi: 'POI-1'),
      );

      expect(http.single.cmd, 'api.poi.get_poi_sales');
      expect(http.single.payload!['poi'], 'POI-1');
      expect(http.single.payload!['limit'], 50);
      expect(sales.count, 1);
      expect(sales.total, 45);
      expect(sales.poi?.label, 'Corner spaza');
    });
  });

  group('the route list reads two sources through one repository', () {
    test('the day work asks map driver_order', () async {
      final http = RecordingHttpService.install((_) => const []);
      await CourierRouteRepository()
          .getDriverRoute(latitude: -26.1, longitude: 28.0);
      expect(http.single.cmd, 'api.driver_order.get_driver_route');
    });

    test('the places ask map poi, with the same payload', () async {
      final http = RecordingHttpService.install((_) => const []);
      await CourierRouteRepository().getDriverRoute(
        latitude: -26.1,
        longitude: 28.0,
        source: DriverRouteSource.pois,
      );
      expect(http.single.cmd, 'api.poi.get_poi_route');
      expect(http.single.payload!['latitude'], -26.1);
      expect(http.single.payload!['longitude'], 28.0);
    });
  });
}
