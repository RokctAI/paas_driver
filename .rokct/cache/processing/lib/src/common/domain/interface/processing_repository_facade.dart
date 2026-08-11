import 'package:base_sdk/base_sdk.dart';

/// Consumer-owned persistence/transport boundary for the engine.
///
/// The host app decides where contract state lives (backend endpoint, local
/// database, or both) and registers an implementation via
/// ProcessingSdkDependencies.register. A local offline implementation
/// backed by base_sdk's shared database ships with this SDK.
abstract class ProcessingRepositoryFacade {
  Future<ApiResult<List<ProcessingContract>>> getContracts({String? type});

  Future<ApiResult<ProcessingContract?>> getContract(String contractId);

  Future<ApiResult<ProcessingContract>> saveContract(
    ProcessingContract contract,
  );

  Future<ApiResult<void>> deleteContract(String contractId);
}
