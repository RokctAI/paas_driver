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

/// Lifecycle of a queued offline operation.
///
/// Stored as the enum name in [OutboxTable.status] (plain text column so the
/// row stays readable in raw SQL and tolerant of future additions). There is
/// no `synced` state: a successfully pushed op is deleted from the outbox,
/// which is also how `dependsOn` resolution detects that a parent has synced.
enum OutboxStatus {
  /// Waiting to be pushed (possibly not before [OutboxTable.nextAttemptAt]).
  pending,

  /// Currently being pushed by a handler.
  inFlight,

  /// Terminally rejected by the backend (4xx-style). Parked for user
  /// resolution; never retried automatically.
  failed,

  /// Retried up to the attempt cap without success. Never retried.
  dead,
}

/// Queue of local-first mutations awaiting push to the backend.
///
/// One row per operation. [id] is a client-generated UUID v4 that doubles as
/// the idempotency key sent to the backend, so an op retried after an
/// ambiguous network failure can be deduplicated server-side.
@DataClassName('OutboxEntry')
class OutboxTable extends Table {
  /// Client-generated UUID v4; also the backend idempotency key.
  TextColumn get id => text()();

  /// Operation type routed to a registered handler,
  /// e.g. `auth.register`, `order.create`.
  TextColumn get opType => text()();

  /// Owning SDK name, e.g. `auth_sdk`, `orders_sdk`.
  TextColumn get sdk => text()();

  /// JSON-encoded operation payload. Temp-id tokens (`offline:<uuid>`)
  /// inside it are rewritten to backend ids as dependencies sync.
  TextColumn get payload => text()();

  /// JSON-encoded list of temp ids (`offline:<uuid>`) this op creates.
  TextColumn get tempIds => text()();

  /// JSON-encoded list of outbox [id]s that must sync before this op.
  TextColumn get dependsOn => text()();

  /// [OutboxStatus] name.
  TextColumn get status => text()();

  /// Push attempts made so far.
  IntColumn get attempts => integer()();

  /// Error from the most recent failed attempt.
  TextColumn get lastError => text().nullable()();

  /// Earliest time the next retry may run (backoff); null = immediately.
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
