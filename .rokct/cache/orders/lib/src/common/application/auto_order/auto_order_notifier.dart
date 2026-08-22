// Copyright (c) 2026 RokctAI
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

import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:orders_sdk/src/common/application/auto_order/auto_order_state.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/models/data/repeat_data.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

class AutoOrderNotifier extends StateNotifier<AutoOrderState> {
  AutoOrderNotifier()
      : super(
          AutoOrderState(
            from: DateTime.now().add(const Duration(days: 1)),
            to: DateTime.now().add(const Duration(days: 7)),
          ),
        );

  void init(RepeatData data, double grandTotal) {
    state = state.copyWith(
      from: data.from != null ? DateTime.parse(data.from!) : state.from,
      to: data.to != null ? DateTime.parse(data.to!) : null,
      paymentMethod: data.paymentMethod ?? 'Wallet',
      savedCardId: data.savedCard,
      unitPrice: grandTotal,
    );
    fetchBalance();
  }

  Future<void> fetchBalance() async {
    final res = await userRepository.getProfileDetails();
    res.when(
      success: (profile) {
        final wallet = profile.data?.wallet;
        final total = wallet?.price?.toDouble() ?? 0.0;
        final ringfenced = profile.data?.ringfencedBalance?.toDouble() ?? 0.0;

        state = state.copyWith(
          totalBalance: total,
          availableBalance: total - ringfenced,
        );
        calculateProjection();
      },
      failure: (error, _) {},
    );
  }

  void calculateProjection() {
    if (state.unitPrice == 0) return;

    int count = 0;
    if (state.to != null) {
      count = _getExecutionsCount(state.from, state.to!, state.cronPattern);
    } else {
      count = 4; // Default for indefinite
    }

    final estimatedTotal = count * state.unitPrice;
    state = state.copyWith(orderTotal: estimatedTotal);
  }

  int _getExecutionsCount(DateTime start, DateTime end, String cron) {
    int count = 0;
    DateTime current = start;

    // Daily
    if (cron == '0 0 * * *') {
      return end.difference(start).inDays + 1;
    }

    // Weekly (Simplified: every 7 days)
    if (cron == '0 0 * * 1') {
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        if (current.weekday == DateTime.monday) count++;
        current = current.add(const Duration(days: 1));
      }
      return count;
    }

    // Bi-Weekly (1st and 15th)
    if (cron == '0 0 1,15 * *') {
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        if (current.day == 1 || current.day == 15) count++;
        current = current.add(const Duration(days: 1));
      }
      return count;
    }

    // Monthly (1st)
    if (cron == '0 0 1 * *') {
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        if (current.day == 1) count++;
        current = current.add(const Duration(days: 1));
      }
      return count;
    }

    return 4;
  }

  void pickFrom(DateTime date) {
    isValidDates();
    state = state.copyWith(from: date);
  }

  void pickTo(DateTime date) {
    isValidDates();

    state = state.copyWith(to: date);
  }

  void setPeriod(int index) {
    // 0: Daily, 1: Weekly, 2: Bi-Weekly, 3: Monthly
    String cron = '0 0 * * *';
    switch (index) {
      case 1:
        cron = '0 0 * * 1'; // Every Monday
        break;
      case 2:
        cron = '0 0 1,15 * *'; // 1st and 15th
        break;
      case 3:
        cron = '0 0 1 * *'; // 1st of month
        break;
    }
    state = state.copyWith(cronPattern: cron, to: index == 0 ? state.to : null);
  }

  void setPaymentMethod(String method, {String? cardId}) {
    state = state.copyWith(paymentMethod: method, savedCardId: cardId);
  }

  bool isValidDates() {
    if (state.to == null) return true;
    if (state.from.isBefore(state.to!)) {
      state = state.copyWith(isError: false);
      return true;
    } else {
      state = state.copyWith(isError: true);
      return false;
    }
  }

  bool isTimeChanged(RepeatData? repeatData) {
    if (repeatData == null) {
      return true;
    }
    return (((DateTime.parse(
              repeatData.from ?? "",
            ).difference(state.from).inDays) !=
            0) ||
        (state.to != null &&
            (DateTime.parse(
                  repeatData.to ?? "",
                ).difference(state.to!).inDays) !=
                0));
  }

  Future<void> startAutoOrder({
    required String orderId,
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    final res = await ordersRepository.createAutoOrder(
      from: DateFormat('yyyy-MM-dd').format(state.from),
      to: state.to != null ? DateFormat('yyyy-MM-dd').format(state.to!) : null,
      orderId: orderId,
      cronPattern: state.cronPattern,
      paymentMethod: state.paymentMethod,
      savedCardId: state.savedCardId,
    );

    res.when(
      success: (data) {
        onSuccess?.call();
        AppHelpers.showCheckTopSnackBarDone(
          context,
          AppHelpers.getTranslation(TrKeys.autoOrderCreatedSuccessfully),
        );
        context.router.maybePop();
      },
      failure: (error, statusCode) {
        if (error.toString().contains("Suggest Topup")) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(error),
          );
          _showTopUpDialog(context);
        } else {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(error),
          );
        }
      },
    );
  }

  void _showTopUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Insufficient Wallet Balance"),
          content: const Text(
            "Your wallet balance is too low for this auto-order schedule. Would you like to top up from your saved card?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processTopUp(context);
              },
              child: const Text("Top Up & Create"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processTopUp(BuildContext context) async {
    final amount = (state.orderTotal - state.availableBalance).abs();
    if (state.savedCardId == null) {
      AppHelpers.showCheckTopSnackBar(
        context,
        "Please select a Saved Card first.",
      );
      return;
    }

    final res = await walletRepository.walletTopUp(
      amount: amount,
      token: state.savedCardId,
    );

    res.when(
      success: (data) {
        AppHelpers.showCheckTopSnackBarDone(
          context,
          "Wallet topped up successfully! Please click Save again.",
        );
        fetchBalance();
      },
      failure: (e, s) {
        AppHelpers.showCheckTopSnackBar(
          context,
          "Top-up failed: ${e.toString()}",
        );
      },
    );
  }

  Future<void> pauseAutoOrder(String autoOrderId, BuildContext context) async {
    final res = await ordersRepository.pauseAutoOrder(autoOrderId);
    res.when(
      success: (_) {
        AppHelpers.showCheckTopSnackBarDone(context, "Order paused");
      },
      failure: (error, _) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(error),
        );
      },
    );
  }

  Future<void> resumeAutoOrder(String autoOrderId, BuildContext context) async {
    final res = await ordersRepository.resumeAutoOrder(autoOrderId);
    res.when(
      success: (_) {
        AppHelpers.showCheckTopSnackBarDone(context, "Order resumed");
      },
      failure: (error, _) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(error),
        );
      },
    );
  }

  Future<void> deleteAutoOrder({
    required String orderId,
    required BuildContext context,
  }) async {
    final res = await ordersRepository.deleteAutoOrder(orderId);

    res.when(
      success: (data) {
        AppHelpers.showCheckTopSnackBarDone(
          context,
          AppHelpers.getTranslation(TrKeys.autoOrderDeletedSuccessfully),
        );
        context.router.maybePop();
      },
      failure: (error, statusCode) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(error),
        );
      },
    );
  }
}
