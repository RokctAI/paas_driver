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


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';

import 'package:base_sdk/src/application/edit_profile/edit_profile_notifier.dart';
import 'package:base_sdk/src/application/edit_profile/edit_profile_state.dart';

final editProfileProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>(
  // The gallery facade is resolved only where it is registered: a
  // composition without products/merchants (the launcher) registers none,
  // and the edit-own-details sheet must still open and save there. Without
  // it a picked avatar is not uploaded; every other field saves as before.
  (ref) => EditProfileNotifier(
    userRepository,
    getIt.isRegistered<GalleryRepositoryFacade>() ? galleryRepository : null,
  ),
);
