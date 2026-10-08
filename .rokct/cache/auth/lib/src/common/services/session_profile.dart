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

import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/local_storage.dart';

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
    isDemoAccount: user.isDemoAccount,
  );
}

/// Stores the signed-in account the way login does, for the register and
/// confirmation paths: [user] (a login-shaped [UserModel] or a full
/// [ProfileData]) when the response carried one, otherwise the
/// profile fetched from [users] right away. Seeds and scopes that read
/// `LocalStorage.getUser()` (productivity's MaintenanceSeed, OwnerScope)
/// then see the new account straight after sign-up. Never throws.
Future<void> storeSessionProfile(
  Object? user,
  UserRepositoryFacade users,
) async {
  if (user is UserModel) {
    await LocalStorage.setUser(sessionProfileOf(user));
    return;
  }
  if (user is ProfileData) {
    await LocalStorage.setUser(user);
    return;
  }
  try {
    final result = await users.getProfileDetails();
    final profile = result.when(
      success: (data) => data.data,
      failure: (_, __) => null,
    );
    if (profile != null) await LocalStorage.setUser(profile);
  } catch (_) {
    // The token is stored; profileProvider.fetchUser retries later.
  }
}
