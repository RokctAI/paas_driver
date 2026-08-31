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


import 'package:flutter/foundation.dart';

/// Model class representing a saved payment card.
///
/// Deliberately carries no gateway reuse credential. That credential is
/// what a saved card *is* -- presenting it to the gateway charges the card
/// again -- so it is a Password field server-side and is never listed,
/// exported or returned over the wire. [id] is the Saved Card docname, and
/// the docname is the handle every charge takes: it is what
/// `process_token_payment` and `process_wallet_top_up` are given, and what
/// `deleteCard` has always used.
class SavedCardModel {
  /// The Saved Card docname. The handle a charge is keyed on.
  final String id;
  final String lastFour;
  final String cardType;
  final String expiryDate;
  final String cardHolderName;
  final bool isDefault;

  SavedCardModel({
    required this.id,
    required this.lastFour,
    required this.cardType,
    required this.expiryDate,
    required this.cardHolderName,
    this.isDefault = false,
  });

  /// Create a SavedCardModel from JSON
  factory SavedCardModel.fromJson(Map<String, dynamic> json) {
    // Print the JSON for debugging
    debugPrint('Parsing card JSON: $json');

    return SavedCardModel(
      // `get_saved_cards` and `tokenize_card` name the docname `name`;
      // `id` is accepted first so callers that already normalise it keep
      // working. Any `token` in the payload is ignored -- the credential
      // does not travel any more.
      id: (json['id'] ?? json['name'])?.toString() ?? '',
      lastFour: json['last_four']?.toString() ?? '',
      cardType: json['card_type']?.toString() ?? 'Card',
      expiryDate: json['expiry_date']?.toString() ?? '',
      cardHolderName: json['card_holder_name']?.toString() ?? '',
      isDefault: json['is_default'] == true || json['is_default'] == 1,
    );
  }

  /// Convert the SavedCardModel to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_four': lastFour,
      'card_type': cardType,
      'expiry_date': expiryDate,
      'card_holder_name': cardHolderName,
      'is_default': isDefault,
    };
  }

  /// Create a copy of this SavedCardModel with some fields replaced
  SavedCardModel copyWith({
    String? id,
    String? lastFour,
    String? cardType,
    String? expiryDate,
    String? cardHolderName,
    bool? isDefault,
  }) {
    return SavedCardModel(
      id: id ?? this.id,
      lastFour: lastFour ?? this.lastFour,
      cardType: cardType ?? this.cardType,
      expiryDate: expiryDate ?? this.expiryDate,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'SavedCardModel(id: $id, lastFour: $lastFour, '
        'cardType: $cardType, expiryDate: $expiryDate, isDefault: $isDefault)';
  }
}
