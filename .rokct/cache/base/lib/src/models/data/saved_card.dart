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
