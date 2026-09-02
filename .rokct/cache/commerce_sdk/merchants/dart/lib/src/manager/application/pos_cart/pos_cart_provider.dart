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

import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_notifier.dart';
import 'package:merchants_sdk/src/manager/application/pos_cart/pos_cart_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_catalog.dart';

/// One cart per till session — the BillingPage tab and the pushed
/// CheckoutPage watch the same instance. The catalog facade comes from
/// get_it (`ManagerMerchantsDependencies.register`: demo-gated to
/// `MockProductsRepository` under `--dart-define=IS_DEMO=true`).
final posCartProvider = StateNotifierProvider<PosCartNotifier, PosCartState>(
  (ref) => PosCartNotifier(GetIt.instance<PosCatalogRepositoryFacade>()),
);
