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

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';

part 'order_state.freezed.dart';

@freezed
abstract class OrderState with _$OrderState {
  const factory OrderState({
    @Default(false) bool isActiveLoading,
    @Default(false) bool isLoading,
    @Default(false) bool isAvailableLoading,
    @Default(false) bool isHistoryLoading,
    @Default(false) bool paymentType,
    @Default(null) OrderDetailData? order,
    @Default([]) List<OrderDetailData> activeOrders,
    @Default([]) List<OrderDetailData> availableOrders,
    @Default([]) List<OrderDetailData> historyOrders,
    @Default(0) num totalActiveOrder,
    @Default(0) int deliveryTime,
    @Default(0) int deliveryType,
  }) = _OrdrState;

  const OrderState._();
}
