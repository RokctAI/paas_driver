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


import 'package:base_sdk/src/models/request/edit_profile.dart';
import 'package:base_sdk/src/handlers/handlers.dart';
import 'package:base_sdk/src/models/models.dart';

abstract class UserRepositoryFacade {
  Future<ApiResult<ProfileResponse>> getProfileDetails();

  Future<ApiResult<ReferralModel>> getReferralDetails();

  Future<ApiResult<dynamic>> saveLocation({required AddressNewModel? address});

  Future<ApiResult<dynamic>> updateLocation({
    required AddressNewModel? address,
    required String? addressId,
  });

  Future<ApiResult<dynamic>> setActiveAddress({required String id});

  Future<ApiResult<dynamic>> deleteAddress({required String id});

  Future<ApiResult<dynamic>> deleteAccount();

  Future<ApiResult<dynamic>> logoutAccount({required String fcm});

  Future<ApiResult<ProfileResponse>> editProfile({required EditProfile? user});

  Future<ApiResult<ProfileResponse>> updateProfileImage({
    required String firstName,
    required String imageUrl,
  });

  Future<ApiResult<ProfileResponse>> updatePassword({
    required String password,
    required String passwordConfirmation,
  });

  Future<ApiResult<WalletHistoriesResponse>> getWalletHistories(int page);

  Future<ApiResult<void>> updateFirebaseToken(String? token);

  Future<dynamic> searchUser({required String name, required int page});
}
