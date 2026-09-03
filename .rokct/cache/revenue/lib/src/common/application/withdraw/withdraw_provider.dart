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
import 'package:revenue_sdk/src/common/application/withdraw/withdraw_notifier.dart';
import 'package:revenue_sdk/src/common/application/withdraw/withdraw_state.dart';

/// Same resolution path as the statistics slice's provider:
/// [DriverPayoutRepositoryFacade] is registered against `GetIt.instance` by
/// `DriverRevenueDependencies.register(getIt)`.
final withdrawProvider =
    StateNotifierProvider<WithdrawNotifier, WithdrawState>(
  (ref) => WithdrawNotifier(
    GetIt.instance<DriverPayoutRepositoryFacade>(),
  ),
);
