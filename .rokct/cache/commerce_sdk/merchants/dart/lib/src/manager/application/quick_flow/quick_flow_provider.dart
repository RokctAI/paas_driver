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

import 'package:merchants_sdk/src/manager/application/quick_flow/quick_flow_notifier.dart';
import 'package:merchants_sdk/src/manager/application/quick_flow/quick_flow_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/quick_flow.dart';
import 'package:merchants_sdk/src/manager/infrastructure/repositories/quick_flow_repository.dart';

/// [QuickFlowRepositoryFacade] is registered by
/// `ManagerMerchantsDependencies.register` (demo-gated to the mock); the
/// direct construction fallback keeps hand-wired hosts working.
///
/// Deliberately a plain (non-auto-dispose) provider: the till reads the
/// same instance the settings page writes, so moving a switch on the Quick
/// flow surface arms or disarms the pad on the till with no refetch.
final quickFlowProvider =
    StateNotifierProvider<QuickFlowNotifier, QuickFlowState>(
  (ref) => QuickFlowNotifier(
    GetIt.instance.isRegistered<QuickFlowRepositoryFacade>()
        ? GetIt.instance<QuickFlowRepositoryFacade>()
        : QuickFlowRepository(),
  ),
);
