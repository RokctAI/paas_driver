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

import '../services/local_storage.dart';
import 'guide_progress.dart';

/// Where one guide's progress lives. Implementations never throw on a
/// missing or corrupt record: they return a fresh [GuideProgress].
abstract class GuideStore {
  Future<GuideProgress> read(String guideId);
  Future<void> write(String guideId, GuideProgress progress);
}

/// The default store: base_sdk's generic `LocalStorage` JSON key API. Like
/// onboarding progress, guide progress is per install and survives sign-out.
class LocalStorageGuideStore implements GuideStore {
  const LocalStorageGuideStore();

  static String keyFor(String guideId) => 'guide.v1.$guideId';

  @override
  Future<GuideProgress> read(String guideId) async =>
      GuideProgress.fromJson(LocalStorage.getJson(keyFor(guideId))) ??
      const GuideProgress.fresh();

  @override
  Future<void> write(String guideId, GuideProgress progress) =>
      LocalStorage.setJson(keyFor(guideId), progress.toJson());
}

/// Test double. Holds records in memory for the life of the object.
class InMemoryGuideStore implements GuideStore {
  final Map<String, GuideProgress> records = {};

  @override
  Future<GuideProgress> read(String guideId) async =>
      records[guideId] ?? const GuideProgress.fresh();

  @override
  Future<void> write(String guideId, GuideProgress progress) async {
    records[guideId] = progress;
  }
}
