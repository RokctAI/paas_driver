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

/// Generic JSON document store shared by all SDKs.
///
/// Rows are namespaced by [box] (a logical collection name, e.g. 'settings',
/// 'polaris_drafts') so feature SDKs can persist small documents without
/// registering a dedicated Drift table. SDKs with real relational needs
/// still declare typed tables via their manifest.json database section.
@DataClassName('KeyValueEntity')
class KeyValueTable extends Table {
  TextColumn get box => text()();
  TextColumn get id => text()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {box, id};
}
