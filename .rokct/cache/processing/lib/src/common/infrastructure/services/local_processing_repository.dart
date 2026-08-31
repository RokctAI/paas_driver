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

import 'package:base_sdk/base_sdk.dart';

import '../../domain/interface/processing_repository_facade.dart';

/// Offline-capable default implementation over base_sdk's shared database
/// (generic JSON document store). Suitable for on-device workflows and as a
/// fallback until a host registers a backend-backed implementation.
class LocalProcessingRepository implements ProcessingRepositoryFacade {
  static const String _box = 'processing_contracts';

  @override
  Future<ApiResult<List<ProcessingContract>>> getContracts({
    String? type,
  }) async {
    try {
      final rows = await AppDatabase().getAll(_box);
      final list = rows
          .map(_fromJson)
          .where((c) => type == null || c.contractType == type)
          .toList();
      return ApiResult.success(data: list);
    } catch (e) {
      return ApiResult.failure(error: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ApiResult<ProcessingContract?>> getContract(String contractId) async {
    try {
      final row = await AppDatabase().getItem(_box, contractId);
      return ApiResult.success(data: row == null ? null : _fromJson(row));
    } catch (e) {
      return ApiResult.failure(error: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ApiResult<ProcessingContract>> saveContract(
    ProcessingContract contract,
  ) async {
    try {
      await AppDatabase().putItem(_box, contract.contractId, _toJson(contract));
      return ApiResult.success(data: contract);
    } catch (e) {
      return ApiResult.failure(error: e.toString(), statusCode: 500);
    }
  }

  @override
  Future<ApiResult<void>> deleteContract(String contractId) async {
    try {
      await AppDatabase().deleteItem(_box, contractId);
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(error: e.toString(), statusCode: 500);
    }
  }

  Map<String, dynamic> _toJson(ProcessingContract c) => {
        'contractId': c.contractId,
        'contractType': c.contractType,
        'currentState': c.currentState.name,
        'metadata': c.metadata,
        'updatedAt': c.updatedAt.toIso8601String(),
        'isPaid': c.isPaid,
      };

  GenericContract _fromJson(Map<String, dynamic> json) => GenericContract(
        contractId: json['contractId'] as String? ?? json['id'] as String,
        contractType: json['contractType'] as String? ?? 'generic',
        currentState: ProcessingState.values.firstWhere(
          (s) => s.name == json['currentState'],
          orElse: () => ProcessingState.draft,
        ),
        metadata:
            (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        isPaid: json['isPaid'] as bool? ?? false,
      );
}
