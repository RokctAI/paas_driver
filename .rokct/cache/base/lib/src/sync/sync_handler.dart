import 'package:base_sdk/src/database/app_database.dart';

/// Outcome of pushing one outbox op to the backend.
sealed class SyncResult {
  const SyncResult();

  /// The backend accepted the op. [idMappings] resolves each temp id the op
  /// created (`offline:<uuid>`) to its backend id; [entityType] labels those
  /// mappings in the id_mappings table (falls back to the op-type prefix,
  /// e.g. `order.create` -> `order`, when omitted).
  const factory SyncResult.synced({
    Map<String, String> idMappings,
    String? entityType,
  }) = SyncSynced;

  /// Transient failure (5xx, timeout, connection drop). The engine retries
  /// with attempt-based backoff.
  const factory SyncResult.retryable(String error) = SyncRetryable;

  /// Terminal rejection (validation error, conflict — 4xx-style). The op is
  /// parked as `failed` for user resolution and never retried automatically.
  const factory SyncResult.rejected(String error) = SyncRejected;
}

class SyncSynced extends SyncResult {
  const SyncSynced({this.idMappings = const {}, this.entityType});

  /// Temp id (`offline:<uuid>`) -> backend id.
  final Map<String, String> idMappings;

  final String? entityType;
}

class SyncRetryable extends SyncResult {
  const SyncRetryable(this.error);

  final String error;
}

class SyncRejected extends SyncResult {
  const SyncRejected(this.error);

  final String error;
}

/// Per-op-type push logic, implemented by feature SDKs and registered with
/// the engine via `SyncEngine.registerHandler` (usually from the SDK's
/// `*SdkDependencies.register`). base_sdk cannot depend on feature SDKs, so
/// this registration is the only legal direction for the engine to reach
/// SDK-owned repositories.
abstract class SyncHandler {
  /// Push [op] to the backend and classify the outcome. Send `op.id` as the
  /// idempotency key so ambiguous-failure retries do not double-create.
  ///
  /// Throwing is treated as [SyncResult.retryable].
  Future<SyncResult> push(OutboxEntry op);

  /// Called after [push] returned synced and the engine has stored
  /// [idMappings] and rewritten still-pending payloads. Override to update
  /// the SDK's own local record with its backend id (e.g. swap
  /// `offline:<uuid>` for the real id and clear a pending badge).
  Future<void> onSynced(OutboxEntry op, Map<String, String> idMappings) async {}
}
