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

import 'package:orders_sdk/src/manager/domain/interface/shop_drivers.dart';
import 'package:orders_sdk/src/manager/domain/interface/shop_loads.dart';
import 'shop_drivers_notifier.dart';
import 'shop_drivers_state.dart';

/// Auto-disposed like the issue-load draft: the roster is small, always
/// worth re-reading on arrival, and a stale copy behind the load screen
/// would be the one thing worse than a second call.
final shopDriversProvider =
    StateNotifierProvider.autoDispose<ShopDriversNotifier, ShopDriversState>(
      (ref) => ShopDriversNotifier(
        GetIt.instance<ShopDriversRepositoryFacade>(),
        GetIt.instance<ShopLoadsRepositoryFacade>(),
      ),
    );
