import 'dart:convert';
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:base_sdk/src/database/app_database.dart';
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/models/request/cart_request.dart';
import 'package:base_sdk/src/services/customer_cart_store.dart';
import 'package:base_sdk/src/sync/sync_handler.dart';

/// Pushes `cart.sync` outbox ops: the latest-wins snapshot of one shop's
/// customer cart, queued by base_sdk's `ShopOrderNotifier` while the backend
/// was unreachable, is replayed against the server cart the next time the
/// SyncEngine drains. Registered with the engine in
/// `OrdersSdkDependencies.register` (the common hook, so customer composes
/// get it — their caches have `lib/src/manager/` stripped).
///
/// Payload contract (written by `ShopOrderNotifier._cartSnapshot`):
/// `{"shopId": <String?>, "cartId": <String?>, "items": [{"stockId",
/// "quantity", "addons": [{"stockId", "quantity"}]}]}` — one coalesced op
/// per shop (`dedupeKey` = shopId, op id `cart.sync:<shopId>`), and an
/// empty `items` list means the server cart must be cleared.
///
/// Replay semantics mirror the online notifier flows exactly: one
/// `insertCart` (add_to_cart) call per item sets that stock's absolute
/// quantity plus its addon list, then any server-side detail whose stock is
/// no longer in the snapshot is dropped via `removeProductCart` — using the
/// cart returned by the last insert, the same shape the online flows read.
/// Every call is absolute-state, so a retry after an ambiguous failure
/// converges instead of double-applying; no temp ids are involved (carts
/// have no offline ids), so success returns no id mappings.
class CartSyncHandler extends SyncHandler {
  CartSyncHandler(this._cartRepository);

  /// Op type this handler serves (base_sdk's constant, so enqueue side and
  /// handler side cannot drift).
  static const String opType = kCartSyncOpType;

  /// `sdk` column value for ops enqueued under this SDK's name.
  static const String sdkName = 'orders_sdk';

  final CartRepositoryFacade _cartRepository;

  @override
  Future<SyncResult> push(OutboxEntry op) async {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(op.payload) as Map<String, dynamic>;
    } catch (e) {
      return SyncResult.rejected('cart.sync payload unreadable: $e');
    }
    final shopId = (payload['shopId'] ?? '').toString();
    final cartId = (payload['cartId'] ?? '').toString();
    final items = payload['items'];
    if (items is! List) {
      return const SyncResult.rejected('cart.sync op missing items');
    }
    if (items.isEmpty) {
      return _clearServerCart(shopId: shopId, cartId: cartId);
    }
    if (shopId.isEmpty) {
      return const SyncResult.rejected('cart.sync op missing shopId');
    }

    final snapshotItems = <Map<String, dynamic>>[
      for (final item in items)
        if (item is Map &&
            (item['stockId'] ?? '').toString().isNotEmpty)
          item.cast<String, dynamic>(),
    ];
    if (snapshotItems.isEmpty) {
      return const SyncResult.rejected('cart.sync op has no usable items');
    }

    // Phase 1: absolute-quantity upsert per item, the exact call shape the
    // online addCount/removeCount flows send for a changed item.
    Cart? serverCart;
    for (final item in snapshotItems) {
      final stockId = item['stockId'].toString();
      final quantity =
          item['quantity'] is num ? (item['quantity'] as num).toInt() : 1;
      final carts = <CartRequest>[
        CartRequest(stockId: stockId, quantity: quantity),
      ];
      final addons = item['addons'];
      if (addons is List) {
        for (final addon in addons) {
          if (addon is! Map) continue;
          final addonStockId = (addon['stockId'] ?? '').toString();
          if (addonStockId.isEmpty) continue;
          carts.add(
            CartRequest(
              stockId: addonStockId,
              quantity: addon['quantity'] is num
                  ? (addon['quantity'] as num).toInt()
                  : null,
              parentId: stockId,
            ),
          );
        }
      }
      final response = await _cartRepository.insertCart(
        cart: CartRequest(
          shopId: shopId,
          stockId: stockId,
          quantity: quantity,
          carts: carts,
        ),
      );
      final failure = response.when<SyncResult?>(
        success: (data) {
          serverCart = data.data;
          return null;
        },
        failure: _failureResult,
      );
      if (failure != null) return failure;
    }

    // Phase 2: drop server details the snapshot no longer contains, from the
    // cart the last insert returned (same read the online flows use). Bonus
    // details are server-granted and never appear in local snapshots, so
    // they are left to the server. Addons live nested under their parent
    // detail, not as top-level details, and were already replaced above.
    final snapshotStockIds = {
      for (final item in snapshotItems) item['stockId'].toString(),
    };
    final details = serverCart?.userCarts?.isNotEmpty == true
        ? (serverCart?.userCarts?.first.cartDetails ?? <CartDetail>[])
        : <CartDetail>[];
    for (final detail in details) {
      if (detail.bonus == true) continue;
      final detailId = detail.id ?? '';
      final detailStockId = detail.stock?.id ?? '';
      if (detailId.isEmpty || snapshotStockIds.contains(detailStockId)) {
        continue;
      }
      final response =
          await _cartRepository.removeProductCart(cartDetailId: detailId);
      final failure = response.when<SyncResult?>(
        success: (_) => null,
        failure: _failureResult,
      );
      if (failure != null) return failure;
    }
    return const SyncResult.synced();
  }

  /// Empty snapshot: the cart was emptied (or discarded) locally, so the
  /// server cart is deleted. Resolves the cart id via `getCart(shopId)` when
  /// the snapshot has none (a cart that never reached the server before the
  /// clear), and treats 404 as already-clear on both calls.
  Future<SyncResult> _clearServerCart({
    required String shopId,
    required String cartId,
  }) async {
    var id = cartId;
    if (id.isEmpty) {
      if (shopId.isEmpty) {
        // Nothing addressable on the server; the empty state already holds.
        return const SyncResult.synced();
      }
      final current = await _cartRepository.getCart(shopId);
      final failure = current.when<SyncResult?>(
        success: (data) {
          id = data.data?.id ?? '';
          return null;
        },
        failure: (error, status) => status == 404
            ? const SyncResult.synced()
            : _failureResult(error, status),
      );
      if (failure != null) return failure;
      if (id.isEmpty) return const SyncResult.synced();
    }
    final response = await _cartRepository.deleteCart(cartId: id);
    return response.when(
      success: (_) => const SyncResult.synced(),
      failure: (error, status) => status == 404
          ? const SyncResult.synced()
          : _failureResult(error, status),
    );
  }

  /// The repository funnels errors through `NetworkExceptions.getDioStatus`,
  /// which maps connection failures and timeouts to 500 — so >= 500 (plus
  /// 408) is transient and a concrete 4xx is a terminal rejection that
  /// parks the op (park-and-surface, matching the other Phase 2/3 handlers
  /// and the notifiers' `_isTransientStatus` rule).
  SyncResult _failureResult(String error, int status) {
    if (status >= 400 && status < 500 && status != 408) {
      return SyncResult.rejected(error);
    }
    return SyncResult.retryable(error);
  }
}
