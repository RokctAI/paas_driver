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

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_order_state.freezed.dart';

@freezed
abstract class AutoOrderState with _$AutoOrderState {
  const factory AutoOrderState({
    required DateTime from,
    DateTime? to,
    TimeOfDay? time,
    @Default('0 0 * * *') String cronPattern,
    @Default('Wallet') String paymentMethod,
    String? savedCardId,
    @Default(0.0) double totalBalance,
    @Default(0.0) double availableBalance,
    @Default(0.0) double orderTotal,
    @Default(0.0) double unitPrice,
    @Default(false) isError,
  }) = _AutoOrderState;

  const AutoOrderState._();
}
