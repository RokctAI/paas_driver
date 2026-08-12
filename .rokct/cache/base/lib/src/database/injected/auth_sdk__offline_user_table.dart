// Copied at compose time from package:auth_sdk/src/common/infrastructure/database/offline_user_table.dart by sdk_installer_base.py's update_database_registration() -
// drift only understands table classes inside its own package.
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
  TextColumn get id => text().clientDefault(() => '')(); // local UUID
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
