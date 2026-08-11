import '../../domain/interface/processing_contract.dart';

class ProcessingSdkState {
  final bool isLoading;
  final List<ProcessingContract> contracts;
  final String? error;

  const ProcessingSdkState({
    this.isLoading = false,
    this.contracts = const [],
    this.error,
  });

  ProcessingSdkState copyWith({
    bool? isLoading,
    List<ProcessingContract>? contracts,
    String? error,
  }) {
    return ProcessingSdkState(
      isLoading: isLoading ?? this.isLoading,
      contracts: contracts ?? this.contracts,
      error: error,
    );
  }
}
