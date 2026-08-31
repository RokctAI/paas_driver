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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stocks/edit_food_stocks_body.dart';
import 'details/edit_food_details_body.dart';
import 'package:base_sdk/src/presentation/components/keyboard_dismisser.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:products_sdk/src/common/infrastructure/models/data/seller_product_data.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/category/edit_food_categories_provider.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/edit_food_details_provider.dart';
import 'package:products_sdk/src/manager/application/foods/edit/details/units/edit_food_units_provider.dart';
import 'package:products_sdk/src/manager/application/foods/foods_provider.dart';
import 'package:products_sdk/src/manager/presentation/catalog/catalog_edit_rail.dart';
import 'package:products_sdk/src/manager/presentation/catalog/edit_plane_flow.dart';

/// The APPROVED edit flow (frames 35b/35d, Ray 2026-08-29 15:41Z): the
/// shipped EditProductModal's two tabs, pushed as a REAL route instead of a
/// sheet — the push is the 12:36Z nav-fold moment (this route covers the
/// home shell's centered nav; the corner back pill is the one affordance
/// left, kitchen_detail_page's precedent).
///
///  * WIDE (35b): the form declares 2 — Details | Stocks side-by-side
///    panes on the plane grid; the origin catalog keeps plane 1 as the
///    compressed [CatalogEditRail] (12:26Z origin rule).
///  * PHONE (35d): the panes fold back into the shipped Details/Stocks
///    segmented tabs.
///
/// The form field logic, validation and save paths are the SHIPPED bodies
/// unchanged in behaviour (EditFoodDetailsBody / EditFoodStocksBody — same
/// notifiers, same satellite picker sheets); only their presentation moved
/// into the approved dark language.
class ProductEditPage extends ConsumerStatefulWidget {
  final SellerProductData product;

  const ProductEditPage({super.key, required this.product});

  /// Seeds the edit providers (exactly the shipped list-tap seeding) and
  /// pushes the page over the whole shell (root navigator = the nav fold).
  static Future<void> open(
    BuildContext context,
    WidgetRef ref,
    SellerProductData product,
  ) {
    ref.read(editFoodDetailsProvider.notifier).setFoodDetails(product);
    ref.read(editFoodUnitsProvider.notifier).setFoodUnit(product.unit);
    ref.read(editFoodCategoriesProvider.notifier).setFoodCategory(
          product.category,
        );
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ProductEditPage(product: product)),
    );
  }

  @override
  ConsumerState<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends ConsumerState<ProductEditPage> {
  final ScrollController _detailsScroll = ScrollController();

  @override
  void dispose() {
    _detailsScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(foodsProvider).foods;
    return KeyboardDismisser(
      child: Scaffold(
        backgroundColor: AppStyle.surfaceDark,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
            child: ProductEditPlaneFlow(
              railBuilder: (context) => CatalogEditRail(
                products: products,
                editedId: widget.product.id,
              ),
              formBuilder: (context) => ProductFormSplit(
                header: _header(),
                detailsTitle: AppHelpers.getTranslation('details'),
                stocksTitle: AppHelpers.getTranslation('stocks'),
                stocksHeaderTrailing: _variantsCount(),
                detailsBuilder: (context) => Padding(
                  // Clear of the corner back pill (the kitchen detail
                  // page's reserve).
                  padding: const EdgeInsets.only(bottom: 64),
                  child: EditFoodDetailsBody(
                    controller: _detailsScroll,
                    // The shipped modal hopped to its stocks tab after a
                    // details save; panes show both at once and the phone
                    // page keeps the user where they saved.
                    onSave: () {},
                  ),
                ),
                stocksBuilder: (context) => Padding(
                  padding: const EdgeInsets.only(bottom: 64),
                  child: EditFoodStocksBody(product: widget.product),
                ),
              ),
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              '${AppHelpers.getTranslation(TrKeys.editProduct)} — '
              '${widget.product.translation?.title ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyle.interBold(size: 20, color: AppStyle.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _variantsCount() {
    final int count = widget.product.stocks?.length ?? 0;
    if (count == 0) return null;
    return Text(
      '$count ${AppHelpers.getTranslation('variants')}',
      style: AppStyle.interNormal(
        size: 12,
        color: AppStyle.textDarkSecondary,
      ),
    );
  }
}
