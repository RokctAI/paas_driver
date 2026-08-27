// Copyright (c) 2026 RokctAI
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


import 'package:base_sdk/src/models/models.dart';

class WalletHistoryData {
  final int? id;
  final String? uuid;
  final String? walletUuid;
  final int? transactionId;
  final String? type;
  final double? price;
  final String? note;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final UserData? user;
  final UserData? author;
  final TransactionData? transaction;

  WalletHistoryData({
    this.id,
    this.uuid,
    this.walletUuid,
    this.transactionId,
    this.type,
    this.price,
    this.note,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.author,
    this.transaction,
  });

  factory WalletHistoryData.fromJson(Map<String, dynamic> json) {
    return WalletHistoryData(
      id: json['id'],
      uuid: json['uuid'],
      walletUuid: json['wallet_uuid'],
      transactionId: json['transaction_id'],
      type: json['type'],
      price: json['price']?.toDouble(),
      note: json['note'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      author: json['author'] != null ? UserData.fromJson(json['author']) : null,
      transaction: json['transaction'] != null
          ? TransactionData.fromJson(json['transaction'])
          : null,
    );
  }
}
