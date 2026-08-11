// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auto_order_state.freezed.dart';

@freezed
class AutoOrderState with _$AutoOrderState {
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
