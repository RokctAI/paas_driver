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

library kitchen_sdk;

// Role folders are siblings of `common/`, per decision_log.md.
//
// `common/` holds what is common *by design*, not by usage count: the
// `KitchensRepositoryFacade` seam a host implements against, the DI entry point
// every generated `main.dart` calls, and the DTOs that seam's signature
// references — a facade in `common/` cannot return a type that lives in a role
// folder without inverting the dependency.
//
// `manager/` holds the concrete implementation and the picker's UI state.
// manager is the only fork landed here so far, and pos may well want the same
// picker verbatim — but "nobody else uses this SDK yet" is not evidence code is
// shared, and no fork session promotes to `common/` from inside its own run.
export 'src/manager/application/kitchens/kitchen_picker_notifier.dart';
export 'src/manager/application/kitchens/kitchen_picker_provider.dart';
export 'src/manager/application/kitchens/kitchen_picker_state.dart';
export 'src/common/di/kitchen_di.dart';
export 'src/common/domain/interface/kitchens.dart';
export 'src/common/infrastructure/models/data/kitchen_data.dart';
export 'src/common/infrastructure/models/response/kitchens_paginate_response.dart';

// The manager KITCHEN screen (1.3.0): the paas_pos KitchenPage behaviour
// as a manager destination in the approved design (frames 34a-34d).
// Deliberately NOT exported here: a customer compose strips
// lib/src/manager/, so the barrel cannot reference the slice (orders_sdk
// precedent). The installed page template, the shell, and the manifest
// di_hooks import these files by their direct src/ paths:
//   src/manager/presentation/kitchen/kitchen_workspace.dart
//   src/manager/application/kitchen/kitchen_provider.dart
//   src/manager/di/manager_kitchen_di.dart
