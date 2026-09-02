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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class ExtrasGroupDetailsState {
  const ExtrasGroupDetailsState({
    this.isLoading = false,
    this.extras = const [],
  });

  final bool isLoading;
  final List<SellerExtras> extras;

  ExtrasGroupDetailsState copyWith({
    bool? isLoading,
    List<SellerExtras>? extras,
  }) =>
      ExtrasGroupDetailsState(
        isLoading: isLoading ?? this.isLoading,
        extras: extras ?? this.extras,
      );
}
