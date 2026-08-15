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
