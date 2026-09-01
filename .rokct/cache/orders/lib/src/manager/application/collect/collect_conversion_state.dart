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

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:orders_sdk/src/manager/infrastructure/models/models.dart';

part 'collect_conversion_state.freezed.dart';

/// The seller-side state of "the customer is here" (design strip section
/// 43). [result] is set once the conversion has run — or been queued,
/// when the till was offline; [error] carries a backend refusal.
@freezed
abstract class CollectConversionState with _$CollectConversionState {
  const factory CollectConversionState({
    @Default(false) bool isConverting,
    CollectConversion? result,
    String? error,
  }) = _CollectConversionState;

  const CollectConversionState._();

  /// The action lane is spent once the order has been handed over — the
  /// goods left the counter and there is nothing left to convert.
  bool get isDone => result != null;
}
