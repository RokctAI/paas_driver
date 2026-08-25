// Copied at compose time from package:auth_sdk/src/common/infrastructure/database/offline_user_table.dart by sdk_installer_base.py's update_database_registration() -
// drift only understands table classes inside its own package.
// Copyright (c) 2026 RokctAI
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
