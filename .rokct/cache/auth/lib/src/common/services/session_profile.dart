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

import 'package:base_sdk/src/models/models.dart';

/// The account a credential exchange came back with, in the shape
/// `LocalStorage.setUser` persists.
///
/// The login response's [UserModel] and the profile endpoint's
/// [ProfileData] decode the same backend user document; the former is the
/// subset the login contract carries. This lifts every field it has, one
/// to one, and leaves the profile-only fields (wallet, shop, membership,
/// referral counters) unset for `profileProvider.fetchUser` to fill in -
/// nothing is guessed. Until the login flow persisted this, the stored
/// user stayed null between sign-in and that fetch, and base_sdk's
/// `GenericProfilePage` (which renders `state.userData ??
/// LocalStorage.getUser()`) painted an empty header first.
ProfileData sessionProfileOf(UserModel user) {
  return ProfileData(
    id: user.id,
    uuid: user.uuid,
    firstname: user.firstname,
    lastname: user.lastname,
    referral: user.referral,
    email: user.email,
    phone: user.phone,
    birthday: user.birthday,
    gender: user.gender,
    emailVerifiedAt: user.emailVerifiedAt,
    registeredAt: user.registeredAt,
    active: user.active,
    img: user.img,
    role: user.role,
    addresses: user.addresses,
  );
}
