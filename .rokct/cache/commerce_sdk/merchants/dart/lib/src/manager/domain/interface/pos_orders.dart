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

/// The POS checkout's order seam (approved strip 11g–11i): customer
/// attach + credit outstanding, and the cart→create-order handoff into
/// the EXISTING seller pipeline (Ray's ruling — "you just need to add
/// scanned ones to that pipeline").
///
/// Declared in merchants_sdk's own terms because the owners of the data
/// live in sibling SDKs this one must not import (orders_sdk owns the
/// pipeline and the customer picker seam; the ADR-005
/// `SellerSectionsTablesRepositoryFacade` precedent). The manager host
/// registers the installed `ManagerPosOrdersAdapter`
/// (templates/adapters/manager/pos_orders_adapter.dart) — host-composition
/// code that may reference any composed SDK. Demo builds register this
/// SDK's `MockPosOrdersRepository` instead (zero backend contact). When
/// NOTHING is registered the checkout degrades honestly: no customer /
/// credit surface, and a finished sale completes locally only.
abstract class PosOrdersFacade {
  /// Customer search for the "Billing to" attach (chip 305) — the same
  /// shop-scoped user search the manager create-order flow uses.
  Future<ApiResult<List<PosCustomer>>> searchCustomers({
    String? query,
    int page = 1,
  });

  /// The attached customer's open credit — the sum of their
  /// `payment_status == "Credit"` orders' outstanding balances (chip 306,
  /// the "owes" chip). Null when the surface cannot answer (endpoint
  /// unreachable / site not migrated); the chip simply doesn't render.
  Future<double?> customerCreditOutstanding(String customerId);

  /// Feeds the finished sale into the seller create-order pipeline,
  /// OFFLINE-FIRST: local store first, sync queue second, never a
  /// blocking network call. Returns the local record id.
  Future<ApiResult<String>> submitSale(PosSaleDraft draft);

  /// Sales recorded on this till not yet reconciled with the backend —
  /// the billing page's pending-sync indicator.
  Future<int> pendingSaleCount();
}

/// One line of a finished sale, in ids the pipeline understands.
class PosDraftLine {
  const PosDraftLine({required this.productId, required this.quantity});

  final String productId;
  final double quantity;
}

/// A finished till sale, ready for the pipeline.
class PosSaleDraft {
  const PosSaleDraft({
    required this.orderId,
    required this.lines,
    required this.total,
    required this.deliveryType,
    required this.status,
    this.customerId,
    this.phone,
    this.address,
    this.paidNow,
    this.onCredit = false,
  });

  /// The till's stable POS order id — the backend `offline_uuid`
  /// idempotency key, so a retried push can never double-create.
  final String orderId;

  final List<PosDraftLine> lines;

  /// The till total (cents-rounded) — the backend's `quoted_total`.
  final double total;

  /// 'pickup' (in-store) or 'delivery' (send-for-delivery).
  final String deliveryType;

  /// The sale's REAL wire status at completion: 'delivered' for an
  /// in-store sale, 'ready' for a packed send-for-delivery sale (an
  /// offline one HOLDS there locally until the sync drains it).
  final String status;

  final String? customerId;
  final String? phone;

  /// Delivery address (send-for-delivery only).
  final String? address;

  /// Amount collected at the till right now. Null/total = fully paid.
  final double? paidNow;

  /// True when a remainder completes as a Credit order on the attached
  /// customer's account.
  final bool onCredit;
}

/// A shop customer, as the POS surfaces need one (mirrors the
/// `get_shop_users` row shape the manager create-order picker renders).
class PosCustomer {
  const PosCustomer({
    required this.id,
    this.firstname,
    this.lastname,
    this.phone,
    this.img,
  });

  /// User docname (Frappe hash string / email).
  final String id;
  final String? firstname;
  final String? lastname;
  final String? phone;
  final String? img;

  String get fullName =>
      [firstname, lastname].whereType<String>().join(' ').trim();

  /// "TM" for Thabo Mokoena — the attach card's avatar initials.
  String get initials {
    final parts = [firstname, lastname]
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
