import 'package:drift/drift.dart';

/// Record of a temp id minted offline resolving to its backend id.
///
/// Temp ids follow the `offline:<uuid>` convention (extending auth's
/// existing `offline:` token prefix). Rows are kept after the owning outbox
/// op syncs so late consumers of a temp id can still resolve it.
@DataClassName('IdMapping')
class IdMappingsTable extends Table {
  /// The locally minted id, e.g. `offline:5f0c...`.
  TextColumn get tempId => text()();

  /// The authoritative id assigned by the backend.
  TextColumn get backendId => text()();

  /// Entity kind, e.g. `user` / `shop` / `product` / `order`.
  TextColumn get entityType => text()();

  DateTimeColumn get mappedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tempId};
}
