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

// The seam between the read and the drawing: poiDataProvider is what the map
// page watches, and until this wave nothing ever called updatePOIData, so the
// provider sat on its empty initial state for the life of the app and the
// customer map drew no stored points at all.
//
// These pin the notifier's contract - starts empty, takes what the repository
// answered, and a second read replaces rather than appends, so panning back
// and forth cannot pile up duplicate markers.

import 'package:base_sdk/src/models/data/poi_data.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_sdk/src/common/application/poidata/poi_data_provider.dart';

POIData _poi(String name, {double latitude = -26.2, double longitude = 28.05}) =>
    POIData(
      name: name,
      latitude: latitude,
      longitude: longitude,
      titleColor: Colors.transparent,
      pin: '',
    );

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('poiDataProvider', () {
    test('holds no points until a read fills it', () {
      expect(container.read(poiDataProvider), isEmpty);
    });

    test('takes the points a read answered', () {
      container
          .read(poiDataProvider.notifier)
          .updatePOIData([_poi('Water Point'), _poi('Clinic')]);

      expect(
        container.read(poiDataProvider).map((poi) => poi.name),
        ['Water Point', 'Clinic'],
      );
    });

    test('a second read replaces the points rather than adding to them', () {
      final notifier = container.read(poiDataProvider.notifier);
      notifier.updatePOIData([_poi('Water Point')]);
      notifier.updatePOIData([_poi('Clinic'), _poi('North Gate')]);

      expect(
        container.read(poiDataProvider).map((poi) => poi.name),
        ['Clinic', 'North Gate'],
      );
    });

    test('an area with no points empties the map again', () {
      final notifier = container.read(poiDataProvider.notifier);
      notifier.updatePOIData([_poi('Water Point')]);
      notifier.updatePOIData(const []);

      expect(container.read(poiDataProvider), isEmpty);
    });

    test('a listener is told each time the points change', () {
      final seen = <int>[];
      container.listen<List<POIData>>(
        poiDataProvider,
        (previous, next) => seen.add(next.length),
        fireImmediately: true,
      );

      final notifier = container.read(poiDataProvider.notifier);
      notifier.updatePOIData([_poi('Water Point')]);
      notifier.updatePOIData([_poi('Clinic'), _poi('North Gate')]);

      expect(seen, [0, 1, 2]);
    });
  });
}
