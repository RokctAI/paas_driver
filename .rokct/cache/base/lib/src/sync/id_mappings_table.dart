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
