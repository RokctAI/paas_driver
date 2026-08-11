import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'section_state.freezed.dart';

@freezed
class SectionState with _$SectionState {
  const factory SectionState({
    @Default([]) List<ShopSection> sections,
    @Default(0) int selectedIndex,
    @Default(false) bool isLoading,
    ShopSection? selectSection,
    TextEditingController? textController,
  }) = _SectionState;

  const SectionState._();
}
