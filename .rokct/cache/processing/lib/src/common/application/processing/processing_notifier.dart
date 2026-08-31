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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

import '../../domain/interface/processing_contract.dart';
import '../../domain/interface/processing_repository_facade.dart';
import 'processing_state.dart';

class ProcessingNotifier extends StateNotifier<ProcessingSdkState> {
  final ProcessingRepositoryFacade _repository;

  ProcessingNotifier(this._repository) : super(const ProcessingSdkState());

  Future<void> fetchContracts({String? type}) async {
    state = state.copyWith(isLoading: true, error: null);
    final res = await _repository.getContracts(type: type);
    res.when(
      success: (data) =>
          state = state.copyWith(isLoading: false, contracts: data),
      failure: (error, statusCode) =>
          state = state.copyWith(isLoading: false, error: error),
    );
  }

  /// Attempts a state transition, enforcing [ProcessingStateMachine] rules.
  /// Returns false (and sets the state error) when the transition is not
  /// allowed or persistence fails.
  Future<bool> transition(
    ProcessingContract contract,
    ProcessingState to,
  ) async {
    if (!ProcessingStateMachine.canTransition(contract.currentState, to)) {
      state = state.copyWith(
        error:
            'Illegal transition: cannot move a ${contract.contractType} from '
            '${contract.currentState.name} to ${to.name}',
      );
      return false;
    }
    final updated = GenericContract(
      contractId: contract.contractId,
      contractType: contract.contractType,
      currentState: to,
      metadata: contract.metadata,
      updatedAt: DateTime.now(),
      isPaid: contract.isPaid,
    );
    final res = await _repository.saveContract(updated);
    return res.when(
      success: (saved) {
        state = state.copyWith(
          contracts: [
            for (final c in state.contracts)
              if (c.contractId == saved.contractId) saved else c,
          ],
        );
        return true;
      },
      failure: (error, statusCode) {
        state = state.copyWith(error: error);
        return false;
      },
    );
  }
}
