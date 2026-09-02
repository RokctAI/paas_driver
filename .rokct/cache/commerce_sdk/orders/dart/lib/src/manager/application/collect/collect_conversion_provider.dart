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

import 'package:orders_sdk/src/manager/domain/interface/seller_orders.dart';

import 'collect_conversion_notifier.dart';
import 'collect_conversion_state.dart';

/// Family-keyed on the Order docname: the board keeps several detail
/// panes alive as the seller moves between cards, and one order's
/// hand-over must never spend another's action lane.
final collectConversionProvider = StateNotifierProvider.family<
    CollectConversionNotifier, CollectConversionState, String>(
  (ref, orderId) => CollectConversionNotifier(
    GetIt.instance<SellerOrdersRepositoryFacade>(),
  ),
);
