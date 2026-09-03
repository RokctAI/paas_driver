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
import 'package:get_it/get_it.dart';

import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/common/application/bank/bank_accounts_notifier.dart';
import 'package:revenue_sdk/src/common/application/bank/bank_accounts_state.dart';

/// Same resolution path as the sibling driver slices:
/// [DriverPayoutRepositoryFacade] is registered against `GetIt.instance` by
/// `DriverRevenueDependencies.register(getIt)`.
///
/// Deliberately NOT auto-disposed. The withdraw path pre-reads the accounts
/// before it opens anything (frame 49n), then the bank plane, the form and
/// the sheet all read the same list — a disposal between those steps would
/// re-ask the server for something it just answered, and worse, would let
/// the sheet reopen on a stale "no account" premise.
final bankAccountsProvider =
    StateNotifierProvider<BankAccountsNotifier, BankAccountsState>(
  (ref) => BankAccountsNotifier(
    GetIt.instance<DriverPayoutRepositoryFacade>(),
  ),
);
