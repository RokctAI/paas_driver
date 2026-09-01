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


class LoanContractModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  LoanContractModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory LoanContractModel.fromJson(Map<String, dynamic> json) {
    return LoanContractModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Loan Contract',
      content: json['content'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
