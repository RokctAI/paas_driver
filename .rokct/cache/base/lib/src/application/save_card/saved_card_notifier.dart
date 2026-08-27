// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
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
