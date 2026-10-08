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

import 'owner_scope.dart' show kUnownedOwner;

/// Generic JSON document store shared by all SDKs.
///
/// Rows are namespaced by [box] (a logical collection name, e.g. 'settings',
/// 'polaris_drafts') so feature SDKs can persist small documents without
/// registering a dedicated Drift table. SDKs with real relational needs
/// still declare typed tables via their manifest.json database section.
///
/// Rows are ALSO namespaced by [owner]. One device, one `rokct_app.sqlite`,
/// one process-wide [AppDatabase]: without an owner in the row, everything
/// two accounts store under the same box and key is the same row, and the
/// second account reads - and overwrites - the first account's document.
@DataClassName('KeyValueEntity')
class KeyValueTable extends Table {
  TextColumn get box => text()();
  TextColumn get id => text()();
  TextColumn get data => text()();

  /// Account this row belongs to, or [kUnownedOwner] for a row that belongs
  /// to nobody in particular (every row written before scoping existed, and
  /// every row written by an app nobody has signed into).
  ///
  /// NOT NULL with a default rather than nullable: see [kUnownedOwner] for
  /// why SQLite's tolerance of NULLs inside a composite PRIMARY KEY makes a
  /// nullable version of this column unsafe.
  TextColumn get owner => text().withDefault(const Constant(kUnownedOwner))();

  /// [owner] is part of the key, so two accounts can legitimately hold the
  /// same `box` + `id` side by side instead of one silently replacing the
  /// other's document. Every read filters the key down to the rows the
  /// current account may see; see `AppDatabase.ownerVisible`.
  @override
  Set<Column> get primaryKey => {box, id, owner};
}
