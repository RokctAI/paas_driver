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

import '../../domain/models/loyalty_models.dart';

class LoyaltyState {
  final bool isLoading;
  final LoyaltyAccount? account;
  final List<LoyaltyTransaction> transactions;
  final String? error;

  const LoyaltyState({
    this.isLoading = false,
    this.account,
    this.transactions = const [],
    this.error,
  });

  LoyaltyState copyWith({
    bool? isLoading,
    LoyaltyAccount? account,
    List<LoyaltyTransaction>? transactions,
    String? error,
  }) {
    return LoyaltyState(
      isLoading: isLoading ?? this.isLoading,
      account: account ?? this.account,
      transactions: transactions ?? this.transactions,
      error: error,
    );
  }
}
