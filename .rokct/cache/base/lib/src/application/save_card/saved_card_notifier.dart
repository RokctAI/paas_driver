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


import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/application/save_card/saved_cards_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class SavedCardsNotifier extends StateNotifier<SavedCardsState> {
  SavedCardsNotifier() : super(const SavedCardsState()) {
    loadSavedCards();
  }

  final _repository = paymentsRepository;

  Future<void> loadSavedCards() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _repository.getSavedCards();

      result.when(
        success: (cards) {
          state = state.copyWith(cards: cards, isLoading: false);
        },
        failure: (error, statusCode) {
          state = state.copyWith(isLoading: false, error: error.toString());
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveCard({
    required String cardNumber,
    required String cardName,
    required String expiryDate,
    required String cvc,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _repository.tokenizeAfterPayment(
        cardNumber,
        cardName,
        expiryDate,
        cvc,
      );

      bool success = false;

      result.when(
        success: (token) {
          success = true;
          // Reload cards to get the newly saved one
          loadSavedCards();
        },
        failure: (error, statusCode) {
          state = state.copyWith(isLoading: false, error: error.toString());
        },
      );

      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteCard(String cardId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final result = await _repository.deleteCard(cardId);

      bool success = false;
      result.when(
        success: (data) {
          // Remove card from state
          final updatedCards =
              state.cards.where((card) => card.id != cardId).toList();
          state = state.copyWith(cards: updatedCards, isLoading: false);
          success = true;
        },
        failure: (error, statusCode) {
          state = state.copyWith(isLoading: false, error: error.toString());
        },
      );

      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
