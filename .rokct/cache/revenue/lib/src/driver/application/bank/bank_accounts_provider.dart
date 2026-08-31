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
import 'package:get_it/get_it.dart';

import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';
import 'package:revenue_sdk/src/driver/application/bank/bank_accounts_notifier.dart';
import 'package:revenue_sdk/src/driver/application/bank/bank_accounts_state.dart';

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
