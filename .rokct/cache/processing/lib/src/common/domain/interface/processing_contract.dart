// Moved to base_sdk (2026-07-24) so feature SDKs enforce identical
// state-transition rules without importing processing_sdk directly
// (ADR-005: only base_sdk is imported cross-SDK). Re-exported here so
// processing_sdk's own existing consumers are unaffected.
export 'package:base_sdk/src/domain/interface/processing_contract.dart';
