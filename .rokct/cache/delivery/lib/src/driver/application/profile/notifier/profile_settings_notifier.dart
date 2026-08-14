import 'package:base_sdk/src/handlers/api_result.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:delivery_sdk/src/driver/domain/interface/courier.dart';


import 'package:delivery_sdk/src/driver/application/profile/state/profile_settings_state.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/tr_keys.dart';

/// The courier-earnings block the legacy notifier also carried
/// (`fetchProfileStatistics` over revenue_sdk's facade) moved to the
/// host-composition provider this SDK installs at
/// lib/presentation/pages/profile/courier_statistics_provider.dart —
/// delivery_sdk src imports no sibling SDK but base_sdk (Ray's rule).
class ProfileSettingsNotifier extends StateNotifier<ProfileSettingsState> {
  final UserRepositoryFacade _userRepository;
  final CourierRepositoryFacade _courierRepository;

  ProfileSettingsNotifier(this._userRepository, this._courierRepository)
      : super(const ProfileSettingsState());

  Future<void> fetchProfileDetails({
    required BuildContext context,
    VoidCallback? checkYourNetwork,
    Function(String?)? setImage,
    Function(ProfileData?)? setUserData,
  }) async {
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(isLoading: true);
      final response = await _userRepository.getProfileDetails();
      response.when(
        success: (data) {
          state = state.copyWith(userData: data.data, isLoading: false);
          if (setImage != null) {
            setImage(data.data?.img);
          }
          if (setUserData != null) {
            setUserData(data.data);
          }
          LocalStorage.setUser(data.data);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          debugPrint('==> get profile details failure: $failure');
        },
      );
    } else {
      checkYourNetwork?.call();
    }
  }

  Future<void> fetchRequestResponse({
    required BuildContext context,
  }) async {
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(isLoading: true);
      final response = await _courierRepository.getRequestModel();
      response.when(
        success: (data) {
          state = state.copyWith(
            requestData: (data.data?.isEmpty ?? true) ? null : data.data?.first,
            isLoading: false,
          );
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          debugPrint('==> get request response failure: $failure');
        },
      );
    } else {
      // ignore: use_build_context_synchronously
      AppHelpers.showNoConnectionSnackBar(context);
    }
  }

  clearRequest() {
    state = state.copyWith(requestData: null);
  }

  setPhone(String? data) {
    state = state.copyWith(userData: ProfileData(phone: data));
  }

  setEmail(String? data) {
    state = state.copyWith(userData: ProfileData(email: data));
  }


  Future<void> deleteAccount(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true);
      final response = await _userRepository.deleteAccount();
      response.when(
        success: (data) async {
          LocalStorage.logout();
          Navigator.of(context).popUntil((route) => route.isFirst);
          AppRoutes.I.replaceLoginRoute(context);
        },
        failure: (fail, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            fail,
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }
}
