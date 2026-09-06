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

import 'package:base_sdk/src/constants/demo_currency.dart';
import 'package:base_sdk/src/constants/demo_images.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/data/address_information.dart';
import 'package:base_sdk/src/models/request/edit_profile.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:users_sdk/src/common/services/session_end_hooks.dart';

/// Demo-build (`--dart-define=IS_DEMO=true`) implementation of base_sdk's
/// [UserRepositoryFacade], selected by `UsersSdkDependencies.register`.
///
/// A demo build talks to no backend, so the HTTP `UserRepository` failed
/// every `profileProvider.fetchUser`; `LocalStorage.getUser()` stayed null
/// (auth_sdk never persists the login user - production relies on this
/// fetch to do it) and base_sdk's `GenericProfilePage` fell back to
/// "Profile" for the name and a "?" avatar, with the failure snackbar on
/// top, in every shell's tour still.
///
/// Serves the account auth_sdk's `MockAuthRepository` signs in - Thandi
/// Mokoena, the seller commerce's demo shop seeds - with the same home
/// address `MockAddressRepository` puts in the address book. The name and
/// address literals are repeated here rather than imported (ADR-005
/// forbids cross-SDK imports); the avatar is base_sdk's
/// `DemoImages.avatar`, the one copy both repositories read.
///
/// Never invents a role: the sign-in ADDRESS decides it
/// (`MockAuthRepository._demoRolesByEmail`), and merchants' signed-in
/// toast and orders board read `LocalStorage.getUser()?.role`, so the role
/// (and email) come from the persisted session when there is one and stay
/// unset otherwise - exactly what those readers saw before this
/// repository existed.
class MockUserRepository implements UserRepositoryFacade {
  /// In-memory account for the session: edits and avatar changes stick
  /// until the app restarts, so the edit-profile sheet round-trips.
  ProfileData _profile = ProfileData(
    id: "1",
    uuid: "demo_uuid",
    firstname: "Thandi",
    lastname: "Mokoena",
    email: "thandi.mokoena@outlook.com",
    phone: "+27 82 456 7890",
    active: true,
    // base_sdk's inline `data:` SVG initials avatar: carries its own
    // pixels, so it renders offline and on the CI tour emulator.
    img: DemoImages.avatar,
    addresses: [
      AddressNewModel(
        id: "1",
        title: "Home",
        address: AddressInformation(
          address: "42 Marula Avenue, Sandton",
          house: "42",
          floor: "1",
        ),
        active: true,
        location: [-26.1076, 28.0567],
      ),
    ],
    // The account's wallet, in the currency every demo amount prints in
    // (base_sdk's DemoCurrency - South African rand, "R793.00"). The
    // balance is the net of wallet_sdk's demo ledger (a top-up, two
    // purchases, a partial refund and a cash-out on wallet `wallet-1`),
    // so the profile card and the history page agree.
    wallet: Wallet(
      id: 1,
      uuid: 'wallet-1',
      userId: 1,
      price: 793.00,
      currency: DemoCurrency.rand,
    ),
  );

  ProfileResponse _response() => ProfileResponse(status: true, data: _profile);

  @override
  Future<ApiResult<ProfileResponse>> getProfileDetails() async {
    // copyWith keeps the current value for a null argument, so a missing
    // session leaves email and role exactly as they are (role unset).
    final ProfileData? session = LocalStorage.getUser();
    _profile = _profile.copyWith(email: session?.email, role: session?.role);
    return ApiResult.success(data: _response());
  }

  @override
  Future<ApiResult<ReferralModel>> getReferralDetails() async {
    return ApiResult.success(data: ReferralModel(active: false));
  }

  @override
  Future<ApiResult<dynamic>> saveLocation({
    required AddressNewModel? address,
  }) async {
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<dynamic>> updateLocation({
    required AddressNewModel? address,
    required String? addressId,
  }) async {
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<dynamic>> setActiveAddress({required String id}) async {
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<dynamic>> deleteAddress({required String id}) async {
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<dynamic>> deleteAccount() async {
    // Same session-end sequence as the HTTP repository, minus the call the
    // demo build has nobody to make: hooks first, then the local session.
    await SessionEndHooks.run();
    LocalStorage.logout();
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<dynamic>> logoutAccount({required String fcm}) async {
    await SessionEndHooks.run();
    LocalStorage.logout();
    return const ApiResult.success(data: null);
  }

  @override
  Future<ApiResult<ProfileResponse>> editProfile({
    required EditProfile? user,
  }) async {
    _profile = _profile.copyWith(
      firstname: user?.firstname,
      lastname: user?.lastname,
      email: user?.email,
      phone: user?.phone,
      secondPhone: user?.secondPhone,
      birthday: user?.birthday,
      gender: user?.gender,
      img: user?.images,
    );
    return ApiResult.success(data: _response());
  }

  @override
  Future<ApiResult<ProfileResponse>> updateProfileImage({
    required String firstName,
    required String imageUrl,
  }) async {
    _profile = _profile.copyWith(firstname: firstName, img: imageUrl);
    return ApiResult.success(data: _response());
  }

  @override
  Future<ApiResult<ProfileResponse>> updatePassword({
    required String password,
    required String passwordConfirmation,
  }) async {
    return ApiResult.success(data: _response());
  }

  @override
  Future<ApiResult<WalletHistoriesResponse>> getWalletHistories(
    int page,
  ) async {
    return ApiResult.success(data: WalletHistoriesResponse(data: const []));
  }

  @override
  Future<ApiResult<void>> updateFirebaseToken(String? token) async {
    return const ApiResult.success(data: null);
  }

  @override
  Future<dynamic> searchUser({required String name, required int page}) async {
    return null;
  }
}
