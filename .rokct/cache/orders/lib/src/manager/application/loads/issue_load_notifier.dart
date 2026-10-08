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
import 'package:base_sdk/src/handlers/api_result.dart';

import 'package:orders_sdk/src/manager/domain/interface/shop_loads.dart';
import 'package:orders_sdk/src/manager/domain/load_draft.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/load_data.dart';
import 'package:orders_sdk/src/manager/infrastructure/models/data/product_data.dart';
import 'issue_load_state.dart';

/// Drives /load/issue: the driver list, the draft's quantities and the one
/// `create_load` call that takes the goods off the shelf.
class IssueLoadNotifier extends StateNotifier<IssueLoadState> {
  final ShopLoadsRepositoryFacade _repository;

  IssueLoadNotifier(this._repository) : super(const IssueLoadState());

  Future<void> fetchDrivers() async {
    state = state.copyWith(isLoadingDrivers: true);
    final response = await _repository.listShopDeliverymen();
    if (!mounted) return;
    response.when(
      success: (drivers) => state = state.copyWith(
        isLoadingDrivers: false,
        drivers: drivers,
        // One driver on file is the pick; nothing is chosen for the shop
        // when there is a choice to make.
        deliverymanId: state.deliverymanId ??
            (drivers.length == 1 ? drivers.first.id : null),
      ),
      failure: (error, statusCode) =>
          state = state.copyWith(isLoadingDrivers: false),
    );
  }

  void selectDeliveryman(String? id) =>
      state = state.copyWith(deliverymanId: id);

  /// A product tapped in the picker: one step up on its shelf row.
  void addProduct(ProductData product) {
    final LoadDraftLine? line = loadDraftLineFromProduct(product);
    if (line == null) return;
    setQuantity(line, draftQuantityOf(state.lines, line.stockId) + 1);
  }

  void setQuantity(LoadDraftLine line, num quantity) =>
      state = state.copyWith(
        lines: setDraftQuantity(state.lines, line, quantity),
      );

  void removeLine(LoadDraftLine line) => setQuantity(line, 0);

  /// Issues the load. Answers it on success so the caller can go straight
  /// to its detail; null when the backend refused and nothing left the
  /// shelf.
  Future<LoadData?> issue() async {
    if (!state.canIssue) return null;
    state = state.copyWith(isSubmitting: true);
    final response = await _repository.createLoad(
      deliveryman: state.deliverymanId ?? '',
      items: draftIssueLines(state.lines),
    );
    LoadData? issued;
    response.when(
      success: (load) => issued = load,
      failure: (error, statusCode) {},
    );
    if (mounted) state = state.copyWith(isSubmitting: false);
    return issued;
  }
}
