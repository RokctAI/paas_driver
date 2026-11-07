// Copied at compose time from package:auth_sdk/src/common/infrastructure/database/offline_user_table.dart by sdk_installer_base.py's update_database_registration() -
// drift only understands table classes inside its own package.
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

/// Local account storage for offline registration/login. A row here is a
/// real usable account the moment it's created — the user isn't blocked
/// waiting for a network round trip — but it's not yet a real backend
/// account until [synced] flips true (see OfflineAuthService.trySync()).
///
/// passwordHash is a local-only SHA-256 hash: it authenticates "is this the
/// same device/person who registered offline," nothing more. The backend's
/// own password hashing takes over once the account syncs for real; this
/// hash is never sent anywhere.
@DataClassName('OfflineUserEntity')
class OfflineUsersTable extends Table {
  // Local-only row identifier (epoch-derived, NOT a UUID — see
  // OfflineAuthService.registerOffline). Predictable by design constraints,
  // so it must never double as a credential; the sync push registers the
  // backend account with a random secret instead.
  TextColumn get id => text().clientDefault(() => '')();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get firstName => text().nullable()();
  TextColumn get lastName => text().nullable()();
  TextColumn get passwordHash => text()();
  TextColumn get referral => text().nullable()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get backendUserId => text().nullable()();
  TextColumn get backendToken => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
