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

// Points of interest as the driver sees them.
//
// The route SHELLS live in `templates/` and only compile inside a composed
// host, so what is pumped here is what those shells render: the SDK's own
// sheets and rows. Everything on the seam except the host-side map pins is
// therefore under test.
//
// What a later edit could quietly undo, and what each group pins:
//
//   * THE PLACE IS OPTIONAL ON A SALE and stays optional: the commit works
//     with nothing named, and the `poi` key only travels when he named one.
//   * A POINT THAT ALREADY STOOD THERE IS SELECTED, not reported as a
//     failure and not filed twice.
//   * THE CATCH-ALL TYPE ASKS FOR THE WORDS. The commit stays inert until
//     it has them, and a named type never shows the field.
//   * "no places around you" NEVER shows before the first answer.
//   * A NAMED PLACE DOES NOT RIDE ALONG to the next sale.
//   * WHO RUNS THE PLACE IS ASKED FOR, and asked for ONCE: an owner the
//     platform already holds for that number is filled in, not typed again.
//   * A PLACE THAT IS A BUSINESS WAITS FOR AN OWNER'S FIRST NAME; a
//     landmark and a gate do not.
//   * THE OWNER CLASH IS A QUESTION, NOT A FAILURE. The sheet asks whether
//     it is the same person and re-sends with the confirmation only on a
//     yes — and files nothing at all on a no.
//   * SELLING AT A PLACE HE IS NOT AT ASKS, AND NEVER BLOCKS.

import 'dart:async';

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:delivery_sdk/src/common/application/poi/poi_proximity.dart';
import 'package:delivery_sdk/src/driver/application/load/load_notifier.dart';
import 'package:delivery_sdk/src/driver/application/load/load_provider.dart';
import 'package:delivery_sdk/src/driver/application/poi/poi_notifier.dart';
import 'package:delivery_sdk/src/driver/application/poi/poi_provider.dart';
import 'package:delivery_sdk/src/driver/domain/interface/load.dart';
import 'package:delivery_sdk/src/driver/domain/interface/poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_load.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/driver_poi.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/route_stop.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_location_fix.dart';
import 'package:delivery_sdk/src/driver/presentation/home/add_place_card.dart';
import 'package:delivery_sdk/src/driver/presentation/load/driver_load_plane.dart';
import 'package:delivery_sdk/src/driver/presentation/load/load_sale_plane.dart';
import 'package:delivery_sdk/src/driver/presentation/poi/add_poi_sheet.dart';
import 'package:delivery_sdk/src/driver/presentation/poi/poi_selector.dart';
import 'package:delivery_sdk/src/driver/presentation/poi/poi_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

const _sandton = (-26.1076, 28.0567);

/// ~220 m north of [_sandton] — further off than the proximity rule lets a
/// sale go unquestioned, and close enough to be the next corner rather than
/// the next suburb.
const _twoHundredMetresOff = (-26.1056, 28.0567);

/// Obviously fake numbers. Nothing here dials anything.
const _ownerPhone = '+27000000000';

Map<String, dynamic> _ownerJson({
  bool found = true,
  String? firstName = 'Thandi',
  String? lastName = 'Mokoena',
  int placesCount = 3,
}) =>
    {
      'found': found ? 1 : 0,
      'first_name': firstName,
      'last_name': lastName,
      'places_count': placesCount,
    };

Map<String, dynamic> _loadJson({
  String id = 'LOAD-4',
  String shopId = 'SHOP-1',
  String shopTitle = 'Depot North',
}) => {
      'id': id,
      'shop': {'id': shopId, 'title': shopTitle},
      'load_status': 'Open',
      'lines': [
        {
          'item_id': 'LI-1',
          'stock_id': 'STK-1',
          'unit_price': 45,
          'issued_qty': 10,
          'sold_qty': 3,
          'returned_qty': 1,
          'remaining_qty': 6,
          'product': {
            'translation': {'title': 'Still water 5L'},
            'unit': {'translation': {'title': 'bottle'}},
          },
        },
      ],
    };

Map<String, dynamic> _pointJson({
  String name = 'POI-1',
  String label = 'Corner spaza',
  String type = 'spaza shop',
  String? customType,
  String? duplicateOf,
  double? distanceKm,
}) =>
    {
      'name': name,
      'label': label,
      'type': type,
      'custom_type': customType,
      'type_label': customType ?? type,
      'latitude': _sandton.$1,
      'longitude': _sandton.$2,
      'shop': 'SHOP-1',
      'is_platform_wide': 0,
      'active': 1,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (duplicateOf != null) 'duplicate_of': duplicateOf,
    };

/// The same point, standing somewhere the driver is not.
Map<String, dynamic> _farPointJson() => {
      ..._pointJson(name: 'POI-FAR', label: 'Next corner spaza'),
      'latitude': _twoHundredMetresOff.$1,
      'longitude': _twoHundredMetresOff.$2,
    };

DriverPoiShopChoices _choices(
  List<(String, String)> shops, {
  bool unrestricted = false,
}) =>
    DriverPoiShopChoices(
      shops: shops
          .map((row) => DriverPoiShop(id: row.$1, title: row.$2))
          .toList(growable: false),
      unrestricted: unrestricted,
    );

List<Map<String, dynamic>> _typeRows() => [
      {
        'name': 'spaza shop',
        'location_type_name': 'spaza shop',
        'takes_custom_type': 0,
        'customer_visible': 1,
      },
      {
        'name': 'gate',
        'location_type_name': 'gate',
        'takes_custom_type': 0,
        'customer_visible': 0,
      },
      {
        'name': 'other',
        'location_type_name': 'other',
        'takes_custom_type': 1,
        'customer_visible': 0,
      },
    ];

/// A repository that answers from memory, so the whole flow runs without a
/// server or a platform channel.
class _FakePoiRepository implements DriverPoiRepositoryFacade {
  _FakePoiRepository({this.points = const []});

  List<DriverPoi> points;

  /// Overridable so a test can hand the sheet a vocabulary of its own.
  List<DriverPoiType>? typeList;

  /// When set, `nearby` never answers — the state the driver is in for the
  /// first second of every entry, and the one the empty line must not
  /// appear in.
  Completer<void>? gate;

  /// What `create` answers with. A row carrying `duplicate_of` is the
  /// server saying the corner is already on the map.
  Map<String, dynamic> createAnswer = _pointJson(name: 'POI-NEW');
  bool createFails = false;

  /// When set, `create` answers the owner clash — the server refusing to
  /// rename the account that already holds the number — until it is sent
  /// `owner_confirmed_user`.
  DriverPoiOwnerClash? ownerClash;

  /// What `lookup_poi_owner` answers, and every number it was asked about.
  DriverPoiOwner ownerAnswer = const DriverPoiOwner();
  final List<String> ownerLookups = [];

  final List<Map<String, Object?>> creates = [];
  final List<String> salesReads = [];
  DriverPoiSales salesAnswer = const DriverPoiSales();

  /// What `get_my_poi_shops` answers. Empty and restricted is the state a
  /// driver on a load never has to leave.
  DriverPoiShopChoices shopChoices = const DriverPoiShopChoices();
  int myShopsReads = 0;

  @override
  Future<ApiResult<List<DriverPoiType>>> types() async => ApiResult.success(
        data: typeList ??
            _typeRows()
                .map(DriverPoiType.fromJson)
                .toList(growable: false),
      );

  @override
  Future<ApiResult<List<DriverPoi>>> nearby({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? type,
    String? shop,
  }) async {
    final held = gate;
    if (held != null) await held.future;
    return ApiResult.success(data: points);
  }

  @override
  Future<ApiResult<DriverPoiFiling>> create({
    required String label,
    required String type,
    required double latitude,
    required double longitude,
    String? customType,
    String? shop,
    String? address,
    String? note,
    String? ownerFirstName,
    String? ownerLastName,
    String? ownerPhone,
    bool ownerConfirmedUser = false,
  }) async {
    creates.add({
      'label': label,
      'type': type,
      'custom_type': customType,
      'note': note,
      'shop': shop,
      'latitude': latitude,
      'longitude': longitude,
      'owner_first_name': ownerFirstName,
      'owner_last_name': ownerLastName,
      'owner_phone': ownerPhone,
      'owner_confirmed_user': ownerConfirmedUser,
    });
    if (createFails) {
      return const ApiResult.failure(error: 'nope', statusCode: 417);
    }
    final clash = ownerClash;
    if (clash != null && !ownerConfirmedUser) {
      return ApiResult.success(data: DriverPoiFiling.ownerClash(clash));
    }
    return ApiResult.success(
      data: DriverPoiFiling.filed(DriverPoi.fromJson(createAnswer)),
    );
  }

  @override
  Future<ApiResult<DriverPoiOwner>> lookupOwner({
    required String phone,
  }) async {
    ownerLookups.add(phone);
    return ApiResult.success(data: ownerAnswer);
  }

  @override
  Future<ApiResult<DriverPoiShopChoices>> myShops() async {
    myShopsReads += 1;
    return ApiResult.success(data: shopChoices);
  }

  @override
  Future<ApiResult<List<RouteStopData>>> route({
    double? latitude,
    double? longitude,
    String? type,
    String? shop,
  }) async =>
      const ApiResult.success(data: <RouteStopData>[]);

  @override
  Future<ApiResult<DriverPoiSales>> sales({
    required String poi,
    int limit = 50,
  }) async {
    salesReads.add(poi);
    return ApiResult.success(data: salesAnswer);
  }
}

class _FakeLoadRepository implements DriverLoadRepositoryFacade {
  _FakeLoadRepository({this.loads = const []});

  List<DriverLoad> loads;

  /// (load order, lines, customer, note, point of interest).
  final List<(String, List<DriverLoadMovement>, String?, String?, String?)>
      sales = [];

  @override
  Future<ApiResult<List<DriverLoad>>> getMyLoad() async =>
      ApiResult.success(data: loads);

  @override
  Future<ApiResult<DriverLoadSale>> createLoadSale({
    required String loadOrder,
    required List<DriverLoadMovement> items,
    String? customer,
    String? note,
    String? poi,
  }) async {
    sales.add((loadOrder, items, customer, note, poi));
    return ApiResult.success(
      data: DriverLoadSale(
        orderId: 'ORD-77',
        load: DriverLoad.fromJson(_loadJson()),
      ),
    );
  }

  @override
  Future<ApiResult<DriverLoad>> returnLoad({
    required String loadOrder,
    required List<DriverLoadMovement> items,
  }) async =>
      ApiResult.success(data: DriverLoad.fromJson(_loadJson()));

  @override
  Future<ApiResult<DriverLoad>> closeLoad({required String loadOrder}) async =>
      ApiResult.success(data: DriverLoad.fromJson(_loadJson()));
}

/// A fix the driver's phone never had to produce.
Future<CourierLocationResult> _fix() async => CourierLocationResult.fix(
      Position(
        latitude: _sandton.$1,
        longitude: _sandton.$2,
        timestamp: DateTime(2026, 9, 18),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );

/// A phone that refused.
Future<CourierLocationResult> _noFix() async =>
    const CourierLocationResult.unavailable(
      denial: CourierLocationDenial.permissionDenied,
      detail: 'test: refused',
    );

DriverPoiNotifier _poiNotifier(
  _FakePoiRepository repository, {
  LocationFix? locationFix,
}) =>
    DriverPoiNotifier(
      repository,
      isOnline: () async => true,
      locationFix: locationFix ?? _fix,
    );

DriverLoadNotifier _loadNotifier(_FakeLoadRepository repository) =>
    DriverLoadNotifier(repository, isOnline: () async => true);

Widget _host(
  Widget child, {
  required DriverPoiNotifier poi,
  DriverLoadNotifier? load,
}) =>
    ProviderScope(
      overrides: [
        driverPoiProvider.overrideWith((ref) => poi),
        if (load != null) driverLoadProvider.overrideWith((ref) => load),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 900),
        // The sheets live inside showModalBottomSheet in production, which
        // is a Material; pumped bare they need one supplied.
        builder: (context, _) => MaterialApp(home: Material(child: child)),
      ),
    );

/// Every rendered string, joined, lower-cased.
String _allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n')
    .toLowerCase();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => AppStyle.isDark = true);

  void sizeUp(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Names whoever runs the place. A spaza shop, a stockist and the
  /// catch-all are businesses somebody runs, so the commit stays inert
  /// without this — the server's own rule, mirrored on the sheet.
  Future<void> nameOwner(
    WidgetTester tester, {
    String first = 'Thandi',
    String? last,
    String? phone,
  }) async {
    await tester.enterText(
      find.byKey(const Key('addPoiOwnerFirst')),
      first,
    );
    if (last != null) {
      await tester.enterText(find.byKey(const Key('addPoiOwnerLast')), last);
    }
    if (phone != null) {
      await tester.enterText(find.byKey(const Key('addPoiOwnerPhone')), phone);
    }
    await tester.pumpAndSettle();
  }

  group('add a place', () {
    testWidgets('the commit waits for a name and a kind', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository();
      final notifier = _poiNotifier(repository);
      await tester.pumpWidget(_host(const AddPoiSheet(), poi: notifier));
      await tester.pumpAndSettle();

      Widget commit() => tester.widget(find.byKey(const Key('addPoiConfirm')));
      expect((commit() as dynamic).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.pumpAndSettle();
      // A name is not enough: a place with no kind is not a place.
      expect((commit() as dynamic).onPressed, isNull);

      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await tester.pumpAndSettle();
      // Nor is a kind, when the kind is a business: a spaza shop with
      // nobody running it is a half-filed point.
      expect((commit() as dynamic).onPressed, isNull);

      await nameOwner(tester);
      expect((commit() as dynamic).onPressed, isNotNull);
    });

    testWidgets('the catch-all kind asks for the words and waits for them',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository();
      final notifier = _poiNotifier(repository);
      await tester.pumpWidget(_host(const AddPoiSheet(), poi: notifier));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Back entrance',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await tester.pumpAndSettle();
      // A named kind never shows the field.
      expect(find.byKey(const Key('addPoiCustomType')), findsNothing);

      await tester.tap(find.byKey(const Key('addPoiType-other')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addPoiCustomType')), findsOneWidget);
      // Named, so the WORDS are the only thing still missing.
      await nameOwner(tester);
      Widget commit() => tester.widget(find.byKey(const Key('addPoiConfirm')));
      expect((commit() as dynamic).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('addPoiCustomType')),
        'taxi rank',
      );
      await tester.pumpAndSettle();
      expect((commit() as dynamic).onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();
      expect(repository.creates.single['type'], 'other');
      expect(repository.creates.single['custom_type'], 'taxi rank');
    });

    testWidgets('it files at the drivers own fix and never asks for one',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository();
      final notifier = _poiNotifier(repository);
      await tester.pumpWidget(_host(const AddPoiSheet(), poi: notifier));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await nameOwner(tester);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();

      expect(repository.creates.single['latitude'], _sandton.$1);
      expect(repository.creates.single['longitude'], _sandton.$2);
      // No coordinate field anywhere: a point he typed is a point he was
      // not standing at.
      final text = _allText(tester);
      for (final forbidden in const ['latitude', 'longitude']) {
        expect(text, isNot(contains(forbidden)));
      }
    });

    testWidgets('it never offers the scope the server decides',
        (tester) async {
      sizeUp(tester);
      final notifier = _poiNotifier(_FakePoiRepository());
      await tester.pumpWidget(_host(const AddPoiSheet(), poi: notifier));
      await tester.pumpAndSettle();
      final text = _allText(tester);
      for (final forbidden in const [
        'platform wide',
        'platform-wide',
        'visible to every shop',
        'share with all shops',
      ]) {
        expect(text, isNot(contains(forbidden)));
      }
    });

    testWidgets('a point that already stood there is handed back, not filed '
        'twice', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..createAnswer = _pointJson(
          name: 'POI-1',
          label: 'Corner spaza',
          duplicateOf: 'POI-1',
        );
      final notifier = _poiNotifier(repository);
      DriverPoi? handedBack;
      await tester.pumpWidget(
        _host(
          AddPoiSheet(onFiled: (point) => handedBack = point),
          poi: notifier,
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza shop',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await nameOwner(tester);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();

      expect(repository.creates, hasLength(1));
      expect(handedBack?.id, 'POI-1');
      expect(handedBack?.wasAlreadyThere, isTrue);
      // And the slice has SELECTED it, so the sale that follows names it.
      expect(notifier.state.selected?.id, 'POI-1');
      expect(notifier.state.lastWasAlreadyThere, isTrue);
    });

    testWidgets('with no fix it says so and files nothing', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository();
      final notifier = _poiNotifier(repository, locationFix: _noFix);
      await tester.pumpWidget(_host(const AddPoiSheet(), poi: notifier));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await nameOwner(tester);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();

      expect(repository.creates, isEmpty);
    });
  });

  group('at this place - the sale', () {
    testWidgets('a sale with nothing named sends no place', (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      final load = _loadNotifier(loads);
      await load.load();
      final poi = _poiNotifier(_FakePoiRepository());
      await tester.pumpWidget(
        _host(const LoadSalePlane(loadOrder: 'LOAD-4'),
            poi: poi, load: load),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSaleConfirm')));
      await tester.pumpAndSettle();

      expect(loads.sales.single.$5, isNull);
    });

    testWidgets('the place he named rides the sale', (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      final load = _loadNotifier(loads);
      await load.load();
      final poi = _poiNotifier(
        _FakePoiRepository(
          points: [DriverPoi.fromJson(_pointJson(distanceKm: 0.012))],
        ),
      );
      await tester.pumpWidget(
        _host(const LoadSalePlane(loadOrder: 'LOAD-4'),
            poi: poi, load: load),
      );
      await tester.pumpAndSettle();

      // The row starts un-named, and says so rather than guessing.
      expect(find.byKey(const Key('loadSalePoi')), findsOneWidget);
      await tester.tap(find.byKey(const Key('loadSalePoiOpen')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('poiRow-POI-1')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('loadSalePoiValue'))).data,
        'Corner spaza',
      );

      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSaleConfirm')));
      await tester.pumpAndSettle();

      expect(loads.sales.single.$5, 'POI-1');
      // And it does not ride along to the next door.
      expect(poi.state.selected, isNull);
    });

    testWidgets('the named place can be cleared again', (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      final load = _loadNotifier(loads);
      await load.load();
      final poi = _poiNotifier(
        _FakePoiRepository(points: [DriverPoi.fromJson(_pointJson())]),
      );
      await tester.pumpWidget(
        _host(const LoadSalePlane(loadOrder: 'LOAD-4'),
            poi: poi, load: load),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSalePoiOpen')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('poiRow-POI-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSalePoiClear')));
      await tester.pumpAndSettle();

      expect(poi.state.selected, isNull);
    });

    testWidgets('the chooser never says there is nothing before the first '
        'answer', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()..gate = Completer<void>();
      final notifier = _poiNotifier(repository);
      await tester.pumpWidget(
        _host(const PoiSelectorRow(), poi: notifier),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('loadSalePoiOpen')));
      await tester.pump();

      final empty = tester.widget<Text>(find.byKey(const Key('poiPickerEmpty')));
      expect(empty.data, isNot(contains('Nothing on the map')));
    });

    testWidgets('a chooser with nothing in it offers to add the place',
        (tester) async {
      sizeUp(tester);
      final notifier = _poiNotifier(_FakePoiRepository());
      await tester.pumpWidget(_host(const PoiSelectorRow(), poi: notifier));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSalePoiOpen')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('poiPickerEmpty')), findsOneWidget);
      expect(find.byKey(const Key('poiPickerAdd')), findsOneWidget);
      await tester.tap(find.byKey(const Key('poiPickerAdd')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addPoiSheet')), findsOneWidget);
    });
  });

  group('the place, opened', () {
    testWidgets('a point with no sales says exactly that', (tester) async {
      sizeUp(tester);
      final point = DriverPoi.fromJson(_pointJson());
      final repository = _FakePoiRepository()
        ..salesAnswer = DriverPoiSales(poi: point);
      final notifier = _poiNotifier(repository);
      await tester.pumpWidget(
        _host(PoiSheet(point: point), poi: notifier),
      );
      await tester.pumpAndSettle();

      expect(repository.salesReads, ['POI-1']);
      expect(find.byKey(const Key('poiSheetNoSales')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('poiSheetTitle'))).data,
        'Corner spaza',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('poiSheetKind'))).data,
        'spaza shop',
      );
    });

    testWidgets('a point with sales shows the count, the total and the last '
        'visit', (tester) async {
      sizeUp(tester);
      final point = DriverPoi.fromJson(_pointJson());
      final repository = _FakePoiRepository()
        ..salesAnswer = DriverPoiSales.fromJson({
          'data': {
            'poi': _pointJson(),
            'sales': [
              {'name': 'ORD-1', 'total_price': 45},
              {'name': 'ORD-2', 'total_price': 55},
            ],
            'count': 2,
            'total': 100,
            'last_visit': '2026-09-17 08:00:00',
          },
        });
      final notifier = _poiNotifier(repository);
      await tester.pumpWidget(
        _host(PoiSheet(point: point), poi: notifier),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('poiSheetSalesTotals')), findsOneWidget);
      expect(find.byKey(const Key('poiSheetLastVisit')), findsOneWidget);
      expect(find.byKey(const Key('poiSheetNoSales')), findsNothing);
      expect(_allText(tester), contains('ord-1'));
    });

    testWidgets('the note the last driver left is shown to this one',
        (tester) async {
      sizeUp(tester);
      final point = DriverPoi.fromJson({
        ..._pointJson(),
        'note': 'Ask at the back',
      });
      final notifier = _poiNotifier(
        _FakePoiRepository()..salesAnswer = DriverPoiSales(poi: point),
      );
      await tester.pumpWidget(_host(PoiSheet(point: point), poi: notifier));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('poiSheetNote')), findsOneWidget);
    });
  });

  group('which shop the place is for', () {
    // Ray, 2026-09-18: "driver doesnt own a shop, he either deliver for
    // every shop in the platform or specific ones if choosen". So the sheet
    // asks only when the driver is the one who knows.

    Future<void> nameIt(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await nameOwner(tester);
    }

    testWidgets('one shop is filled in silently and never shown as a choice',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..shopChoices = _choices([('SHOP-1', 'Depot North')]);
      await tester.pumpWidget(
        _host(const AddPoiSheet(), poi: _poiNotifier(repository)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addPoiShopPicker')), findsNothing);
      await nameIt(tester);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();
      expect(repository.creates.single['shop'], 'SHOP-1');
    });

    testWidgets('several shops must be chosen between before it will file',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..shopChoices = _choices([
          ('SHOP-1', 'Depot North'),
          ('SHOP-2', 'Depot South'),
        ]);
      await tester.pumpWidget(
        _host(const AddPoiSheet(), poi: _poiNotifier(repository)),
      );
      await tester.pumpAndSettle();
      await nameIt(tester);

      expect(find.byKey(const Key('addPoiShopPicker')), findsOneWidget);
      Widget commit() => tester.widget(find.byKey(const Key('addPoiConfirm')));
      // Named and typed, but the shop is still nobody's guess.
      expect((commit() as dynamic).onPressed, isNull);

      await tester.tap(find.byKey(const Key('addPoiShop-SHOP-2')));
      await tester.pumpAndSettle();
      expect((commit() as dynamic).onPressed, isNotNull);

      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();
      expect(repository.creates.single['shop'], 'SHOP-2');
      expect(_allText(tester), contains('depot south'));
    });

    testWidgets('an unrestricted driver picks from the whole platform',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..shopChoices = _choices(
          [('SHOP-1', 'Depot North'), ('SHOP-2', 'Depot South')],
          unrestricted: true,
        );
      await tester.pumpWidget(
        _host(const AddPoiSheet(), poi: _poiNotifier(repository)),
      );
      await tester.pumpAndSettle();
      // Same picker, same tap: unrestricted changes what the list is OF,
      // not whether he is asked.
      expect(find.byKey(const Key('addPoiShopPicker')), findsOneWidget);
      expect(find.byKey(const Key('addPoiShop-SHOP-1')), findsOneWidget);
      expect(find.byKey(const Key('addPoiShop-SHOP-2')), findsOneWidget);
    });

    testWidgets('on a load there is no picker and no read for one',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..shopChoices = _choices([
          ('SHOP-1', 'Depot North'),
          ('SHOP-2', 'Depot South'),
        ]);
      await tester.pumpWidget(
        _host(
          const AddPoiSheet(shop: 'SHOP-7'),
          poi: _poiNotifier(repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addPoiShopPicker')), findsNothing);
      expect(repository.myShopsReads, 0);
      await nameIt(tester);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();
      expect(repository.creates.single['shop'], 'SHOP-7');
    });

    testWidgets('the sell screens place row carries the loads own shop',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository();
      await tester.pumpWidget(
        _host(
          const PoiSelectorRow(shop: 'SHOP-9'),
          poi: _poiNotifier(repository),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSalePoiOpen')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('poiPickerAdd')));
      await tester.pumpAndSettle();

      await nameIt(tester);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();
      expect(repository.creates.single['shop'], 'SHOP-9');
    });
  });

  group('add a place with no load', () {
    testWidgets('the home card stands whether or not he is carrying anything',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository();
      var opened = false;
      await tester.pumpWidget(
        _host(
          AddPlaceCard(onAddPlace: () => opened = true),
          poi: _poiNotifier(repository),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing about it reads a load: no load notifier was even supplied.
      expect(find.byKey(const Key('driverHomeAddPlaceCard')), findsOneWidget);
      await tester.tap(find.byKey(const Key('driverHomeAddPlaceCard')));
      await tester.pumpAndSettle();
      expect(opened, isTrue);
    });

    testWidgets('with no load the sheet asks the server which shops he '
        'delivers for', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..shopChoices = _choices([('SHOP-1', 'Depot North')]);
      await tester.pumpWidget(
        _host(const AddPoiSheet(), poi: _poiNotifier(repository)),
      );
      await tester.pumpAndSettle();
      expect(repository.myShopsReads, 1);
    });
  });

  group('the load card', () {
    testWidgets('add a place is a fourth action and opens the sheet',
        (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      final load = _loadNotifier(loads);
      await load.load();
      final poi = _poiNotifier(_FakePoiRepository());
      await tester.pumpWidget(
        _host(const DriverLoadPlane(), poi: poi, load: load),
      );
      await tester.pumpAndSettle();

      final action = find.byKey(const Key('driverLoadAddPoi-LOAD-4'));
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('addPoiSheet')), findsOneWidget);
    });

    testWidgets('each card tags the place to ITS OWN shop, so two open '
        'loads are never an unanswerable question', (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [
          DriverLoad.fromJson(_loadJson()),
          DriverLoad.fromJson(
            _loadJson(
              id: 'LOAD-5',
              shopId: 'SHOP-2',
              shopTitle: 'Depot South',
            ),
          ),
        ],
      );
      final load = _loadNotifier(loads);
      await load.load();
      final repository = _FakePoiRepository();
      await tester.pumpWidget(
        _host(
          const DriverLoadPlane(),
          poi: _poiNotifier(repository),
          load: load,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('driverLoadAddPoi-LOAD-5')));
      await tester.pumpAndSettle();
      // The card he tapped answered "which shop" before the sheet opened,
      // so the sheet neither asks nor needs to read the picker.
      expect(find.byKey(const Key('addPoiShopPicker')), findsNothing);
      expect(repository.myShopsReads, 0);

      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await nameOwner(tester);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();
      expect(repository.creates.single['shop'], 'SHOP-2');
    });
  });

  group('who runs the place', () {
    Future<void> openSheet(
      WidgetTester tester,
      _FakePoiRepository repository,
    ) async {
      await tester.pumpWidget(
        _host(const AddPoiSheet(), poi: _poiNotifier(repository)),
      );
      await tester.pumpAndSettle();
    }

    /// Types the number and leaves the field, which is when the sheet asks
    /// who holds it.
    Future<void> typeNumberAndLeaveIt(WidgetTester tester) async {
      await tester.enterText(
        find.byKey(const Key('addPoiOwnerPhone')),
        _ownerPhone,
      );
      await tester.pumpAndSettle();
      // Focus moves to another field: that is the blur the lookup hangs on.
      await tester.tap(find.byKey(const Key('addPoiLabel')));
      await tester.pumpAndSettle();
    }

    testWidgets('the number is looked up when he leaves the field, not on '
        'every digit', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..ownerAnswer = DriverPoiOwner.fromJson(_ownerJson());
      await openSheet(tester, repository);

      await tester.enterText(
        find.byKey(const Key('addPoiOwnerPhone')),
        _ownerPhone,
      );
      await tester.pumpAndSettle();
      // Eleven digits typed, nothing asked yet.
      expect(repository.ownerLookups, isEmpty);

      await tester.tap(find.byKey(const Key('addPoiLabel')));
      await tester.pumpAndSettle();
      expect(repository.ownerLookups, [_ownerPhone]);
    });

    testWidgets('an owner already on file is filled in and says how many '
        'places he runs', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..ownerAnswer = DriverPoiOwner.fromJson(_ownerJson());
      await openSheet(tester, repository);
      await typeNumberAndLeaveIt(tester);

      expect(find.byKey(const Key('addPoiOwnerOnFile')), findsOneWidget);
      final text = _allText(tester);
      expect(text, contains('thandi mokoena'));
      // The count is the thing a driver could not otherwise know.
      expect(text, contains('3'));
      // And the name is filled in rather than typed again.
      expect(
        tester
            .widget<TextFormField>(
              find.descendant(
                of: find.byKey(const Key('addPoiOwnerFirst')),
                matching: find.byType(TextFormField),
              ),
            )
            .controller
            ?.text,
        'Thandi',
      );
    });

    testWidgets('a number nobody holds says nothing and leaves the name his',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..ownerAnswer = DriverPoiOwner.fromJson(_ownerJson(found: false));
      await openSheet(tester, repository);
      await typeNumberAndLeaveIt(tester);

      expect(repository.ownerLookups, [_ownerPhone]);
      expect(find.byKey(const Key('addPoiOwnerOnFile')), findsNothing);
    });

    testWidgets('the owner he named rides the create', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository();
      await openSheet(tester, repository);
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await nameOwner(tester, last: 'Mokoena', phone: _ownerPhone);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();

      final sent = repository.creates.single;
      expect(sent['owner_first_name'], 'Thandi');
      expect(sent['owner_last_name'], 'Mokoena');
      expect(sent['owner_phone'], _ownerPhone);
      // Nobody has been asked anything, so nothing is confirmed.
      expect(sent['owner_confirmed_user'], isFalse);
    });

    testWidgets('a place that is a business waits for a first name; a gate '
        'does not', (tester) async {
      sizeUp(tester);
      await openSheet(tester, _FakePoiRepository());
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Depot gate',
      );
      Widget commit() => tester.widget(find.byKey(const Key('addPoiConfirm')));

      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await tester.pumpAndSettle();
      expect((commit() as dynamic).onPressed, isNull);

      // A gate is nobody's. Same form, no owner needed.
      await tester.tap(find.byKey(const Key('addPoiType-gate')));
      await tester.pumpAndSettle();
      expect((commit() as dynamic).onPressed, isNotNull);
    });

    testWidgets('the number on file under another name is asked about, and '
        'a yes re-sends it confirmed', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..ownerClash = const DriverPoiOwnerClash(firstName: 'Thandi');
      await openSheet(tester, repository);
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await nameOwner(tester, first: 'Sipho', phone: _ownerPhone);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();

      // A question, not a red line - and it names the owner on file.
      expect(find.byKey(const Key('addPoiOwnerClashDialog')), findsOneWidget);
      expect(_allText(tester), contains('thandi'));
      expect(repository.creates, hasLength(1));
      expect(repository.creates.single['owner_confirmed_user'], isFalse);

      await tester.tap(find.byKey(const Key('addPoiOwnerClashConfirm')));
      await tester.pumpAndSettle();

      // Re-sent once, and only the second one carries the confirmation.
      expect(repository.creates, hasLength(2));
      expect(repository.creates.last['owner_confirmed_user'], isTrue);
      expect(repository.creates.last['owner_first_name'], 'Sipho');
    });

    testWidgets('a no files nothing and asks nothing twice', (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..ownerClash = const DriverPoiOwnerClash(firstName: 'Thandi');
      DriverPoi? handedBack;
      await tester.pumpWidget(
        _host(
          AddPoiSheet(onFiled: (point) => handedBack = point),
          poi: _poiNotifier(repository),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await nameOwner(tester, first: 'Sipho', phone: _ownerPhone);
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('addPoiOwnerClashCancel')));
      await tester.pumpAndSettle();

      expect(repository.creates, hasLength(1));
      expect(handedBack, isNull);
      // The sheet is still open on his own answer, not closed behind him.
      expect(find.byKey(const Key('addPoiSheet')), findsOneWidget);
    });

    testWidgets('"not this person" hands the name back to him',
        (tester) async {
      sizeUp(tester);
      final repository = _FakePoiRepository()
        ..ownerAnswer = DriverPoiOwner.fromJson(_ownerJson());
      await openSheet(tester, repository);
      await typeNumberAndLeaveIt(tester);
      expect(find.byKey(const Key('addPoiOwnerOnFile')), findsOneWidget);

      await tester.tap(find.byKey(const Key('addPoiOwnerNotThem')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addPoiOwnerOnFile')), findsNothing);
      await tester.enterText(
        find.byKey(const Key('addPoiOwnerFirst')),
        'Sipho',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('addPoiLabel')),
        'Corner spaza',
      );
      await tester.tap(find.byKey(const Key('addPoiType-spaza shop')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('addPoiConfirm')));
      await tester.pumpAndSettle();
      expect(repository.creates.single['owner_first_name'], 'Sipho');
    });
  });

  group('selling at a place he says he is at', () {
    Future<DriverLoadNotifier> openSellScreen(
      WidgetTester tester, {
      required _FakeLoadRepository loads,
      required _FakePoiRepository points,
      LocationFix? locationFix,
    }) async {
      final load = _loadNotifier(loads);
      await load.load();
      await tester.pumpWidget(
        _host(
          const LoadSalePlane(loadOrder: 'LOAD-4'),
          poi: _poiNotifier(points, locationFix: locationFix),
          load: load,
        ),
      );
      await tester.pumpAndSettle();
      return load;
    }

    Future<void> pickThePlaceAndSell(
      WidgetTester tester, {
      String pointKey = 'poiRow-POI-FAR',
    }) async {
      await tester.tap(find.byKey(const Key('loadSalePoiOpen')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(pointKey)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSaleConfirm')));
      await tester.pumpAndSettle();
    }

    testWidgets('standing at it, nothing is asked', (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await openSellScreen(
        tester,
        loads: loads,
        points: _FakePoiRepository(
          points: [DriverPoi.fromJson(_pointJson())],
        ),
      );
      await pickThePlaceAndSell(tester, pointKey: 'poiRow-POI-1');

      expect(find.byKey(const Key('loadSalePoiFarDialog')), findsNothing);
      expect(loads.sales.single.$5, 'POI-1');
    });

    testWidgets('further off than the rule allows, it asks - and the sale '
        'goes through on a yes', (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await openSellScreen(
        tester,
        loads: loads,
        points: _FakePoiRepository(
          points: [DriverPoi.fromJson(_farPointJson())],
        ),
      );
      await pickThePlaceAndSell(tester);

      expect(find.byKey(const Key('loadSalePoiFarDialog')), findsOneWidget);
      // It says how far off he is and which place he named.
      final asked = _allText(tester);
      expect(asked, contains('next corner spaza'));
      expect(asked, contains('m'));
      expect(loads.sales, isEmpty);

      await tester.tap(find.byKey(const Key('loadSalePoiFarConfirm')));
      await tester.pumpAndSettle();

      // It ASKED. It never blocked.
      expect(loads.sales.single.$5, 'POI-FAR');
    });

    testWidgets('a no leaves the sale unbooked and the screen standing',
        (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await openSellScreen(
        tester,
        loads: loads,
        points: _FakePoiRepository(
          points: [DriverPoi.fromJson(_farPointJson())],
        ),
      );
      await pickThePlaceAndSell(tester);
      await tester.tap(find.byKey(const Key('loadSalePoiFarCancel')));
      await tester.pumpAndSettle();

      expect(loads.sales, isEmpty);
      expect(find.byKey(const Key('loadSalePlane')), findsOneWidget);
    });

    testWidgets('a phone that will not give a fix is not asked to prove '
        'anything', (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await openSellScreen(
        tester,
        loads: loads,
        points: _FakePoiRepository(
          points: [DriverPoi.fromJson(_farPointJson(), )],
        ),
        locationFix: _noFix,
      );
      // With no fix there is nothing to seed the list from either, so the
      // point is selected straight on the slice - the same state the row
      // would be in after a pick.
      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSaleConfirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loadSalePoiFarDialog')), findsNothing);
      expect(loads.sales, hasLength(1));
    });

    testWidgets('a sale with no place named is never asked about',
        (tester) async {
      sizeUp(tester);
      final loads = _FakeLoadRepository(
        loads: [DriverLoad.fromJson(_loadJson())],
      );
      await openSellScreen(
        tester,
        loads: loads,
        points: _FakePoiRepository(
          points: [DriverPoi.fromJson(_farPointJson())],
        ),
      );
      await tester.tap(find.byKey(const Key('loadStepPlus-STK-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('loadSaleConfirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('loadSalePoiFarDialog')), findsNothing);
      expect(loads.sales.single.$5, isNull);
    });
  });

  group('how close counts as at the place', () {
    test('fifty metres is the line, and it is inclusive', () {
      expect(PoiProximity.confirmMetres, 50);
      expect(PoiProximity.needsConfirming(0), isFalse);
      expect(PoiProximity.needsConfirming(49.9), isFalse);
      expect(PoiProximity.needsConfirming(50), isFalse);
      expect(PoiProximity.needsConfirming(50.1), isTrue);
      expect(PoiProximity.needsConfirming(400), isTrue);
    });

    test('an unknown distance never asks', () {
      // A phone that would not give a fix is not evidence that he is
      // somewhere else.
      expect(PoiProximity.needsConfirming(null), isFalse);
    });

    test('the distance is measured the way the server measures it', () {
      expect(
        metresBetween(
          _sandton.$1,
          _sandton.$2,
          _sandton.$1,
          _sandton.$2,
        ),
        0,
      );
      // ~0.002 degrees of latitude is ~222 m, and the sign of the step
      // cannot matter.
      final north = metresBetween(
        _sandton.$1,
        _sandton.$2,
        _twoHundredMetresOff.$1,
        _twoHundredMetresOff.$2,
      );
      expect(north, closeTo(222, 3));
      expect(
        metresBetween(
          _twoHundredMetresOff.$1,
          _twoHundredMetresOff.$2,
          _sandton.$1,
          _sandton.$2,
        ),
        closeTo(north, 0.001),
      );
    });
  });

  group('distance, as a driver reads it', () {
    test('metres up close, kilometres past that', () {
      expect(poiDistanceText(0.012), '12 m');
      expect(poiDistanceText(0.999), '999 m');
      expect(poiDistanceText(1.25), '1.3 km');
    });
  });
}
