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

import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/data/currency_data.dart';
import 'package:base_sdk/src/models/data/location.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/models/response/transactions_response.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/collect_conversion.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/order_calculate_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/order_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/payment_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/product_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/stock.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/user_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/create_order_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/order_status_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/orders_paginate_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/payments_response.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/response/single_order_response.dart';

/// Demo-only [SellerOrdersRepositoryFacade] (`--dart-define=IS_DEMO=true`):
/// serves a small, fictional shift of seller orders entirely from memory, so
/// the manager order board and `/order-history` render stocked instead of
/// showing their empty states in demo builds. Selected in place of
/// [SellerOrdersRepository]'s HTTP path by `ManagerOrdersDependencies` — the
/// same `AppConstants.isDemo` ternary products_sdk's `ProductsSdkDependencies`
/// and merchants_sdk's `ManagerMerchantsDependencies` already apply
/// (zones_sdk's `DemoDriverDeliveryZonesRepository` precedent).
///
/// Never used in production: every write is acknowledged locally, nothing
/// leaves the device and no HTTP client is constructed. The seed is
/// deliberately obvious fiction — placeholder customers, a fictional shop's
/// dishes — priced in South African rand because the demo shop trades in ZAR.
///
/// Session-local by design (the [DemoDriverDeliveryZonesRepository] overlay
/// convention): status moves and POS sales made during a tour stick for the
/// rest of the process and reset on the next launch. Nothing is persisted.
class DemoSellerOrdersRepository implements SellerOrdersRepositoryFacade {
  /// The board never asks for more than a page at a time and the notifiers
  /// stop paging as soon as a page comes back short (`length >= 10`), so the
  /// whole seed fits comfortably inside page 1 of every column.
  static const int _pageSize = 10;

  static final CurrencyData _rand = CurrencyData(
    id: 'ZAR',
    symbol: 'R',
    title: 'South African Rand',
    rate: 1,
    isDefault: true,
    active: true,
    position: 'before',
  );

  /// Wall-clock anchor for the seeded shift, resolved once per launch so the
  /// board's times read as "today" whenever the tour runs.
  static final DateTime _today = DateTime.now();

  static String _date(DateTime moment) =>
      '${moment.year.toString().padLeft(4, '0')}-'
      '${moment.month.toString().padLeft(2, '0')}-'
      '${moment.day.toString().padLeft(2, '0')}';

  static String _clock(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static UserData _customer({
    required String id,
    required String firstname,
    required String lastname,
  }) =>
      UserData(
        id: id,
        uuid: 'demo_user_$id',
        firstname: firstname,
        lastname: lastname,
        email: '$firstname.$lastname@example.com'.toLowerCase(),
        phone: '+27 82 000 00$id',
        active: true,
        role: 'user',
      );

  static Transaction _paidWith(String tag, num price) => Transaction(
        id: 'demo_trx_$tag',
        price: price,
        status: 'paid',
        paymentSystem: PaymentData(id: tag, tag: tag, active: true),
      );

  static OrderDetail _line({
    required String id,
    required String title,
    required num price,
    required int quantity,
  }) =>
      OrderDetail(
        id: id,
        quantity: quantity,
        originPrice: price,
        totalPrice: price * quantity,
        tax: 0,
        discount: 0,
        stock: Stock(
          id: id,
          price: price,
          quantity: quantity,
          totalPrice: price * quantity,
          product: ProductData(
            id: id,
            uuid: 'demo_product_$id',
            translation: Translation(title: title, locale: 'en'),
          ),
        ),
      );

  /// The seeded shift. Mixed states, believable rand totals and times that
  /// walk backwards through the trading day, so the board's columns and the
  /// history list are both populated without being cluttered: four live
  /// orders across new/accepted/ready and three finished ones.
  static List<OrderData> _seed() => <OrderData>[
        OrderData(
          id: 'DEMO-1041',
          userId: '1',
          status: 'new',
          deliveryType: 'delivery',
          totalPrice: 248.50,
          deliveryFee: 25,
          tax: 0,
          currency: _rand,
          user: _customer(id: '1', firstname: 'Thandi', lastname: 'Mokoena'),
          deliveryDate: _date(_today),
          deliveryTime: _clock(12, 40),
          createdAt: _date(_today),
          transaction: _paidWith('cash', 248.50),
          location: LocationModel(latitude: -26.2041, longitude: 28.0473),
          details: <OrderDetail>[
            _line(
                id: '1',
                title: 'Peri-peri chicken wrap',
                price: 89.00,
                quantity: 2),
            _line(id: '2', title: 'Chakalaka fries', price: 45.50, quantity: 1),
          ],
        ),
        OrderData(
          id: 'DEMO-1040',
          userId: '2',
          status: 'new',
          deliveryType: 'dine_in',
          totalPrice: 132.00,
          deliveryFee: 0,
          tax: 0,
          currency: _rand,
          user: _customer(id: '2', firstname: 'Sipho', lastname: 'Dlamini'),
          deliveryDate: _date(_today),
          deliveryTime: _clock(12, 25),
          createdAt: _date(_today),
          transaction: _paidWith('cash', 132.00),
          details: <OrderDetail>[
            _line(
                id: '3',
                title: 'Bunny chow (quarter)',
                price: 66.00,
                quantity: 2),
          ],
        ),
        OrderData(
          id: 'DEMO-1039',
          userId: '3',
          status: 'accepted',
          deliveryType: 'pickup',
          totalPrice: 96.00,
          deliveryFee: 0,
          tax: 0,
          currency: _rand,
          user: _customer(id: '3', firstname: 'Lerato', lastname: 'Naidoo'),
          deliveryDate: _date(_today),
          deliveryTime: _clock(12, 10),
          createdAt: _date(_today),
          transaction: _paidWith('wallet', 96.00),
          details: <OrderDetail>[
            _line(id: '4', title: 'Boerewors roll', price: 48.00, quantity: 2),
          ],
        ),
        OrderData(
          id: 'DEMO-1038',
          userId: '4',
          status: 'ready',
          deliveryType: 'delivery',
          totalPrice: 415.75,
          deliveryFee: 25,
          tax: 0,
          currency: _rand,
          user: _customer(id: '4', firstname: 'Ayanda', lastname: 'Khumalo'),
          deliveryDate: _date(_today),
          deliveryTime: _clock(11, 55),
          createdAt: _date(_today),
          transaction: _paidWith('cash', 415.75),
          location: LocationModel(latitude: -26.1952, longitude: 28.0340),
          details: <OrderDetail>[
            _line(
                id: '5',
                title: 'Family braai platter',
                price: 390.75,
                quantity: 1),
          ],
        ),
        OrderData(
          id: 'DEMO-1037',
          userId: '5',
          status: 'delivered',
          deliveryType: 'delivery',
          totalPrice: 187.00,
          deliveryFee: 25,
          tax: 0,
          currency: _rand,
          user: _customer(id: '5', firstname: 'Nomsa', lastname: 'Petersen'),
          deliverymanName: 'Bongani M.',
          deliveryDate: _date(_today),
          deliveryTime: _clock(11, 20),
          createdAt: _date(_today),
          transaction: _paidWith('cash', 187.00),
          details: <OrderDetail>[
            _line(id: '6', title: 'Gatsby (half)', price: 81.00, quantity: 2),
          ],
        ),
        OrderData(
          id: 'DEMO-1036',
          userId: '6',
          status: 'delivered',
          deliveryType: 'pickup',
          totalPrice: 74.50,
          deliveryFee: 0,
          tax: 0,
          currency: _rand,
          user: _customer(id: '6', firstname: 'Kagiso', lastname: 'Steyn'),
          deliveryDate: _date(_today),
          deliveryTime: _clock(10, 45),
          createdAt: _date(_today),
          transaction: _paidWith('cash', 74.50),
          details: <OrderDetail>[
            _line(
                id: '7',
                title: 'Vetkoek and mince',
                price: 37.25,
                quantity: 2),
          ],
        ),
        OrderData(
          id: 'DEMO-1035',
          userId: '7',
          status: 'delivered',
          deliveryType: 'dine_in',
          totalPrice: 322.00,
          deliveryFee: 0,
          tax: 0,
          currency: _rand,
          user: _customer(id: '7', firstname: 'Zanele', lastname: 'Botha'),
          deliveryDate: _date(_today.subtract(const Duration(days: 1))),
          deliveryTime: _clock(19, 30),
          createdAt: _date(_today.subtract(const Duration(days: 1))),
          transaction: _paidWith('wallet', 322.00),
          details: <OrderDetail>[
            _line(
                id: '8',
                title: 'Seafood potjie for two',
                price: 161.00,
                quantity: 2),
          ],
        ),
      ];

  /// Session-local overlay: seeded lazily on first read so the seed's
  /// "today" is the launch day, then mutated in place by
  /// [updateOrderStatus] / [createOrder] for the rest of the session.
  static List<OrderData>? _orders;

  static List<OrderData> get _all => _orders ??= _seed();

  /// Ids handed to orders created during the session, continuing the seed's
  /// run so a POS sale reads as the next ticket off the same pad.
  static int _nextId = 1042;

  /// Drops the overlay so the next read re-seeds. Mirrors
  /// `DemoDriverDeliveryZonesRepository.reset()`; used by tests.
  static void reset() {
    _orders = null;
    _nextId = 1042;
  }

  /// The legacy wire strings, identical to [SellerOrdersRepository]'s and to
  /// `BoardStatus.wire`.
  static String? _statusText(OrderStatus? status) {
    switch (status) {
      case OrderStatus.open:
        return 'new';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.onWay:
        return 'on_a_way';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.canceled:
        return 'canceled';
      default:
        return null;
    }
  }

  /// Counts every column off the live overlay, so the board's pills and the
  /// history total stay consistent with the rows actually served — including
  /// after a status move made during the session.
  static OrdersStatistic _statistic() {
    int count(String wire) =>
        _all.where((OrderData order) => order.status == wire).length;
    final int delivered = count('delivered');
    final int canceled = count('canceled');
    return OrdersStatistic(
      newOrdersCount: count('new'),
      acceptedOrdersCount: count('accepted'),
      cookingOrdersCount: count('cooking'),
      readyOrdersCount: count('ready'),
      onAWayOrdersCount: count('on_a_way'),
      deliveredOrdersCount: delivered,
      cancelOrdersCount: canceled,
      progressOrdersCount: _all.length - delivered - canceled,
      ordersCount: _all.length,
      totalPrice: _all.fold<num>(
        0,
        (num sum, OrderData order) => sum + (order.totalPrice ?? 0),
      ),
      todayCount: _all.length,
    );
  }

  /// One page of [rows]. Page 1 (or an unpaged call) is the only page that
  /// can be non-empty here — the whole seed is smaller than [_pageSize], so
  /// the notifiers' `length >= 10` check stops them after it.
  static OrdersPaginateResponse _page(List<OrderData> rows, int? page) {
    final int start = ((page ?? 1) - 1) * _pageSize;
    final int end =
        start + _pageSize < rows.length ? start + _pageSize : rows.length;
    final List<OrderData> slice =
        start >= rows.length ? const <OrderData>[] : rows.sublist(start, end);
    return OrdersPaginateResponse(
      data: OrderResponseData(statistic: _statistic(), orders: slice),
    );
  }

  @override
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    String? rawStatus,
    int? page,
    String? from,
    String? to,
  }) async {
    // [rawStatus] wins when both are passed — the facade's documented rule
    // (the board's `cooking` column has no [OrderStatus] member).
    final String? wire = rawStatus ?? _statusText(status);
    final List<OrderData> rows = wire == null
        ? _all
        : _all.where((OrderData order) => order.status == wire).toList();
    return ApiResult<OrdersPaginateResponse>.success(data: _page(rows, page));
  }

  @override
  Future<ApiResult<OrdersPaginateResponse>> getHistoryOrders({
    int? page,
    String? from,
    String? to,
  }) async {
    // History is the two terminal columns, newest first — the pair the real
    // repository asks the backend for.
    final List<OrderData> rows = _all
        .where((OrderData order) =>
            order.status == 'delivered' || order.status == 'canceled')
        .toList();
    return ApiResult<OrdersPaginateResponse>.success(data: _page(rows, page));
  }

  @override
  Future<ApiResult<SingleOrderResponse>> getOrderDetails({
    required String orderId,
  }) async {
    for (final OrderData order in _all) {
      if (order.id == orderId) {
        return ApiResult<SingleOrderResponse>.success(
          data: SingleOrderResponse(data: order),
        );
      }
    }
    // Unknown id: hand back the first seeded order rather than an error, so a
    // deep link taken during a tour can never dead-end on a failure sheet.
    return ApiResult<SingleOrderResponse>.success(
      data: SingleOrderResponse(data: _all.first),
    );
  }

  @override
  Future<ApiResult<OrderStatusResponse>> updateOrderStatus({
    OrderStatus? status,
    String? rawStatus,
    required String orderId,
  }) async {
    final String wire = rawStatus ?? _statusText(status) ?? 'new';
    for (int i = 0; i < _all.length; i++) {
      if (_all[i].id == orderId) {
        // copyWith carries every other field through unchanged (its
        // arguments are all `?? current`), so this only moves the column.
        _all[i] = _all[i].copyWith(status: wire);
        break;
      }
    }
    return ApiResult<OrderStatusResponse>.success(
      data: OrderStatusResponse(data: OrderStatusData(status: wire)),
    );
  }

  @override
  Future<ApiResult<CollectConversion>> convertDeliveryToCollected({
    required String orderId,
  }) async {
    int index = -1;
    for (int i = 0; i < _all.length; i++) {
      if (_all[i].id == orderId) {
        index = i;
        break;
      }
    }
    final OrderData? target = index < 0 ? null : _all[index];
    final num fee = target?.deliveryFee ?? 0;
    final num before = target?.totalPrice ?? 0;
    // No driver is ever dispatched in demo, so the fee always goes back —
    // the `refunded` branch of the section-43 outcome.
    final num after = before - fee;
    if (target != null) {
      _all[index] = target.copyWith(
        deliveryType: 'pickup',
        totalPrice: after,
        collectedInPerson: true,
        collectFeeRefunded: fee,
      );
    }
    return ApiResult<CollectConversion>.success(
      data: CollectConversion(
        converted: true,
        deliveryType: 'pickup',
        deliveryFee: fee,
        feeOutcome:
            fee > 0 ? CollectFeeOutcome.refunded : CollectFeeOutcome.none,
        refundedToWallet: fee,
        totalPrice: after,
        totalPriceBefore: before,
      ),
    );
  }

  @override
  Future<ApiResult<CreateOrderResponse>> createOrder({
    required String deliveryType,
    required List<Stock> stocks,
    required String deliveryTime,
    required String address,
    UserData? user,
    LocationModel? location,
    String? entrance,
    String? tableId,
    String? floor,
    String? house,
    String? paymentId,
  }) async {
    final num total = stocks.fold<num>(
      0,
      (num sum, Stock stock) =>
          sum +
          (stock.totalPrice ?? (stock.price ?? 0) * (stock.quantity ?? 1)),
    );
    final String id = 'DEMO-${_nextId++}';
    final DateTime now = DateTime.now();
    _all.insert(
      0,
      OrderData(
        id: id,
        userId: user?.id ?? '1',
        status: 'new',
        deliveryType: deliveryType,
        totalPrice: total,
        deliveryFee: 0,
        tax: 0,
        currency: _rand,
        user: user,
        location: location,
        deliveryDate: _date(now),
        deliveryTime: _clock(now.hour, now.minute),
        createdAt: _date(now),
        // The tag is what the queue card prints, so the demo names the
        // method rather than echoing the payment docname the POS passed.
        transaction: _paidWith('cash', total),
      ),
    );
    return ApiResult<CreateOrderResponse>.success(
      data: CreateOrderResponse(
        data: CreatedOrder(
          id: id,
          userId: user?.id ?? '1',
          price: total,
          rate: 1,
        ),
      ),
    );
  }

  @override
  Future<ApiResult<TransactionsResponse>> createTransaction({
    required String orderId,
    required String paymentId,
  }) async {
    return ApiResult<TransactionsResponse>.success(
      data: TransactionsResponse(
        status: true,
        message: 'Demo transaction recorded locally',
        data: TransactionData(status: 'paid', tag: paymentId, rate: 1),
      ),
    );
  }

  @override
  Future<ApiResult<PaymentsResponse>> getPayments() async {
    return ApiResult<PaymentsResponse>.success(
      data: PaymentsResponse(
        data: <Payment>[
          Payment(
            id: 'cash',
            shopId: '1',
            status: 1,
            payment: PaymentData(id: 'cash', tag: 'cash', active: true),
          ),
          Payment(
            id: 'wallet',
            shopId: '1',
            status: 1,
            payment: PaymentData(id: 'wallet', tag: 'wallet', active: true),
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResult<OrderCalculate>> getCalculate({
    required List<Stock> stocks,
    required String type,
    LocationModel? location,
  }) async {
    final num price = stocks.fold<num>(
      0,
      (num sum, Stock stock) =>
          sum +
          (stock.totalPrice ?? (stock.price ?? 0) * (stock.quantity ?? 1)),
    );
    // Delivery is the only type that carries a fee in the seeded shop; the
    // rand amounts match the seeded orders above.
    final num deliveryFee = type == 'delivery' ? 25 : 0;
    return ApiResult<OrderCalculate>.success(
      data: OrderCalculate(
        status: true,
        code: '200',
        data: OrderCalculateDetail(
          stocks: stocks,
          price: price,
          totalTax: 0,
          totalShopTax: 0,
          totalDiscount: 0,
          serviceFee: 0,
          deliveryFee: deliveryFee,
          totalPrice: price + deliveryFee,
          rate: 1,
          couponPrice: 0,
        ),
      ),
    );
  }
}
