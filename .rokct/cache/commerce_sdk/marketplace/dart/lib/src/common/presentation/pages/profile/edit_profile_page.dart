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

// The customer edit-own-details sheet was PROMOTED verbatim to base_sdk
// (1.45.0, approved frame 4d 2026-08-30 — chips 725-734) so every
// GenericProfilePage host can wire the user-card pencil (chip 109,
// ProfileSectionRegistry.I.onEditProfile) to the one shipped flow — the
// manager hub is the first new consumer. This file stays as the
// marketplace call-sites' import path (my_account.dart's "Edit account"
// row) and re-exports the shared component; customer behavior is
// unchanged — same class name, same `EditProfileScreen(controller: c)`
// drag-sheet contract, same base_sdk editProfileProvider save path.
export 'package:base_sdk/src/presentation/pages/profile/edit_profile_sheet.dart'
    show EditProfileScreen;
