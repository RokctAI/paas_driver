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

// Demo runs the REAL merchants repositories: base_sdk's
// DemoGatewayInterceptor answers every platform cmd they send from
// templates/assets/demo/merchants.

import 'package:base_sdk/src/handlers/platform_gateway.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:merchants_sdk/src/common/infrastructure/repositories/shops_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/quick_flow_repository.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/seller_shop_repository.dart';

import 'support/demo_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(startDemoFixtures);
  tearDown(stopDemoFixtures);

  test('customer shops: the two demo shops and every read', () async {
    final repo = ShopsRepository();
    final all = ok(await repo.getAllShops(1, isOpen: true)).data!;
    expect(all.map((s) => s.translation?.title), [
      'Corner Kitchen',
      "Nonna's Pizzeria",
    ]);
    final corner = all.first;
    expect(corner.seller?.firstname, 'Thandi');
    expect(corner.deliveryTime?.from, '30');
    expect(corner.deliveryTime?.to, '45');
    expect(corner.backgroundImg, startsWith('data:image/svg+xml'));
    expect(ok(await repo.getSingleShop(uuid: '1')).data!.id, '1');
    expect(ok(await repo.searchShops(text: 'corner')).data, hasLength(1));
    expect(ok(await repo.getNearbyShops(0, 0)).data, hasLength(1));
    expect(ok(await repo.getShopsByIds(['1'])).data, hasLength(1));
    expect(ok(await repo.getShopsRecommend(1)).data, hasLength(1));
    expect(
      ok(await repo.getShopFilter(page: 1, categoryId: '1')).data,
      hasLength(2),
    );
    expect(ok(await repo.getPickupShops()).data, hasLength(2));
    expect(ok(await repo.checkDriverZone(const LatLng(0, 0))), isTrue);
    expect(ok(await repo.getStory(1)), isEmpty);
    expect(ok(await repo.getTags('1')).data, isEmpty);
    expect(ok(await repo.getSuggestPrice()).data.max, 100);
  });

  test('manager: the same shop, its week and Quick flow', () async {
    final shop = SellerShopRepository();
    final mine = ok(await shop.getMyShop());
    expect(mine.data!.translation?.title, 'Corner Kitchen');
    expect(mine.orderPayment, 'before');
    ok(await shop.setWorkingStatus(open: false));
    final week = ok(await shop.getShopWorkingDays());
    expect(week, hasLength(7));
    expect(week.last.day, 'sunday');
    expect(week.last.disabled, isTrue);
    ok(await shop.updateShopWorkingDays(workingDays: week));
    final quick = ok(await QuickFlowRepository().getQuickFlowSettings());
    expect(quick.shopName, 'Blue Tap Water Refill');
    expect(quick.presetCount, 5);
    expect(quick.autodialArmed, isTrue);
    expect(quick.presetFor(9), isNull);
  });

  test(
    'the POS adapter\'s customer search answers the demo customer',
    () async {
      final rows = await const PlatformGateway().tenant(
        'api.seller_shop_settings.get_shop_users',
        {'limit_start': 0, 'limit_page_length': 20},
      );
      expect((rows as List).single['firstname'], 'Thabo');
    },
  );
}
