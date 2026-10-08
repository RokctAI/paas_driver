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
import 'package:flutter/foundation.dart';

import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/sync/sync_engine.dart' show kOfflineIdPrefix;

/// The `owner` value a row carries when it belongs to nobody in particular.
///
/// Deliberately the empty string rather than SQL NULL. `owner` is part of the
/// primary key of both owner-scoped tables, and SQLite - unlike the SQL
/// standard - does NOT enforce NOT NULL on the columns of an ordinary rowid
/// table's composite PRIMARY KEY. A nullable `owner` in that key would
/// therefore compare NULL != NULL in the backing unique index, so
/// `insertOnConflictUpdate` on an unowned row would never find its conflict
/// target and would append a second row instead of updating the first - and
/// the next single-row read would then have two rows to choose from. An empty
/// string is a value, so the key stays total and the upsert keeps working.
///
/// The visibility rule is unchanged by that encoding: a row with no owner
/// counts as the current user's, so every read filters on
/// `owner = kUnownedOwner OR owner = <me>` (the `owner IS NULL OR owner = :me`
/// of the ruling, written against a NOT NULL column).
const String kUnownedOwner = '';

/// Resolves the owner value rows written right now belong to.
///
/// Returns null when the device has no idea who is using it; [OwnerScope]
/// turns that into [kUnownedOwner] or into the last owner it saw, per the
/// teardown rule documented on [OwnerScope.current].
typedef OwnerResolver = String? Function();

/// The single place the data layer asks "whose rows are these?".
///
/// Kept out of the table definitions on purpose: `kv_tables.dart` and
/// `outbox_table.dart` declare a plain text column and know nothing about
/// sessions, and everything session-shaped lives here behind one swappable
/// [resolver] so tests can drive an owner without a `SharedPreferences`
/// store.
class OwnerScope {
  OwnerScope._internal();

  factory OwnerScope() => instance;

  static final OwnerScope instance = OwnerScope._internal();

  /// How the owner is read off the device. Replaceable so tests (and a host
  /// that keeps its account identity somewhere else) can supply their own.
  OwnerResolver resolver = defaultResolver;

  String? _lastKnown;

  /// The owner value to stamp on a row written now.
  ///
  /// Three cases, in order:
  ///
  ///  1. The resolver names an account - that account owns the write, and is
  ///     remembered.
  ///  2. The resolver names nobody but one was named earlier in this process
  ///     - the LAST KNOWN owner still owns the write. This is the sign-out
  ///     teardown case and it is the reason this cache exists: the owner read
  ///     is synchronous and unauthenticated, `LocalStorage.logout()` clears
  ///     both the stored user and the token, and every SDK's session-end hook
  ///     runs AFTER that. A write from one of those hooks (or from a widget
  ///     still settling) would otherwise land as an unowned row, and an
  ///     unowned row is visible to whoever signs in next - the departing
  ///     user's data leaking forward, which is the whole defect this scoping
  ///     exists to close. Attributing it to the account that is on its way
  ///     out keeps it where it belongs, and a fresh sign-in overwrites the
  ///     cache on its first resolve (case 1).
  ///  3. Nobody has ever been named in this process - [kUnownedOwner]. A
  ///     first launch, a never-signed-in app and every pre-scoping row on
  ///     every device already in the field all read the same way, which is
  ///     what keeps "no worse than today" true.
  String get current {
    final String? resolved = resolver();
    if (resolved != null && resolved.isNotEmpty) {
      _lastKnown = resolved;
      return resolved;
    }
    return _lastKnown ?? kUnownedOwner;
  }

  /// Test-only: forget the remembered owner and restore [defaultResolver].
  @visibleForTesting
  void debugReset({OwnerResolver? withResolver}) {
    _lastKnown = null;
    resolver = withResolver ?? defaultResolver;
  }

  /// Test-only: pretend [owner] was the last account seen, without going
  /// through a resolve.
  @visibleForTesting
  void debugRemember(String? owner) {
    _lastKnown = owner;
  }

  /// What base_sdk reads on a real device.
  ///
  /// `LocalStorage.getUser()?.id` first: that is the account identity every
  /// backend-authenticated session persists (auth_sdk's `_establishSession`
  /// via `sessionProfileOf`, and the profile fetch afterwards).
  ///
  /// The offline token second, and NOT as a fallback of convenience: a
  /// temp-local account - the exact account the "sign-out must never delete
  /// user data" ruling is about - stores NO user at all.
  /// `OfflineAuthService.registerOffline` / `loginOffline` (Users
  /// auth/dart/.../offline_auth_service.dart) call `LocalStorage.setToken`
  /// and nothing else, so `getUser()` is null for the whole of a temp-local
  /// session and the token `offline:<local user id>` is the only thing on the
  /// device that names that account. It is used WHOLE rather than split at
  /// the prefix: the string is a one-to-one function of the local user id, so
  /// it is exactly as stable as the id, and nothing here has to know how auth
  /// composes it. It is also not a credential - auth mints the local id from
  /// the clock precisely so it can never be used as one - so unlike a real
  /// bearer token it is safe to write into a column.
  ///
  /// When that account later syncs, auth swaps the token for a backend one
  /// and the owner becomes the backend user id. The rows written under the
  /// offline owner are carried across by `AppDatabase.adoptOwner`, which the
  /// sync engine calls as each temp id resolves; without that the account
  /// would come back from its first sync unable to see its own work.
  static String? defaultResolver() {
    final String? userId = LocalStorage.getUser()?.id;
    if (userId != null && userId.isNotEmpty) return userId;
    final String token = LocalStorage.getToken();
    if (token.startsWith(kOfflineIdPrefix)) return token;
    return null;
  }
}

/// The rows of an owner-scoped table [owner] may see: their own, plus every
/// row that belongs to nobody in particular.
///
/// This is the ruling written as SQL. An existing row with no owner counts as
/// the current user's, because every row on every device in the field today
/// has no owner and a strict `owner = :me` would hide all of them from
/// everybody - the one outcome "sign-out must never delete user data" rules
/// out. Legacy rows therefore stay exactly as visible as they are now, and
/// leave the unowned set as they are next written (see `AppDatabase.putItem`),
/// with no migration guessing an owner for them.
Expression<bool> ownerVisible(Expression<String> column, String owner) {
  if (owner == kUnownedOwner) return column.equals(kUnownedOwner);
  return column.equals(kUnownedOwner) | column.equals(owner);
}
