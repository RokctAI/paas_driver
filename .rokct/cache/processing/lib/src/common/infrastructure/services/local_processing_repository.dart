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
