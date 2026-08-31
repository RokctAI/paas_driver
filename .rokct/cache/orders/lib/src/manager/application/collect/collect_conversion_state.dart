// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

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
