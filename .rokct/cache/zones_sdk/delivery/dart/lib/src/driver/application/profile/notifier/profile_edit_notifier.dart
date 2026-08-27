// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:base_sdk/src/handlers/api_result.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';


import 'package:delivery_sdk/src/driver/application/profile/state/profile_edit_state.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final CourierRepositoryFacade _courierRepository;

  ProfileEditNotifier(this._courierRepository)
      : super(const ProfileEditState());

  void toggleShowConfirmPassword() {
    state = state.copyWith(showConfirmPassword: !state.showConfirmPassword);
  }

  void toggleShowPassword() {
    state = state.copyWith(showPassword: !state.showPassword);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(
      confirmPassword: value.trim(),
      isConfirmPasswordError: false,
    );
  }

  void setPassword(String value) {
    state = state.copyWith(password: value.trim(), isPasswordError: false);
  }

  Future<void> updateGeneralInfo({
    required BuildContext context,
    VoidCallback? checkYourNetwork,
    VoidCallback? updated,
  }) async {
    if (state.firstname.trim().isEmpty) {
      state = state.copyWith(isFirstnameError: true);
      return;
    }
    if (state.lastname.trim().isEmpty) {
      state = state.copyWith(isLastnameError: true);
      return;
    }
    if (state.password.isNotEmpty && state.password.length < 6) {
      state = state.copyWith(isPasswordError: true);
      return;
    }
    if (state.confirmPassword != state.password) {
      state = state.copyWith(isConfirmPasswordError: true);
      return;
    }
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(isLoading: true);
      final response = await _courierRepository.updateGeneralInfo(
        firstName: state.firstname.trim(),
        lastName: state.lastname.trim(),
        phone: state.isPhoneEditable ? state.phone : null,
        email: state.isEmailEditable ? state.email : null,
        password: state.password.isEmpty ? null : state.password,
        confirmPassword: state.password.isEmpty ? null : state.confirmPassword,
      );
      response.when(
        success: (data) {
          LocalStorage.setUser(data.data);
          state = state.copyWith(isLoading: false);
          updated?.call();
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
          debugPrint('==> update profile details failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  void setInitialInfo(ProfileData? userData) {
    state = state.copyWith(
      firstname: userData?.firstname ?? '',
      lastname: userData?.lastname ?? '',
      phone: userData?.phone ?? '',
      email: userData?.email ?? '',
      isEmailEditable: userData?.email?.isEmpty ?? true,
      isPhoneEditable: userData?.phone?.isEmpty ?? true,
      isFirstnameError: false,
      isLastnameError: false,
      isPasswordError: false,
      isConfirmPasswordError: false,
      showPassword: false,
      showConfirmPassword: false,
      password: '',
      confirmPassword: '',
    );
  }

  void setFirstname(String value) {
    state = state.copyWith(firstname: value.trim(), isFirstnameError: false);
  }

  void setLastname(String value) {
    state = state.copyWith(lastname: value.trim(), isLastnameError: false);
  }

  void setPhone(String value) {
    state = state.copyWith(phone: value.trim());
  }

  void setEmail(String value) {
    state = state.copyWith(email: value.trim());
  }

  Future<void> editCarInfo({
    required BuildContext context,
    VoidCallback? checkYourNetwork,
    VoidCallback? updated,
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String weight,
    required String length,
    required String width,
    String? imageUrl,
  }) async {
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(isLoading: true);
      final response = await _courierRepository.editCarInfo(
        type: type,
        brand: brand,
        model: model,
        number: number,
        color: color,
        imageUrl: imageUrl,
        height: height,
        weight: weight,
        length: length,
        width: width,
      );
      response.when(
        success: (data) {
          CourierStorage.setDeliveryInfo(data);
          CourierStorage.setOnline(data.data?.online ?? false);
          state = state.copyWith(isLoading: false);
          updated?.call();
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
          debugPrint('==> update profile details failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      }
    }
  }

  Future<void> createCarInfo({
    required BuildContext context,
    VoidCallback? checkYourNetwork,
    VoidCallback? updated,
    required String type,
    required String brand,
    required String model,
    required String number,
    required String color,
    required String height,
    required String weight,
    required String length,
    required String width,
    String? imageUrl,
  }) async {
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(isLoading: true);
      final response = await _courierRepository.createCarInfo(
        type: type,
        brand: brand,
        model: model,
        number: number,
        color: color,
        imageUrl: imageUrl,
        height: height,
        weight: weight,
        length: length,
        width: width,
      );
      response.when(
        success: (data) {
          CourierStorage.setDeliveryInfo(data);
          CourierStorage.setOnline(data.data?.online ?? false);
          state = state.copyWith(isLoading: false);
          updated?.call();
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
          debugPrint('==> update profile details failure: $failure');
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      }
    }
  }
}
