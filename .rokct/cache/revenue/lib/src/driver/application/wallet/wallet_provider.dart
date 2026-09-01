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

import 'package:revenue_sdk/src/common/domain/interface/courier_statistics.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_wallet.dart';
import 'package:revenue_sdk/src/driver/application/wallet/wallet_notifier.dart';
import 'package:revenue_sdk/src/driver/application/wallet/wallet_state.dart';

/// Same resolution path as the statistics and withdraw slices: both seams
/// are registered against `GetIt.instance` by
/// `DriverRevenueDependencies.register(getIt)`.
final driverWalletProvider =
    StateNotifierProvider<DriverWalletNotifier, DriverWalletState>(
  (ref) => DriverWalletNotifier(
    GetIt.instance<DriverWalletRepositoryFacade>(),
    GetIt.instance<CourierStatisticsRepositoryFacade>(),
  ),
);
