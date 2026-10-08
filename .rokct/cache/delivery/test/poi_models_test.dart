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

// The POI shapes, read the way the server sends them.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * A CREATE THAT ANSWERS AN EXISTING POINT IS NOT A NEW PIN.
//     `duplicate_of` is what says so, and `wasAlreadyThere` is the only
//     thing a screen should ask.
//   * THE KIND OF PLACE HAS ONE NAME. The server strikes `type_label` (the
//     driver's own words for the catch-all type, the type itself
//     otherwise) so the map pin, the list row and the sheet cannot
//     disagree; the model prefers it and falls back in a fixed order.
//   * EVERY FIELD TOLERATES ABSENCE. A shell whose serializer has not
//     caught up degrades to a blank, never to a crash.
//   * THE SALES HISTORY'S COUNT IS THE SERVER'S. It may exceed the listed
//     rows, so it is never recomputed from them.
//   * WHO RUNS THE PLACE IS READ, AND WHICH ACCOUNT IS NOT DECIDED HERE.
//     The owner's name, his number and the account the server linked all
//     come off the row; nothing on this side invents one.
//   * A PLACE THAT IS A BUSINESS NEEDS AN OWNER. The kinds that do are the
//     server's own list, mirrored on the type.

import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _pointJson({
  String name = 'POI-1',
  String type = 'spaza shop',
}) =>
    {
      'name': name,
      'label': 'Corner spaza',
      'type': type,
      'custom_type': null,
      'type_label': type,
      'latitude': -26.1076,
      'longitude': 28.0567,
      'address': '12 Main Road',
      'note': 'Ask at the back',
      'shop': 'SHOP-1',
      'owner_name': 'Thandi Mokoena',
      'owner_phone': '+27000000000',
      'owner_user': 'owner-0000000000000000@place-owner.invalid',
      'is_platform_wide': 0,
      'created_by_deliveryman': 'driver@example.com',
      'active': 1,
      'distance_km': 0.412,
    };

void main() {
  group('DriverPoi', () {
    test('reads the whole row the driver surface answers', () {
      final point = DriverPoi.fromJson(_pointJson());
      expect(point.id, 'POI-1');
      expect(point.label, 'Corner spaza');
      expect(point.ownerName, 'Thandi Mokoena');
      expect(point.ownerPhone, '+27000000000');
      expect(
        point.ownerUser,
        'owner-0000000000000000@place-owner.invalid',
      );
      expect(point.type, 'spaza shop');
      expect(point.address, '12 Main Road');
      expect(point.note, 'Ask at the back');
      expect(point.shopId, 'SHOP-1');
      expect(point.isPlatformWide, isFalse);
      expect(point.createdByDeliveryman, 'driver@example.com');
      expect(point.active, isTrue);
      expect(point.distanceKm, closeTo(0.412, 0.0001));
      expect(point.hasCoordinates, isTrue);
      expect(point.wasAlreadyThere, isFalse);
    });

    test('a point that already stood there says so', () {
      final point = DriverPoi.fromJson({
        ..._pointJson(),
        'duplicate_of': 'POI-1',
      });
      expect(point.duplicateOf, 'POI-1');
      expect(point.wasAlreadyThere, isTrue);
    });

    test('the kind prefers the servers own label', () {
      final point = DriverPoi.fromJson({
        ..._pointJson(type: 'other'),
        'custom_type': 'taxi rank',
        'type_label': 'taxi rank',
      });
      expect(point.kind, 'taxi rank');
    });

    test('the kind falls back to the typed words then to the type', () {
      final noLabel = DriverPoi.fromJson({
        ..._pointJson(type: 'other'),
        'custom_type': 'taxi rank',
        'type_label': null,
      });
      expect(noLabel.kind, 'taxi rank');
      final bare = DriverPoi.fromJson({
        ..._pointJson(),
        'custom_type': null,
        'type_label': null,
      });
      expect(bare.kind, 'spaza shop');
    });

    test('a nameless point titles itself by kind, then by id', () {
      final byKind = DriverPoi.fromJson({
        ..._pointJson(),
        'label': null,
      });
      expect(byKind.title, 'spaza shop');
      final byId = DriverPoi.fromJson({'name': 'POI-9'});
      expect(byId.title, 'POI-9');
    });

    test('a blank row degrades rather than crashing', () {
      final point = DriverPoi.fromJson(const {});
      expect(point.id, '');
      expect(point.label, isNull);
      expect(point.hasCoordinates, isFalse);
      // A row that never mentioned `active` is not a deactivated point.
      expect(point.active, isTrue);
    });

    test('the null island is not a coordinate', () {
      final point = DriverPoi.fromJson({
        ..._pointJson(),
        'latitude': 0,
        'longitude': 0,
      });
      expect(point.hasCoordinates, isFalse);
    });

    test('the platform-wide flag reads the string a form call sends', () {
      expect(
        DriverPoi.fromJson({..._pointJson(), 'is_platform_wide': '1'})
            .isPlatformWide,
        isTrue,
      );
      expect(
        DriverPoi.fromJson({..._pointJson(), 'is_platform_wide': '0'})
            .isPlatformWide,
        isFalse,
      );
    });

    test('a list arrives out of any of the envelopes', () {
      for (final body in <dynamic>[
        [_pointJson()],
        {'data': [_pointJson()]},
        {'message': {'data': [_pointJson()]}},
      ]) {
        expect(DriverPoi.listFrom(body), hasLength(1));
      }
    });

    test('a nameless row is dropped from a list rather than listed blank',
        () {
      final points = DriverPoi.listFrom([_pointJson(), const {}]);
      expect(points, hasLength(1));
      expect(points.single.id, 'POI-1');
    });

    test('one point out of an envelope, and nothing out of an empty one', () {
      expect(DriverPoi.oneFrom({'data': _pointJson()})?.id, 'POI-1');
      expect(DriverPoi.oneFrom(const {'data': {}}), isNull);
      expect(DriverPoi.oneFrom(null), isNull);
    });
  });

  group('DriverPoiType', () {
    test('reads the vocabulary row, including what it is shown to', () {
      final types = DriverPoiType.listFrom({
        'data': [
          {
            'name': 'spaza shop',
            'location_type_name': 'spaza shop',
            'takes_custom_type': 0,
            'customer_visible': 1,
          },
          {
            'name': 'other',
            'location_type_name': 'other',
            'takes_custom_type': 1,
            'customer_visible': 0,
          },
        ],
      });
      expect(types.map((t) => t.id), ['spaza shop', 'other']);
      expect(types.first.customerVisible, isTrue);
      expect(types.first.takesCustomType, isFalse);
      expect(types.last.takesCustomType, isTrue);
      expect(types.last.customerVisible, isFalse);
    });

    test('the kinds that are a business are the kinds that need an owner',
        () {
      // Mirrored from the server's OWNER_REQUIRED_POI_TYPES, matched on the
      // Location Type docname exactly as the server matches it.
      expect(
        DriverPoiType.ownerRequiredIds,
        {'spaza shop', 'stockist', 'other'},
      );
      for (final id in const ['spaza shop', 'stockist', 'other']) {
        expect(DriverPoiType.fromJson({'name': id}).needsOwner, isTrue,
            reason: id);
      }
      // A landmark and a gate are nobody's.
      for (final id in const ['landmark', 'gate', 'taxi rank']) {
        expect(DriverPoiType.fromJson({'name': id}).needsOwner, isFalse,
            reason: id);
      }
    });

    test('a type with no title reads as its own name', () {
      final type = DriverPoiType.fromJson(const {'name': 'taxi rank'});
      expect(type.label, 'taxi rank');
    });

    test('a nameless type is dropped', () {
      expect(DriverPoiType.listFrom(const [{}]), isEmpty);
    });
  });

  group('DriverPoiSales', () {
    test('reads the point, the rows and the three figures', () {
      final sales = DriverPoiSales.fromJson({
        'data': {
          'poi': _pointJson(),
          'sales': [
            {
              'name': 'ORD-1',
              'creation': '2026-09-17 08:00:00',
              'total_price': 45,
              'deliveryman': 'driver@example.com',
              'user': 'buyer@example.com',
              'payment_status': 'paid',
            },
            {'name': 'ORD-2', 'total_price': '55'},
          ],
          'count': 2,
          'total': 100,
          'last_visit': '2026-09-17 08:00:00',
        },
      });
      expect(sales.poi?.id, 'POI-1');
      expect(sales.sales, hasLength(2));
      expect(sales.sales.first.orderId, 'ORD-1');
      expect(sales.sales.first.paymentStatus, 'paid');
      expect(sales.sales.last.total, 55);
      expect(sales.count, 2);
      expect(sales.total, 100);
      expect(sales.lastVisit, '2026-09-17 08:00:00');
      expect(sales.hasHistory, isTrue);
    });

    test('a point with no history is an empty history, not a blank point',
        () {
      final sales = DriverPoiSales.fromJson({
        'data': {
          'poi': _pointJson(),
          'sales': <dynamic>[],
          'count': 0,
          'total': 0,
          'last_visit': null,
        },
      });
      expect(sales.poi?.label, 'Corner spaza');
      expect(sales.hasHistory, isFalse);
      expect(sales.total, 0);
    });

    test('the count is the servers own, not the length of the page', () {
      final sales = DriverPoiSales.fromJson({
        'data': {
          'sales': [
            {'name': 'ORD-1', 'total_price': 45},
          ],
          'count': 7,
        },
      });
      expect(sales.count, 7);
      expect(sales.sales, hasLength(1));
    });
  });

  group('DriverPoiOwner', () {
    test('reads who the number belongs to and how many places he runs', () {
      final owner = DriverPoiOwner.fromJson({
        'data': {
          'found': 1,
          'first_name': 'Thandi',
          'last_name': 'Mokoena',
          'places_count': 4,
        },
      });
      expect(owner.found, isTrue);
      expect(owner.firstName, 'Thandi');
      expect(owner.lastName, 'Mokoena');
      expect(owner.fullName, 'Thandi Mokoena');
      expect(owner.placesCount, 4);
    });

    test('a number nobody holds reads as nobody, not as a blank person', () {
      final owner = DriverPoiOwner.fromJson({
        'data': {
          'found': 0,
          'first_name': null,
          'last_name': null,
          'places_count': 0,
        },
      });
      expect(owner.found, isFalse);
      expect(owner.fullName, isEmpty);
      expect(owner.placesCount, 0);
    });

    test('an account with only a first name still has a name', () {
      final owner = DriverPoiOwner.fromJson({
        'data': {'found': true, 'first_name': 'Thandi', 'places_count': 1},
      });
      expect(owner.fullName, 'Thandi');
    });

    test('an empty envelope is nobody rather than a crash', () {
      final owner = DriverPoiOwner.fromJson(const {});
      expect(owner.found, isFalse);
      expect(owner.placesCount, 0);
    });
  });

  group('DriverPoiFiling', () {
    test('a filed point is a point and asks nothing', () {
      final filing = DriverPoiFiling.filed(DriverPoi.fromJson(_pointJson()));
      expect(filing.point?.id, 'POI-1');
      expect(filing.ownerClash, isNull);
      expect(filing.needsOwnerConfirmation, isFalse);
    });

    test('an owner clash is a question and carries no point', () {
      const filing = DriverPoiFiling.ownerClash(
        DriverPoiOwnerClash(firstName: 'Thandi', detail: 'on file'),
      );
      expect(filing.point, isNull);
      expect(filing.needsOwnerConfirmation, isTrue);
      expect(filing.ownerClash!.firstName, 'Thandi');
      // The class name is what the repository matches on, never English.
      expect(DriverPoiOwnerClash.excType, 'PoiOwnerMismatch');
    });
  });

  group('DriverPoiShopChoices', () {
    // Ray, 2026-09-18: "driver doesnt own a shop, he either deliver for
    // every shop in the platform or specific ones if choosen". Two states,
    // and this shape has to be able to say which.
    test('a chosen list of one is settled and needs no asking', () {
      final choices = DriverPoiShopChoices.fromJson({
        'data': {
          'shops': [
            {'name': 'SHOP-1', 'shop_name': 'Depot North'},
          ],
          'unrestricted': 0,
        },
      });
      expect(choices.unrestricted, isFalse);
      expect(choices.isSettled, isTrue);
      expect(choices.needsChoosing, isFalse);
      expect(choices.only?.label, 'Depot North');
    });

    test('several shops need choosing between, unrestricted or not', () {
      for (final unrestricted in const [0, 1]) {
        final choices = DriverPoiShopChoices.fromJson({
          'data': {
            'shops': [
              {'name': 'SHOP-1', 'shop_name': 'Depot North'},
              {'name': 'SHOP-2', 'shop_name': 'Depot South'},
            ],
            'unrestricted': unrestricted,
          },
        });
        expect(choices.needsChoosing, isTrue);
        expect(choices.isSettled, isFalse);
        expect(choices.only, isNull);
      }
    });

    test('a nameless row falls back to its id and a blank one is dropped',
        () {
      final choices = DriverPoiShopChoices.fromJson({
        'data': {
          'shops': [
            {'name': 'SHOP-1'},
            {'shop_name': 'Nameless'},
          ],
        },
      });
      expect(choices.shops.single.id, 'SHOP-1');
      expect(choices.shops.single.label, 'SHOP-1');
    });

    test('an answer with no shops key is an empty offer, not a crash', () {
      final choices = DriverPoiShopChoices.fromJson({'data': {}});
      expect(choices.shops, isEmpty);
      expect(choices.needsChoosing, isFalse);
      expect(choices.isSettled, isFalse);
      expect(choices.unrestricted, isFalse);
    });

    test('the flag is read the way every other check is', () {
      for (final truthy in const [1, '1', true, 'true', 'yes']) {
        expect(
          DriverPoiShopChoices.fromJson({
            'data': {'shops': [], 'unrestricted': truthy},
          }).unrestricted,
          isTrue,
          reason: 'unrestricted: $truthy',
        );
      }
      expect(
        DriverPoiShopChoices.fromJson({
          'data': {'shops': [], 'unrestricted': 0},
        }).unrestricted,
        isFalse,
      );
    });
  });
}
