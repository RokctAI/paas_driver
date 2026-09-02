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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/domain/interface/currencies.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';

import 'package:base_sdk/src/application/currency/currency_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  final CurrenciesRepositoryFacade _currenciesRepository;

  CurrencyNotifier(this._currenciesRepository) : super(const CurrencyState());

  Future<void> fetchCurrency(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true);
      final response = await _currenciesRepository.getCurrencies();
      response.when(
        success: (data) async {
          CurrencyData currencyData =
              LocalStorage.getSelectedCurrency() ?? CurrencyData();

          for (int i = 0; i < data.data!.length; i++) {
            if (data.data![i].id == currencyData.id) {
              state = state.copyWith(index: i);
              LocalStorage.setSelectedCurrency(data.data![i]);
              break;
            } else {
              LocalStorage.setSelectedCurrency(data.data![0]);
            }
          }

          state = state.copyWith(isLoading: false, list: data.data ?? []);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  void change(int index) {
    LocalStorage.setSelectedCurrency(state.list[index]);
    state = state.copyWith(index: index);
  }
}
