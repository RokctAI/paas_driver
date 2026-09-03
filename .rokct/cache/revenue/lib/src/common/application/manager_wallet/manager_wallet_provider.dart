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

import 'package:revenue_sdk/src/common/application/manager_wallet/manager_wallet_notifier.dart';
import 'package:revenue_sdk/src/common/application/manager_wallet/manager_wallet_scope.dart';
import 'package:revenue_sdk/src/common/application/manager_wallet/manager_wallet_state.dart';
import 'package:revenue_sdk/src/common/domain/interface/driver_payout.dart';

/// The manager wallet slice, one per shop (design strip frame 49l).
///
/// Resolution path: [DriverPayoutRepositoryFacade] is registered against
/// `GetIt.instance` by `ManagerRevenueDependencies.register(getIt)` — the
/// `revenue-manager-role-di` hook in this SDK's manifest — exactly as the
/// driver's slices resolve it through `DriverRevenueDependencies`. A host
/// that composes revenue_sdk in the manager flavour has it before the hub
/// first builds.
///
/// Deliberately NOT auto-disposed: the withdraw path pre-reads the accounts
/// before it opens anything (frame 49n), then the sheet, the form and the
/// sent sheet all read the same list, and the post-hold balance must
/// outlive the sheet that produced it so the card can draw it.
///
/// Tests override it whole:
/// `managerWalletProvider.overrideWith((ref, scope) =>
/// ManagerWalletNotifier(fakeRepository, scope: scope, isOnline: ...))`.
final managerWalletProvider = StateNotifierProvider.family<
    ManagerWalletNotifier, ManagerWalletState, ManagerWalletScope>(
  (ref, scope) => ManagerWalletNotifier(
    GetIt.instance<DriverPayoutRepositoryFacade>(),
    scope: scope,
  ),
);
