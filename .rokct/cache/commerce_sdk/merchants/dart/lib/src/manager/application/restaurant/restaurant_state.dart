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

import 'package:base_sdk/src/models/data/shop_data.dart';

/// Plain immutable state rather than a `freezed` union — merchants_sdk
/// convention (see `application/main/main_state.dart`).
///
/// [shop] is base_sdk's [ShopData]; the legacy manager twin is not carried
/// over. `orderPayment` mirrors the legacy field that base's model lacks.
class RestaurantState {
  const RestaurantState({
    this.isLoading = false,
    this.backgroundImageFile,
    this.logoImageFile,
    this.orderPayment,
    this.shop,
    this.pendingSync = false,
  });

  final bool isLoading;
  final String? backgroundImageFile;
  final String? logoImageFile;
  final String? orderPayment;
  final ShopData? shop;

  /// True while [shop] is a local-first record not yet accepted by the
  /// backend (offline create awaiting sync) — widgets read this for the
  /// "pending sync" badge.
  final bool pendingSync;

  RestaurantState copyWith({
    bool? isLoading,
    String? backgroundImageFile,
    String? logoImageFile,
    String? orderPayment,
    ShopData? shop,
    bool? pendingSync,
    bool clearBackgroundImageFile = false,
    bool clearLogoImageFile = false,
  }) =>
      RestaurantState(
        isLoading: isLoading ?? this.isLoading,
        backgroundImageFile: clearBackgroundImageFile
            ? null
            : (backgroundImageFile ?? this.backgroundImageFile),
        logoImageFile:
            clearLogoImageFile ? null : (logoImageFile ?? this.logoImageFile),
        orderPayment: orderPayment ?? this.orderPayment,
        shop: shop ?? this.shop,
        pendingSync: pendingSync ?? this.pendingSync,
      );
}
