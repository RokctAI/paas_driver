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

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'section_state.freezed.dart';

@freezed
abstract class SectionState with _$SectionState {
  const factory SectionState({
    @Default([]) List<ShopSection> sections,
    @Default(0) int selectedIndex,
    @Default(false) bool isLoading,
    ShopSection? selectSection,
    TextEditingController? textController,
  }) = _SectionState;

  const SectionState._();
}
