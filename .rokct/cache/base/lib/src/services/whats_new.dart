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

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';

import 'demo_session.dart';
import 'local_storage.dart';

/// One release's note, as the release workflow packs it into the app.
class WhatsNewNote {
  final String version;
  final String notes;
  const WhatsNewNote(this.version, this.notes);
}

/// The in-app "What's new" note (Ray, 2026-11-27).
///
/// The release workflow (shared-workflows universal-release.yml, step
/// "Pack What's New Into The App") writes the note BEFORE it builds, into
/// [asset], so every version carries its own note, never the previous
/// release's. [due] answers once per version: a fresh install only records
/// the version (nothing to compare with), an update shows the note once.
/// Nothing is fetched, so GitHub limits never apply.
class WhatsNew {
  WhatsNew._();

  static const asset = 'assets/whats_new.json';
  static const storageKey = 'whats_new.v1';

  /// Reads the packed note; null when the build packed none.
  static Future<WhatsNewNote?> load({AssetBundle? bundle}) async {
    try {
      final raw = await (bundle ?? rootBundle).loadString(asset);
      final j = jsonDecode(raw);
      if (j is! Map) return null;
      final v = '${j['version'] ?? ''}'.trim();
      final n = '${j['notes'] ?? ''}'.trim();
      if (v.isEmpty || n.isEmpty) return null;
      return WhatsNewNote(v, n);
    } catch (_) {
      return null;
    }
  }

  /// The note to show now, or null. Marks the version as seen either way.
  ///
  /// Keyed by the installed build, not the version: a rebuild of the same
  /// version (bug fixes, an SDK pin) gets a new build number, and its
  /// rewritten note replaces the old one, so it shows once more. [build]
  /// is for tests; the app reads its own.
  static Future<WhatsNewNote?> due({AssetBundle? bundle, String? build}) async {
    if (DemoSession.demoActive) return null;
    final note = await load(bundle: bundle);
    if (note == null) return null;
    final b = build ?? (await PackageInfo.fromPlatform()).buildNumber;
    final key = '${note.version}+$b';
    final seen = LocalStorage.getJson(storageKey)?['seen'];
    if (seen == key) return null;
    await LocalStorage.setJson(storageKey, {'seen': key});
    return seen == null ? null : note;
  }
}
