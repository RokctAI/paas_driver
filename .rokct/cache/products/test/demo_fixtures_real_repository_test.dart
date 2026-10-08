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

// Demo runs the REAL products repositories: base_sdk's
// DemoGatewayInterceptor answers every platform cmd they send from
// templates/assets/demo/products.

import 'package:base_sdk/src/models/data/cart_product_data.dart';
import 'package:base_sdk/src/models/data/product_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/brands_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/categories_repository.dart';
import 'package:products_sdk/src/common/infrastructure/repositories/products_repository.dart';
import 'package:products_sdk/src/manager/infrastructure/repositories/seller_catalog_repository.dart';
import 'package:products_sdk/src/manager/infrastructure/repositories/seller_products_repository.dart';

import 'support/demo_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(startDemoFixtures);
  tearDown(stopDemoFixtures);

  test(
    'customer catalog: products, the 18+ seed, details and totals',
    () async {
      final repo = ProductsRepository();
      final page = ok(await repo.getProductsPaginate(page: 1)).data!;
      expect(page.map((p) => p.translation?.title), [
        'Flame-grilled beef burger',
        'Margherita pizza',
        'Craft lager 440ml',
      ]);
      expect(page.last.isAdult, isTrue);
      expect(page.first.stocks!.single.price, 150);
      expect(ok(await repo.getProductsPaginate(page: 2)).data, isEmpty);
      expect(ok(await repo.searchProducts(text: 'burger')).data, isNotEmpty);
      expect(
        ok(await repo.getProductDetails('demo_product_uuid')).data!.uuid,
        'demo_product_uuid',
      );
      expect(ok(await repo.getMostSoldProducts()).data, hasLength(1));
      expect(ok(await repo.getProductsByIds(['1'])).data, hasLength(3));
      expect(ok(await repo.getDiscountProducts()).data, hasLength(3));
      expect(ok(await repo.getNewProducts()).data, hasLength(3));
      final all = ok(await repo.getAllProducts(shopId: '1'));
      expect(all.data!.all!.single.products!.single.uuid, 'demo_product_uuid');
      final calc = ok(
        await repo.getAllCalculations([
          CartProductData(selectedStock: Stocks(id: '1'), quantity: 1),
        ]),
      );
      expect(calc.data!.orderTotal, 150);
      ok(await repo.addReview('demo_product_uuid', 'Great', 5, null));
    },
  );

  test('customer categories and brands', () async {
    final categories = CategoriesRepository();
    expect(
      ok(await categories.getAllCategories(page: 1)).data!
          .map((c) => c.translation?.title),
      ['Burgers', 'Pizza'],
    );
    expect(
      ok(await categories.getCategoriesByShop(shopId: '1')).data!
          .map((c) => c.translation?.title),
      ['Mains', 'Sides', 'Drinks'],
    );
    expect(
      ok(await categories.searchCategories(text: 'bur')).data,
      hasLength(1),
    );
    final brands = BrandsRepository();
    expect(ok(await brands.getAllBrands()).data!.map((b) => b.title), [
      'Karoo Grill Co.',
      'Highveld Dairy',
    ]);
    expect(ok(await brands.getSingleBrand('1')).data!.title, 'Karoo Grill Co.');
  });

  test('seller menu: six dishes, two add-ons, extras and every edit', () async {
    final repo = SellerProductsRepository();
    final products = ok(await repo.getProducts(page: 1)).data!;
    expect(products, hasLength(6));
    expect(products.first.translation?.title, 'Peri-peri chicken wrap');
    expect(products.first.stocks!.single.price, 89.0);
    expect(
      ok(await repo.getProducts(page: 1, categoryId: '3')).data!.single.id,
      '6',
    );
    expect(
      ok(await repo.getProducts(page: 1, needAddons: true)).data,
      hasLength(2),
    );
    expect(ok(await repo.getProducts(page: 2)).data, isEmpty);
    expect(ok(await repo.getProductDetails('demo_product_5')).data!.id, '5');
    expect(
      ok(await repo.updateProduct(uuid: 'demo_product_2', product: {}))
          .data!
          .id,
      '2',
    );
    final groups = ok(await repo.getExtrasGroups(page: 1)).data!;
    expect(groups.map((g) => g.translation?.title), ['Heat', 'Portion']);
    expect(
      ok(await repo.getExtras(groupId: '2')).data!.extraValues,
      hasLength(2),
    );
    ok(await repo.createExtrasGroup(group: {}));
    ok(await repo.updateExtrasGroup(groupId: '1', group: {}));
    ok(await repo.deleteExtrasGroup(groupId: '2'));
    expect(ok(await repo.createExtrasItem(item: {})).data!.value, 'New value');
    expect(
      ok(await repo.updateExtrasItem(extrasId: '3', item: {})).data!.value,
      'Hot',
    );
    ok(await repo.deleteExtrasItem(ids: ['1']));
  });

  test('seller catalog: categories by type, units, and edits', () async {
    final repo = SellerCatalogRepository();
    expect(
      ok(await repo.getCategories()).data!.map((c) => c.translation?.title),
      ['Mains', 'Sides', 'Drinks'],
    );
    expect(ok(await repo.getShopCategories()).data, hasLength(3));
    expect(
      ok(await repo.getCategoriesSub()).data!.map((c) => c.translation?.title),
      ['Breakfast', 'Late night'],
    );
    expect(ok(await repo.getCategories(page: 2)).data, isEmpty);
    expect(ok(await repo.getUnits()).data, hasLength(3));
    ok(await repo.createCategory(title: 'Desserts', input: '1'));
    ok(await repo.deleteCategory(id: 'demo_category_1'));
  });
}
