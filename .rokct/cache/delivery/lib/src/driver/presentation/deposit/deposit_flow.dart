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

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:delivery_sdk/src/driver/application/deposit/deposit_provider.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/deposit_request.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/bank_deposit_sheet.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_grammar.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_method_sheet.dart';
import 'package:delivery_sdk/src/driver/presentation/deposit/deposit_status_page.dart';

/// The three surfaces of the driver's top-up, in order (frames 49g → 49h
/// → 49i), started from any "Top up" the driver app draws: the wallet
/// position card on home (chip 970), the wallet plane's pill (corporate
/// 49f, arriving here as `/driver-deposits?choose=1`) and the status
/// plane's own "Make a deposit".
///
/// The card branch is wallet_sdk's `/wallet-topup`. That SDK is not
/// composed into paas_driver today, so the push is guarded: a composition
/// without the route tells the driver so, instead of a pill that opens
/// nothing (the dead control 49f was drawn to end).
abstract final class DriverDepositFlow {
  /// wallet_sdk's card top-up surface (`process_wallet_top_up` behind it).
  static const String cardTopUpPath = '/wallet-topup';

  /// Frame 49g: the method chooser. Reads chip 975 (where the money goes)
  /// FIRST, so a tenant not accepting bank deposits meets the fact on the
  /// row rather than after a form; reads the balance if the slice has none
  /// yet, so the head states the wallet as a sentence.
  static Future<void> openChooser(
    BuildContext context,
    WidgetRef ref, {
    void Function(DepositRecord sent)? onSubmitted,
    SlipPicker? pickSlip,
  }) async {
    final notifier = ref.read(depositProvider.notifier);
    await notifier.loadDestination(context: context);
    if (ref.read(depositProvider).balance == null) {
      await notifier.load(context: context);
    }
    if (!context.mounted) return;
    final state = ref.read(depositProvider);
    final destination = state.destination;
    // A failed read already spoke (ErrorPresenter / no-connection bar);
    // opening a chooser that cannot name the account would be a second,
    // emptier answer.
    if (destination == null) return;

    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: DepositMethodSheet(
        balance: state.balance,
        bankDepositsAccepted: destination.accepting,
        onCard: () {
          Navigator.of(context).pop();
          openCard(context);
        },
        onBankDeposit: () {
          Navigator.of(context).pop();
          openBankSheet(
            context,
            ref,
            destination,
            onSubmitted: onSubmitted,
            pickSlip: pickSlip,
          );
        },
      ),
    );
  }

  /// The card branch. Guarded: a composition without wallet_sdk's route
  /// hears "not available in this app yet" instead of seeing nothing.
  static Future<void> openCard(BuildContext context) async {
    await context.router.pushNamed(
      cardTopUpPath,
      onFailure: (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppHelpers.getTranslation(
                'card_top_ups_are_not_available_in_this_app_yet',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Frame 49h: the capture sheet. The reference is generated FOR the
  /// driver from his name and the minute (chip 977) so he can write it on
  /// the slip before anything is sent; the amount is prefilled with what
  /// he owes, as a suggestion. On success the sheet closes and, unless the
  /// caller says otherwise, the status plane (49i) opens over the shell.
  static Future<void> openBankSheet(
    BuildContext context,
    WidgetRef ref,
    DepositDestination destination, {
    void Function(DepositRecord sent)? onSubmitted,
    SlipPicker? pickSlip,
    DateTime? now,
  }) async {
    final balance = ref.read(depositProvider).balance;
    final owed = (balance != null && balance < 0) ? balance.abs() : null;
    final user = LocalStorage.getUser();
    final fullName = [user?.firstname, user?.lastname]
        .where((part) => (part ?? '').trim().isNotEmpty)
        .join(' ');
    final reference = suggestedReference(fullName, now ?? DateTime.now());

    AppHelpers.showCustomModalBottomSheet(
      context: context,
      isDarkMode: true,
      modal: Consumer(
        builder: (sheetContext, ref, _) {
          final submitting = ref.watch(depositProvider).isSubmitting;
          return BankDepositSheet(
            destination: destination,
            reference: reference,
            initialAmount: owed,
            submitting: submitting,
            pickSlip: pickSlip ?? pickSlipWithImagePicker,
            onSubmit: (amount, chosenReference, slipPath) {
              ref.read(depositProvider.notifier).submit(
                    context: sheetContext,
                    amount: amount,
                    slipPath: slipPath,
                    reference: chosenReference,
                    onSuccess: (sent) {
                      Navigator.of(sheetContext).pop();
                      if (onSubmitted != null) {
                        onSubmitted(sent);
                      } else if (context.mounted) {
                        DriverDepositStatusPlane.push(context);
                      }
                    },
                  );
            },
          );
        },
      ),
    );
  }
}
