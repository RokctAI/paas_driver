import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';

/// Op type for the coalescing customer-cart snapshot push. The handler is
/// registered by orders_sdk when it is composed into the app; until then
/// ops of this type sit pending in the outbox (the engine skips op types
/// without a registered handler).
const String kCartSyncOpType = 'cart.sync';

/// Local-first customer cart document in the shared KV store.
///
/// One document per device (`customer_cart` box, single key): cart
/// mutations write here synchronously and the backend cart catches up via
/// the outbox, so the model is same-device only — matching the sync
/// engine's overall non-goal of multi-device offline merge.
class CustomerCartStore {
  const CustomerCartStore();

  static const String boxName = 'customer_cart';
  static const String _docKey = 'cart';

  AppDatabase get _db => AppDatabase();

  Future<void> save(Cart cart) async {
    try {
      await _db.putItem(boxName, _docKey, cart.toJson());
    } catch (e) {
      // Cart.toJson is null-hostile (`userCarts!`); a snapshot that cannot
      // serialize is skipped rather than crashing the mutation that
      // already succeeded locally.
      debugPrint('==> customer cart persist failed: $e');
    }
  }

  Future<Cart?> load() async {
    final json = await _db.getItem(boxName, _docKey);
    if (json == null) return null;
    try {
      return Cart.fromJson(json);
    } catch (e) {
      debugPrint('==> customer cart load failed: $e');
      return null;
    }
  }

  Future<void> clear() => _db.deleteItem(boxName, _docKey);
}
