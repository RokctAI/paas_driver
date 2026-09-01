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
import 'package:products_sdk/src/common/domain/interface/seller_products.dart';
import 'package:products_sdk/src/manager/application/extras/delete/delete_extras_group_notifier.dart';
import 'package:products_sdk/src/manager/application/extras/delete/delete_extras_group_state.dart';

final deleteExtrasGroupProvider =
    StateNotifierProvider<DeleteExtrasGroupNotifier, DeleteExtrasGroupState>(
  (ref) =>
      DeleteExtrasGroupNotifier(GetIt.instance<SellerProductsRepositoryFacade>()),
);
