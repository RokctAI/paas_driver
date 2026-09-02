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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:merchants_sdk/src/manager/domain/interface/pos_orders.dart';

/// Demo (`--dart-define=IS_DEMO=true`) implementation of
/// [PosOrdersFacade]: the strip's render fixtures with zero backend
/// contact, so headless tours and the standalone POS test harness
/// exercise the full checkout — customer attach, credit split,
/// send-for-delivery — end to end. Mirrors `MockProductsRepository`'s
/// role for the catalog seam.
class MockPosOrdersRepository implements PosOrdersFacade {
  /// The design strip's demo customer (frames 11g–11i).
  static const PosCustomer demoCustomer = PosCustomer(
    id: 'demo-customer',
    firstname: 'Thabo',
    lastname: 'Mokoena',
    phone: '072 114 8890',
  );

  /// The strip's "owes R89.50" outstanding chip.
  static const double demoOutstanding = 89.50;

  /// Sales submitted this session; demo never syncs, so each stays
  /// pending — which is exactly what the pending-sync indicator renders.
  final List<PosSaleDraft> submitted = [];

  @override
  Future<ApiResult<List<PosCustomer>>> searchCustomers({
    String? query,
    int page = 1,
  }) async {
    final q = (query ?? '').trim().toLowerCase();
    final match = q.isEmpty ||
        demoCustomer.fullName.toLowerCase().contains(q) ||
        (demoCustomer.phone ?? '').replaceAll(' ', '').contains(q);
    return ApiResult.success(data: match ? const [demoCustomer] : const []);
  }

  @override
  Future<double?> customerCreditOutstanding(String customerId) async =>
      customerId == demoCustomer.id ? demoOutstanding : 0;

  @override
  Future<ApiResult<String>> submitSale(PosSaleDraft draft) async {
    submitted.add(draft);
    return ApiResult.success(data: 'offline:demo-${submitted.length}');
  }

  @override
  Future<int> pendingSaleCount() async => submitted.length;
}
