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

import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/restaurant_notifier.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/restaurant_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';

/// [SellerShopRepositoryFacade] is registered by
/// `ManagerMerchantsDependencies.register`; [GalleryRepositoryFacade] by
/// base_sdk's own DI.
final restaurantProvider =
    StateNotifierProvider<RestaurantNotifier, RestaurantState>(
  (ref) => RestaurantNotifier(
    GetIt.instance<SellerShopRepositoryFacade>(),
    GetIt.instance<GalleryRepositoryFacade>(),
  ),
);
