import 'package:flutter/widgets.dart';

import 'package:base_sdk/src/models/data/product_data.dart';

/// Host-supplied product-detail surface, opened as a draggable bottom sheet.
///
/// Feature SDKs that list products (marketplace_sdk's discounted-products
/// row, a search result, a shop page) need to open a product's detail view
/// on tap, but the page that renders it lives in products_sdk — and under
/// ADR-005 a feature SDK must not import another feature SDK, only
/// base_sdk. Depending on products_sdk directly would also force every app
/// composing marketplace_sdk to compose products_sdk too, whether or not it
/// sells products.
///
/// So the caller asks for this interface instead, and apps that do compose
/// products_sdk register an implementation (typically via `GetIt`, at
/// startup) that returns products_sdk's `ProductScreen`. Callers guard on
/// `GetIt.instance.isRegistered<ProductDetailSheet>()`; where nothing is
/// registered the tap is simply inert, exactly like launch_sdk's
/// [LaunchGlanceSource] renders nothing when unregistered.
///
/// [build] returns the sheet's content rather than showing it, because the
/// caller owns presentation — it supplies the [controller] from whichever
/// modal host it used (`AppHelpers.showCustomModalBottomDragSheet`).
abstract class ProductDetailSheet {
  Widget build(
    BuildContext context, {
    required ScrollController controller,
    ProductData? data,
    String? productId,
    String? cartId,
  });
}
