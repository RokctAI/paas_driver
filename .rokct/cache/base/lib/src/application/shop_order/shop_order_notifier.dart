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


import 'dart:async';
import 'dart:convert';
import 'package:base_sdk/src/navigation/app_routes.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/cart.dart';
import 'package:base_sdk/src/models/data/addons_data.dart';
import 'package:base_sdk/src/models/data/cart_data.dart';
import 'package:base_sdk/src/models/request/cart_request.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
// [refork] removed host router import
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/customer_cart_store.dart';
import 'package:base_sdk/src/services/tpying_delay.dart';
import 'package:base_sdk/src/sync/sync_engine.dart';
import 'package:base_sdk/src/application/shop_order/shop_order_state.dart';
import 'package:http/http.dart' as http;
import 'package:base_sdk/src/handlers/api_result.dart';

class ShopOrderNotifier extends StateNotifier<ShopOrderState> {
  final CartRepositoryFacade _cartRepository;

  ShopOrderNotifier(this._cartRepository) : super(const ShopOrderState());
  final _delayed = Delayed(milliseconds: 700);
  static const _store = CustomerCartStore();

  /// 4xx means the server actively rejected the change; everything else
  /// (network layer, 5xx) is transient and coalesces into the outbox.
  bool _isTransientStatus(int status) => status < 400 || status >= 500;

  Future<void> _persistLocalCart() async {
    final cart = state.cart;
    if (cart == null) {
      await _store.clear();
    } else {
      await _store.save(cart);
    }
  }

  /// Latest-wins snapshot of the (single-user) cart for the `cart.sync` op.
  Map<String, dynamic> _cartSnapshot() {
    final details = state.cart?.userCarts?.isNotEmpty == true
        ? (state.cart?.userCarts?.first.cartDetails ?? <CartDetail>[])
        : <CartDetail>[];
    return {
      'shopId': state.cart?.shopId,
      'cartId': state.cart?.id,
      'items': [
        for (final detail in details)
          {
            'stockId': detail.stock?.id,
            'quantity': detail.quantity ?? 1,
            'addons': [
              for (final Addons addon in detail.addons ?? [])
                {'stockId': addon.stocks?.id, 'quantity': addon.quantity},
            ],
          },
      ],
    };
  }

  /// One pending `cart.sync` op per cart: replaces any earlier queued
  /// snapshot instead of stacking ops (dedupe by shop).
  Future<void> _enqueueCartSync({
    Map<String, dynamic>? snapshot,
    bool kickNow = false,
  }) async {
    final engine = SyncEngine();
    final payload = snapshot ?? _cartSnapshot();
    await engine.enqueueOrReplace(
      opType: kCartSyncOpType,
      sdk: 'orders_sdk',
      dedupeKey: (payload['shopId'] ?? '').toString(),
      payload: payload,
    );
    if (kickNow) {
      unawaited(engine.kick());
    }
  }

  Future<void> addCount(BuildContext context, int index) async {
    state = state.copyWith(isAddAndRemoveLoading: true);
    CartDetail oldDetail =
        state.cart?.userCarts?.first.cartDetails?[index] ?? CartDetail();
    CartDetail newDetail = oldDetail.copyWith(
      quantity: 1 + (oldDetail.quantity ?? 1),
    );
    if (!(((oldDetail.quantity ?? 1)) <
        (oldDetail.stock?.product?.maxQty ?? 1))) {
      if (context.mounted) {
        AppHelpers.showCheckTopSnackBarInfo(
          context,
          "${AppHelpers.getTranslation(TrKeys.maxQty)} ${((oldDetail.quantity ?? 1))}",
        );
      }
      state = state.copyWith(isAddAndRemoveLoading: false);
      return;
    }
    List<CartDetail> newCartList =
        state.cart?.userCarts?.first.cartDetails ?? [];
    newCartList.removeAt(index);
    newCartList.insert(index, newDetail);
    UserCart newCart = state.cart!.userCarts!.first.copyWith(
      cartDetails: newCartList,
    );
    List<UserCart> newUserCart = state.cart?.userCarts ?? [];
    newUserCart.removeAt(0);
    newUserCart.insert(0, newCart);
    Cart newDate = state.cart!.copyWith(userCarts: newUserCart);
    state = state.copyWith(cart: newDate);
    await _persistLocalCart();
    final connected = await AppConnectivity.connectivity();
    if (!connected) {
      state = state.copyWith(isAddAndRemoveLoading: false);
      await _enqueueCartSync();
      return;
    }
    List<CartRequest> list = [
      CartRequest(
        stockId:
            state.cart?.userCarts?.first.cartDetails?[index].stock?.id ?? "",
        quantity:
            state.cart?.userCarts?.first.cartDetails?[index].quantity ?? 1,
      ),
    ];
    for (Addons element
        in state.cart?.userCarts?.first.cartDetails?[index].addons ?? []) {
      list.add(
        CartRequest(
          stockId: element.stocks?.id,
          quantity: element.quantity,
          parentId:
              state.cart?.userCarts?.first.cartDetails?[index].stock?.id ?? "",
        ),
      );
    }
    final response = await _cartRepository.insertCart(
      cart: CartRequest(
        shopId: state.cart?.shopId ?? "",
        stockId:
            state.cart?.userCarts?.first.cartDetails?[index].stock?.id ?? "",
        quantity:
            state.cart?.userCarts?.first.cartDetails?[index].quantity ?? 1,
        carts: list,
      ),
    );
    await response.when(
      success: (data) async {
        state = state.copyWith(cart: data.data, isAddAndRemoveLoading: false);
        await _persistLocalCart();
      },
      failure: (failure, status) async {
        state = state.copyWith(isAddAndRemoveLoading: false);
        if (_isTransientStatus(status)) {
          await _enqueueCartSync();
        } else if (context.mounted) {
          AppHelpers.showCheckTopSnackBar(context, failure);
        }
      },
    );
  }

  Future<void> removeCount(BuildContext context, int index) async {
    state = state.copyWith(isAddAndRemoveLoading: true);
    if ((state.cart?.userCarts?.first.cartDetails?[index].quantity ?? 1) > 1) {
      CartDetail oldDetail =
          state.cart?.userCarts?.first.cartDetails?[index] ?? CartDetail();
      CartDetail newDetail = oldDetail.copyWith(
        quantity: (oldDetail.quantity ?? 1) - 1,
      );
      List<CartDetail> newCartList =
          state.cart?.userCarts?.first.cartDetails ?? [];
      newCartList.removeAt(index);
      newCartList.insert(index, newDetail);
      UserCart newCart = state.cart!.userCarts!.first.copyWith(
        cartDetails: newCartList,
      );
      List<UserCart> newUserCart = state.cart?.userCarts ?? [];
      newUserCart.removeAt(0);
      newUserCart.insert(0, newCart);
      Cart newDate = state.cart!.copyWith(userCarts: newUserCart);
      state = state.copyWith(cart: newDate);
      await _persistLocalCart();
      final connected = await AppConnectivity.connectivity();
      if (!connected) {
        state = state.copyWith(isAddAndRemoveLoading: false);
        await _enqueueCartSync();
        return;
      }
      List<CartRequest> list = [
        CartRequest(
          stockId:
              state.cart?.userCarts?.first.cartDetails?[index].stock?.id ?? "",
          quantity:
              state.cart?.userCarts?.first.cartDetails?[index].quantity ?? 1,
        ),
      ];
      for (Addons element
          in state.cart?.userCarts?.first.cartDetails?[index].addons ?? []) {
        list.add(
          CartRequest(
            stockId: element.stocks?.id,
            quantity: element.quantity,
            parentId:
                state.cart?.userCarts?.first.cartDetails?[index].stock?.id ??
                    "",
          ),
        );
      }
      final response = await _cartRepository.insertCart(
        cart: CartRequest(
          shopId: state.cart?.shopId ?? "",
          stockId:
              state.cart?.userCarts?.first.cartDetails?[index].stock?.id ?? "",
          quantity:
              state.cart?.userCarts?.first.cartDetails?[index].quantity ?? 1,
          carts: list,
        ),
      );
      await response.when(
        success: (data) async {
          state = state.copyWith(
            cart: data.data,
            isAddAndRemoveLoading: false,
          );
          await _persistLocalCart();
          getCart(context, () {}, isShowLoading: false);
        },
        failure: (failure, status) async {
          state = state.copyWith(isAddAndRemoveLoading: false);
          if (_isTransientStatus(status)) {
            await _enqueueCartSync();
          } else if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(context, failure);
          }
        },
      );
    } else {
      final cartId = state.cart?.id ?? "";
      final cartDetailId =
          state.cart?.userCarts?.first.cartDetails?[index].id ?? "";
      final shopId = state.cart?.shopId;
      List<CartDetail> newCartList =
          state.cart?.userCarts?.first.cartDetails ?? [];
      newCartList.removeAt(index);
      UserCart newCart = state.cart!.userCarts!.first.copyWith(
        cartDetails: newCartList,
      );
      List<UserCart> newUserCart = state.cart?.userCarts ?? [];
      newUserCart.removeAt(0);
      newUserCart.insert(0, newCart);
      Cart newDate = state.cart!.copyWith(userCarts: newUserCart);
      if (newDate.userCarts!.first.cartDetails!.isEmpty) {
        state = state.copyWith(isAddAndRemoveLoading: false, cart: null);
        await _persistLocalCart();
        if (context.mounted) {
          context.maybePop();
        }
        final connected = await AppConnectivity.connectivity();
        if (!connected) {
          await _enqueueCartSync(
            snapshot: {'shopId': shopId, 'cartId': cartId, 'items': []},
          );
          return;
        }
        final responseDelete = await _cartRepository.deleteCart(
          cartId: cartId,
        );
        await responseDelete.when(
          success: (data) async {},
          failure: (failure, status) async {
            if (_isTransientStatus(status)) {
              await _enqueueCartSync(
                snapshot: {'shopId': shopId, 'cartId': cartId, 'items': []},
              );
            } else if (context.mounted) {
              AppHelpers.showCheckTopSnackBar(context, failure);
            }
          },
        );
      } else {
        state = state.copyWith(cart: newDate, isAddAndRemoveLoading: false);
        await _persistLocalCart();
        final connected = await AppConnectivity.connectivity();
        if (!connected) {
          await _enqueueCartSync();
          return;
        }
        final response = await _cartRepository.removeProductCart(
          cartDetailId: cartDetailId,
        );
        await response.when(
          success: (data) async {
            getCart(context, () {}, isShowLoading: false);
          },
          failure: (failure, status) async {
            if (_isTransientStatus(status)) {
              await _enqueueCartSync();
            } else if (context.mounted) {
              AppHelpers.showCheckTopSnackBar(
                context,
                AppHelpers.getTranslation(status.toString()),
              );
            }
          },
        );
      }
    }
  }

  // Group-order carts stay connectivity-gated: the cart is shared live
  // between several users' devices, so a local-first snapshot replace would
  // clobber other members' changes (multi-device offline merge is an
  // explicit non-goal of the sync engine).
  Future<void> addCountWithGroup({
    required BuildContext context,
    required int productIndex,
    required int userIndex,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      CartDetail oldDetail =
          state.cart?.userCarts?[userIndex].cartDetails?[productIndex] ??
              CartDetail();
      CartDetail newDetail = oldDetail.copyWith(
        quantity: 1 + (oldDetail.quantity ?? 1),
      );
      List<CartDetail> newCartList =
          state.cart?.userCarts?[userIndex].cartDetails ?? [];
      newCartList.removeAt(productIndex);
      newCartList.insert(productIndex, newDetail);
      UserCart newCart = state.cart!.userCarts![userIndex].copyWith(
        cartDetails: newCartList,
      );
      List<UserCart> newUserCart = state.cart?.userCarts ?? [];
      newUserCart.removeAt(userIndex);
      newUserCart.insert(userIndex, newCart);
      Cart newDate = state.cart!.copyWith(userCarts: newUserCart);
      state = state.copyWith(cart: newDate);
      _delayed.run(() async {
        state = state.copyWith(isAddAndRemoveLoading: true);
        List<CartRequest> list = [
          CartRequest(
            stockId: state.cart?.userCarts?[userIndex]
                    .cartDetails?[productIndex].stock?.id ??
                "",
            quantity: state.cart?.userCarts?[userIndex]
                    .cartDetails?[productIndex].quantity ??
                1,
          ),
        ];
        for (Addons element in state.cart?.userCarts?[userIndex]
                .cartDetails?[productIndex].addons ??
            []) {
          list.add(
            CartRequest(
              stockId: element.stocks?.id,
              quantity: element.quantity,
              parentId: state.cart?.userCarts?[userIndex]
                      .cartDetails?[productIndex].stock?.id ??
                  "",
            ),
          );
        }
        final response = await _cartRepository.insertCartWithGroup(
          cart: CartRequest(
            cartId: state.cart?.id.toString(),
            userUuid: state.cart?.userCarts?[userIndex].uuid,
            shopId: state.cart?.shopId ?? "",
            stockId: state.cart?.userCarts?[userIndex]
                    .cartDetails?[productIndex].stock?.id ??
                "",
            quantity: state.cart?.userCarts?[userIndex]
                    .cartDetails?[productIndex].quantity ??
                1,
            carts: list,
          ),
        );
        response.when(
          success: (data) async {
            state = state.copyWith(
              cart: data.data,
              isAddAndRemoveLoading: false,
            );
          },
          failure: (failure, status) {
            state = state.copyWith(isAddAndRemoveLoading: false);
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(status.toString()),
            );
          },
        );
      });
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> removeCountWithGroup({
    required BuildContext context,
    required int productIndex,
    required int userIndex,
  }) async {
    if ((state.cart?.userCarts?[userIndex].cartDetails?[productIndex]
                .quantity ??
            1) >
        1) {
      final connected = await AppConnectivity.connectivity();
      if (connected) {
        CartDetail oldDetail =
            state.cart?.userCarts?[userIndex].cartDetails?[productIndex] ??
                CartDetail();
        CartDetail newDetail = oldDetail.copyWith(
          quantity: (oldDetail.quantity ?? 1) - 1,
        );
        List<CartDetail> newCartList =
            state.cart?.userCarts?[userIndex].cartDetails ?? [];
        newCartList.removeAt(productIndex);
        newCartList.insert(productIndex, newDetail);
        UserCart newCart = state.cart!.userCarts![userIndex].copyWith(
          cartDetails: newCartList,
        );
        List<UserCart> newUserCart = state.cart?.userCarts ?? [];
        newUserCart.removeAt(userIndex);
        newUserCart.insert(userIndex, newCart);
        Cart newDate = state.cart!.copyWith(userCarts: newUserCart);
        state = state.copyWith(cart: newDate);
        _delayed.run(() async {
          state = state.copyWith(isAddAndRemoveLoading: true);
          List<CartRequest> list = [
            CartRequest(
              stockId: state.cart?.userCarts?[userIndex]
                      .cartDetails?[productIndex].stock?.id ??
                  "",
              quantity: state.cart?.userCarts?[userIndex]
                      .cartDetails?[productIndex].quantity ??
                  1,
            ),
          ];
          for (Addons element in state.cart?.userCarts?[userIndex]
                  .cartDetails?[productIndex].addons ??
              []) {
            list.add(
              CartRequest(
                stockId: element.stocks?.id,
                quantity: element.quantity,
                parentId: state.cart?.userCarts?[userIndex]
                        .cartDetails?[productIndex].stock?.id ??
                    "",
              ),
            );
          }
          final response = await _cartRepository.insertCartWithGroup(
            cart: CartRequest(
              cartId: state.cart?.id.toString(),
              userUuid: state.cart?.userCarts?[userIndex].uuid,
              shopId: state.cart?.shopId ?? "",
              stockId: state.cart?.userCarts?[userIndex]
                      .cartDetails?[productIndex].stock?.id ??
                  "",
              quantity: state.cart?.userCarts?[userIndex]
                      .cartDetails?[productIndex].quantity ??
                  1,
              carts: list,
            ),
          );
          response.when(
            success: (data) async {
              state = state.copyWith(
                cart: data.data,
                isAddAndRemoveLoading: false,
              );
              getCart(context, () {}, isShowLoading: false);
            },
            failure: (failure, status) {
              state = state.copyWith(isAddAndRemoveLoading: false);
              AppHelpers.showCheckTopSnackBar(
                context,
                AppHelpers.getTranslation(status.toString()),
              );
            },
          );
        });
      } else {
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    } else {
      final connected = await AppConnectivity.connectivity();
      if (connected) {
        state = state.copyWith(isAddAndRemoveLoading: true);
        final cartId = state.cart?.id ?? "";
        final cartDetailId =
            state.cart?.userCarts?[userIndex].cartDetails?[productIndex].id ??
                "";
        List<CartDetail> newCartList =
            state.cart?.userCarts?[userIndex].cartDetails ?? [];
        newCartList.removeAt(productIndex);
        UserCart newCart = state.cart!.userCarts![userIndex].copyWith(
          cartDetails: newCartList,
        );
        List<UserCart> newUserCart = state.cart?.userCarts ?? [];
        newUserCart.removeAt(userIndex);
        newUserCart.insert(userIndex, newCart);
        Cart newDate = state.cart!.copyWith(userCarts: newUserCart);
        if (newDate.userCarts![userIndex].cartDetails!.isEmpty) {
          final responseDelete = await _cartRepository.deleteCart(
            cartId: cartId,
          );
          responseDelete.when(
            success: (data) async {
              state = state.copyWith(isAddAndRemoveLoading: false, cart: null);
              context.maybePop();
              getCart(context, () {}, isShowLoading: false);
            },
            failure: (failure, status) {
              state = state.copyWith(isAddAndRemoveLoading: false);
              AppHelpers.showCheckTopSnackBar(
                context,
                AppHelpers.getTranslation(status.toString()),
              );
            },
          );
        } else {
          state = state.copyWith(cart: newDate);
          final response = await _cartRepository.removeProductCart(
            cartDetailId: cartDetailId,
          );
          response.when(
            success: (data) async {
              state = state.copyWith(isAddAndRemoveLoading: false);
              getCart(context, () {}, isShowLoading: false);
            },
            failure: (failure, status) {
              state = state.copyWith(isAddAndRemoveLoading: false);
              AppHelpers.showCheckTopSnackBar(
                context,
                AppHelpers.getTranslation(status.toString()),
              );
            },
          );
        }
      } else {
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    }
  }

  Future getCart(
    BuildContext context,
    VoidCallback onSuccess, {
    bool isShowLoading = true,
    String? shopId,
    String? cartId,
    String? userUuid,
  }) async {
    // A queued cart.sync means the server cart lags this device's local
    // document; show the local cart and let the engine catch the server up
    // before trusting server reads again.
    if (await SyncEngine().hasPending(kCartSyncOpType)) {
      final local = await _store.load();
      if (isShowLoading) {
        state = state.copyWith(cart: local, isLoading: false);
        onSuccess();
      } else {
        state = state.copyWith(cart: local);
      }
      unawaited(SyncEngine().kick());
      return;
    }
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (isShowLoading) {
        state = state.copyWith(isLoading: true);
      }

      final response = (userUuid == null || userUuid.isEmpty)
          ? await _cartRepository.getCart(
              shopId ??
                  (state.cart?.shopId != null
                      ? state.cart!.shopId.toString()
                      : ""),
            )
          : await _cartRepository.getCartInGroup(cartId, shopId, userUuid);

      response.when(
        success: (data) async {
          if (isShowLoading) {
            state = state.copyWith(cart: data.data, isLoading: false);
            onSuccess();
          } else {
            state = state.copyWith(cart: data.data);
          }
          await _persistLocalCart();
        },
        failure: (failure, status) {
          if (status == 404) {
            if (isShowLoading) {
              state = state.copyWith(isLoading: false, cart: null);
            } else {
              state = state.copyWith(cart: null);
            }
            unawaited(_store.clear());
          } else if (status == 400 || status == 404) {
            AppHelpers.showCheckTopSnackBarDone(
              context,
              AppHelpers.getTranslation(TrKeys.thankYouForOrder),
            );
            state = state.copyWith(cart: null, isStartGroup: false);
            Navigator.pop(context);
          } else if (status != 401) {
            if (isShowLoading) {
              state = state.copyWith(isLoading: false);
            }
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(status.toString()),
            );
          } else {
            if (isShowLoading) {
              state = state.copyWith(isLoading: false);
            }
            LocalStorage.logout();
            context.router.popUntilRoot();
            AppRoutes.I.replaceLoginRoute(context);
          }
        },
      );
    } else {
      final local = await _store.load();
      if (local != null) {
        if (isShowLoading) {
          state = state.copyWith(cart: local, isLoading: false);
          onSuccess();
        } else {
          state = state.copyWith(cart: local);
        }
      } else if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future changeStatus(BuildContext context, String? userUuid) async {
    final connected = await AppConnectivity.connectivity();
    state = state.copyWith(isEditOrder: !state.isEditOrder);
    if (connected) {
      final response = await _cartRepository.changeStatus(
        userUuid: userUuid,
        cartId: state.cart?.id.toString(),
      );
      response.when(success: (data) async {}, failure: (failure, status) {});
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
        return;
      }
    }
  }

  Future deleteCart(BuildContext context) async {
    final cartId = state.cart?.id ?? "";
    final shopId = state.cart?.shopId;
    state = state.copyWith(isDeleteLoading: false, cart: null);
    await _store.clear();
    if (context.mounted) {
      Navigator.pop(context);
    }
    final connected = await AppConnectivity.connectivity();
    if (!connected) {
      await _enqueueCartSync(
        snapshot: {'shopId': shopId, 'cartId': cartId, 'items': []},
      );
      return;
    }
    final response = await _cartRepository.deleteCart(cartId: cartId);
    await response.when(
      success: (data) async {},
      failure: (failure, status) async {
        if (_isTransientStatus(status)) {
          await _enqueueCartSync(
            snapshot: {'shopId': shopId, 'cartId': cartId, 'items': []},
          );
        } else if (context.mounted) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(status.toString()),
          );
        }
      },
    );
  }

  Future<void> deleteUser(
    BuildContext context,
    int index, {
    String? userId,
  }) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (userId == null) {
        _cartRepository.deleteUser(
          cartId: state.cart?.id ?? "",
          userId: state.cart?.userCarts?[index].uuid ?? "",
        );
        Cart? cart = state.cart;
        List<UserCart>? list = cart?.userCarts;
        list?.removeAt(index);
        Cart? newCart = cart?.copyWith(userCarts: list);
        state = state.copyWith(cart: newCart);
      } else {
        if (context.mounted) {
          context.maybePop();
        }
        _cartRepository.deleteUser(
          cartId: state.cart?.id ?? "",
          userId: userId,
        );
        state = state.copyWith(isStartGroup: false, cart: null);
      }
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
        return;
      }
    }
  }

  void joinGroupOrder(BuildContext context) async {
    state = state.copyWith(isStartGroup: false);
    state = state.copyWith(isStartGroup: true);
  }

  Future<void> startGroupOrder(BuildContext context, String cartId) async {
    final connected = await AppConnectivity.connectivity();
    state = state.copyWith(isStartGroup: false, isStartGroupLoading: true);
    if (connected) {
      final response = await _cartRepository.startGroupOrder(cartId: cartId);
      response.when(
        success: (data) async {
          Cart? cart = state.cart;
          Cart? newCart = cart?.copyWith(group: true);
          state = state.copyWith(
            cart: newCart,
            isStartGroup: true,
            isStartGroupLoading: false,
          );
        },
        failure: (failure, status) {
          state = state.copyWith(
            isStartGroup: false,
            isStartGroupLoading: false,
          );
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(status.toString()),
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  void createCart(BuildContext context, String shopId) async {
    state = state.copyWith(isCheckShopOrder: false, isOtherShop: false);
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isCheckShopOrder: true);
      final response = await _cartRepository.createCart(
        cart: CartRequest(shopId: shopId),
      );
      response.when(
        success: (data) {
          state = state.copyWith(isCheckShopOrder: false, cart: data.data);
          startGroupOrder(context, data.data?.id ?? "");
        },
        failure: (failure, status) {
          state = state.copyWith(isCheckShopOrder: false);
          if (status == 400) {
            state = state.copyWith(isOtherShop: true);
          } else {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(status.toString()),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  generateShareLink(String shopName, String shopLogo, String? type) async {
    final productLink =
        "${AppConstants.webUrl}/group/${state.cart?.shopId}?g=${state.cart?.id}&o=${state.cart?.ownerId}&t=${type ?? 'shop'}";

    final dynamicLink =
        'https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=${AppConstants.firebaseWebKey}';

    final dataShare = {
      "dynamicLinkInfo": {
        "domainUriPrefix": AppConstants.uriPrefix,
        "link": productLink,
        "androidInfo": {
          "androidPackageName": AppConstants.androidPackageName,
          "androidFallbackLink":
              "${AppConstants.webUrl}/group/${state.cart?.shopId}?g=${state.cart?.id}&o=${state.cart?.ownerId}&t=${type ?? 'shop'}",
        },
        "iosInfo": {
          "iosBundleId": AppConstants.iosPackageName,
          "iosFallbackLink":
              "${AppConstants.webUrl}/group/${state.cart?.shopId}?g=${state.cart?.id}&o=${state.cart?.ownerId}&t=${type ?? 'shop'}",
        },
        "socialMetaTagInfo": {
          "socialTitle": AppHelpers.getTranslation(TrKeys.groupOrder),
          "socialDescription": shopName,
          "socialImageLink": shopLogo,
        },
      },
    };

    final res = await http.post(
      Uri.parse(dynamicLink),
      body: jsonEncode(dataShare),
    ).timeout(const Duration(seconds: 30));

    state = state.copyWith(shareLink: jsonDecode(res.body)['shortLink']);

    debugPrint(
      "share link shop_order_notifier: ${state.shareLink}\n$dataShare",
    );
  }
}
