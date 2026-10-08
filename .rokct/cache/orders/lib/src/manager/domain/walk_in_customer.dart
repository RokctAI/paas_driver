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

/// WHO THE CUSTOMER IS ON A WALK-IN SALE (Ray 2026-09-18: "in paas_pos i
/// think if seller was making order for walkin customer and not input
/// details it then used seller account as customer").
///
/// The manager POS's create-order flow lets the seller pick a customer,
/// type a new one, or walk straight past the step. `Order.user` is a
/// REQUIRED link on the backend, so "walked straight past it" needs an
/// answer, and the pre-fork POS's answer was the seller's own account.
/// That is what this resolves, as a pure function so the rule is testable
/// without a till, a session or a socket: the repository hands it the
/// picked customer and the cached seller profile and puts the result on
/// the wire.
///
/// It never invents an identity: with no pick AND no cached seller profile
/// the customer keys stay ABSENT from the payload, exactly as before, and
/// the backend's own required-field error is what the seller sees.
library;

/// The customer keys a create-order payload carries, and which of the two
/// rules put them there.
class WalkInOrderCustomer {
  /// The `user_id` the order is placed for, or null when neither a picked
  /// customer nor a cached seller profile could supply one.
  final String? userId;

  /// The `phone` that travels with it — the picked customer's, or the
  /// seller's own on the fallback (an in-person sale's contact number is
  /// the till's, and `require_phone_for_order` shops still get a value).
  final String? phone;

  /// True when this is the seller's own account standing in as the
  /// walk-in customer.
  final bool isSellerAccount;

  const WalkInOrderCustomer({
    this.userId,
    this.phone,
    required this.isSellerAccount,
  });
}

String? _clean(String? value) {
  final String trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Resolves the customer a manager-placed order is for.
///
/// A picked (or just-created) customer always wins. With no pick — the
/// seller entered no details at all — the seller's own account stands in
/// as the walk-in customer.
WalkInOrderCustomer resolveWalkInOrderCustomer({
  String? selectedUserId,
  String? selectedPhone,
  String? sellerUserId,
  String? sellerPhone,
}) {
  final String? selected = _clean(selectedUserId);
  if (selected != null) {
    return WalkInOrderCustomer(
      userId: selected,
      phone: _clean(selectedPhone),
      isSellerAccount: false,
    );
  }
  final String? seller = _clean(sellerUserId);
  return WalkInOrderCustomer(
    userId: seller,
    phone: seller == null ? null : _clean(sellerPhone),
    isSellerAccount: seller != null,
  );
}
