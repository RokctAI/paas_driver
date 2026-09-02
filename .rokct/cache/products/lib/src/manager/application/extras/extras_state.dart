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

import 'package:products_sdk/src/common/infrastructure/models/data/seller_extras_group.dart';

/// Plain immutable state (no freezed) — same reason as the stage 2 states.
class ExtrasState {
  const ExtrasState({
    this.isLoading = false,
    this.isSaving = false,
    this.groups = const [],
  });

  final bool isLoading;
  final bool isSaving;
  final List<SellerExtrasGroup> groups;

  ExtrasState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<SellerExtrasGroup>? groups,
  }) =>
      ExtrasState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        groups: groups ?? this.groups,
      );
}
