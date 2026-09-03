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

import 'package:revenue_sdk/src/common/application/deposit_approvals/deposit_approvals_notifier.dart';
import 'package:revenue_sdk/src/common/application/deposit_approvals/deposit_approvals_state.dart';
import 'package:revenue_sdk/src/common/domain/interface/deposit_approval.dart';

/// The deposit approval queue (design strip frame 49i, manager side).
///
/// Resolution path: [DepositApprovalRepositoryFacade] is registered against
/// `GetIt.instance` by `ManagerRevenueDependencies.register(getIt)` — the
/// `revenue-manager-role-di` hook in this SDK's manifest — so a manager
/// host has it before the hub first builds.
///
/// Deliberately NOT auto-disposed: the hub's entry row and the page share
/// the queue, and a decision's result must outlive the sheet that made it.
///
/// Tests override it whole:
/// `depositApprovalsProvider.overrideWith((ref) =>
/// DepositApprovalsNotifier(fakeRepository, isOnline: ...))`.
final depositApprovalsProvider =
    StateNotifierProvider<DepositApprovalsNotifier, DepositApprovalsState>(
  (ref) => DepositApprovalsNotifier(
    GetIt.instance<DepositApprovalRepositoryFacade>(),
  ),
);
