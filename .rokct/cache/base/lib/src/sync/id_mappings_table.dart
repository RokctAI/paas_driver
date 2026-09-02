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
