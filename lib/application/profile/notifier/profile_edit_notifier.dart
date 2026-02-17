import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driver/domain/interface/interfaces.dart';
import '../../../../infrastructure/models/models.dart';
import '../../../../infrastructure/services/services.dart';
import '../state/profile_edit_state.dart';

class ProfileEditNotifier extends StateNotifier<ProfileEditState> {
  final UserRepository _userRepository;

  ProfileEditNotifier(this._userRepository) : super(const ProfileEditState());

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
      final response = await _userRepository.updateGeneralInfo(
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

  void setInitialInfo(UserData? userData) {
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
      final response = await _userRepository.editCarInfo(
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
          LocalStorage.setDeliveryInfo(data);
          LocalStorage.setOnline(data.data?.online ?? false);
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
      final response = await _userRepository.createCarInfo(
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
          LocalStorage.setDeliveryInfo(data);
          LocalStorage.setOnline(data.data?.online ?? false);
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
