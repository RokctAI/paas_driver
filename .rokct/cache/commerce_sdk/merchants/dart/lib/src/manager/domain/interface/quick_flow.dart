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
import 'package:base_sdk/src/models/data/product_data.dart';

/// QUICK FLOW (design strip section 42) — the three shop switches that let
/// the till run itself between customers, read and written as one surface.
///
/// The three are at very different depths and the surface says so on every
/// frame, so the contract keeps them apart rather than pretending they are
/// peers:
///
///   * [QuickFlowSettings.autoAcceptOrders] is `Shop.auto_approve_orders`,
///     a field that ALREADY EXISTS and is already honoured server-side
///     (`create_order` writes the initial status as `Accepted` when this
///     and the platform's own `Auto Approve All Orders` are both on). The
///     surface exposes that exact field and nothing more — no behaviour of
///     ours rides on it. [QuickFlowSettings.platformAutoApprove] is the
///     platform half, READ-ONLY, so the seller can see why their switch may
///     not be biting yet.
///   * [QuickFlowSettings.autoCompleteAtReady] is a new Shop field honoured
///     by a new Order-controller rule (pickup orders only — an order that
///     still has to travel is never completed by it).
///   * [QuickFlowSettings.keypadAutodial] plus [QuickFlowSettings.presets]
///     is the new per-shop digit→product map. The till interprets a digit
///     press against it while its ticket is empty; base_sdk's shared
///     `MoneyKeypad` (design chip 390) is NOT involved in the decision and
///     is not modified by any of this — it stays the pure input surface it
///     is fleet-wide.
///
/// Owned by merchants_sdk because the shop IS this SDK's manager vertical
/// (the `SellerShopRepositoryFacade` neighbourhood). Models are base_sdk's
/// ([ProductData]) — a preset carries its product already resolved, so a
/// digit press on the till never waits on the network.
abstract class QuickFlowRepositoryFacade {
  Future<ApiResult<QuickFlowSettings>> getQuickFlowSettings();

  /// Saves one switch or the whole preset map — every argument is optional
  /// and an omitted one is left exactly as it was. Supplying [presets]
  /// REPLACES the whole 1–9 map (the grid is owned as a unit, which is what
  /// keeps a digit from ever holding two products).
  Future<ApiResult<QuickFlowSettings>> updateQuickFlowSettings({
    bool? autoAcceptOrders,
    bool? autoCompleteAtReady,
    bool? keypadAutodial,
    List<QuickFlowPreset>? presets,
  });
}

/// One digit→product mapping (design chips 803/804: a filled slot of the
/// DIGIT PRESETS grid).
class QuickFlowPreset {
  const QuickFlowPreset({required this.digit, required this.product});

  /// 1–9. `0`, `00` and `⌫` are never presets: they are not item keys.
  final int digit;

  final ProductData product;

  String get title => product.translation?.title ?? '';

  /// The preset's unit price — the first stock row's, falling back to the
  /// product's single stock. Never null: an unpriced preset would put a
  /// free line on the ticket.
  num get price {
    final stocks = product.stocks;
    if (stocks != null && stocks.isNotEmpty) return stocks.first.price ?? 0;
    return product.stock?.price ?? 0;
  }

  Map<String, dynamic> toJson() => {
        'digit': digit.toString(),
        'product': product.id,
      };

  static QuickFlowPreset? fromJson(dynamic json) {
    if (json is! Map) return null;
    final digit = int.tryParse('${json['digit']}');
    if (digit == null || digit < 1 || digit > 9) return null;
    final product = json['product'];
    if (product == null) return null;
    return QuickFlowPreset(
      digit: digit,
      product: ProductData.fromJson(product),
    );
  }
}

/// The Quick flow surface's whole state, as one immutable value.
class QuickFlowSettings {
  const QuickFlowSettings({
    this.shopName = '',
    this.autoAcceptOrders = false,
    this.platformAutoApprove = false,
    this.autoCompleteAtReady = false,
    this.keypadAutodial = false,
    this.presets = const [],
  });

  final String shopName;

  /// `Shop.auto_approve_orders` — LIVE server-side today.
  final bool autoAcceptOrders;

  /// `Permission Settings.auto_approve_orders` — the platform half of the
  /// auto-accept gate. Read-only here: only the admin can move it.
  final bool platformAutoApprove;

  final bool autoCompleteAtReady;
  final bool keypadAutodial;

  /// At most nine, one per digit, ordered 1→9.
  final List<QuickFlowPreset> presets;

  /// The `5 of 9 set` counter (design chip 803).
  int get presetCount => presets.length;
  static const int presetSlots = 9;

  /// The preset on [digit], or null when that key is unset — an unset digit
  /// is INERT on the till, not an error (design chip 805).
  QuickFlowPreset? presetFor(int digit) {
    for (final preset in presets) {
      if (preset.digit == digit) return preset;
    }
    return null;
  }

  /// The till's arming condition, minus the empty-ticket half it cannot
  /// know about: the switch is on AND at least one digit is actually set.
  /// A shop that turned autodial on and mapped nothing gets the ordinary
  /// till, not a pad of dead keys.
  bool get autodialArmed => keypadAutodial && presets.isNotEmpty;

  static QuickFlowSettings fromJson(dynamic json) {
    if (json is! Map) return const QuickFlowSettings();
    final presets = <QuickFlowPreset>[];
    final rows = json['digit_presets'];
    if (rows is List) {
      for (final row in rows) {
        final preset = QuickFlowPreset.fromJson(row);
        if (preset != null) presets.add(preset);
      }
    }
    presets.sort((a, b) => a.digit.compareTo(b.digit));
    return QuickFlowSettings(
      shopName: '${json['shop_name'] ?? ''}',
      autoAcceptOrders: _flag(json['auto_accept_orders']),
      platformAutoApprove: _flag(json['platform_auto_approve']),
      autoCompleteAtReady: _flag(json['auto_complete_at_ready']),
      keypadAutodial: _flag(json['keypad_autodial']),
      presets: presets,
    );
  }

  static bool _flag(dynamic value) =>
      value == true || value == 1 || value == '1';

  QuickFlowSettings copyWith({
    String? shopName,
    bool? autoAcceptOrders,
    bool? platformAutoApprove,
    bool? autoCompleteAtReady,
    bool? keypadAutodial,
    List<QuickFlowPreset>? presets,
  }) =>
      QuickFlowSettings(
        shopName: shopName ?? this.shopName,
        autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
        platformAutoApprove: platformAutoApprove ?? this.platformAutoApprove,
        autoCompleteAtReady: autoCompleteAtReady ?? this.autoCompleteAtReady,
        keypadAutodial: keypadAutodial ?? this.keypadAutodial,
        presets: presets ?? this.presets,
      );
}
