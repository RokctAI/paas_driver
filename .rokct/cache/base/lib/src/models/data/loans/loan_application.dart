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


// Copyright (c) 2024 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

class LoanApplicationModel {
  final String idNumber;
  final double amount;
  final Map<String, dynamic>? financialDetails; // Added
  final double income;
  final double totalExpenses;
  final bool skipDocuments;
  final String? savedApplicationId;
  final Map<String, dynamic>
      documents; // Changed from List<File> to Map<String, dynamic>

  LoanApplicationModel({
    required this.idNumber,
    required this.amount,
    required this.documents,
    this.savedApplicationId,
    this.financialDetails,
    this.income = 0,
    this.totalExpenses = 0,
    this.skipDocuments = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_number': idNumber,
      'amount': amount,
      'saved_application_id': savedApplicationId,
      'documents': documents,
      'income': income,
      'total_expenses': totalExpenses,
      'skip_documents': skipDocuments,
      'financial_details': financialDetails,
    };
  }
}
