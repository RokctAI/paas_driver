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
import 'package:revenue_sdk/src/common/application/payouts/payout_history_notifier.dart';
import 'package:revenue_sdk/src/common/application/payouts/payout_history_state.dart';

/// Same resolution path as the withdraw slice's provider: the payout seam is
/// registered against `GetIt.instance` by
/// `DriverRevenueDependencies.register(getIt)`. Sharing that ONE seam with
/// the withdraw sheet is why a payout the driver has just requested shows up
/// on this trail without a second registration.
final payoutHistoryProvider =
    StateNotifierProvider<PayoutHistoryNotifier, PayoutHistoryState>(
  (ref) => PayoutHistoryNotifier(
    GetIt.instance<DriverPayoutRepositoryFacade>(),
  ),
);
