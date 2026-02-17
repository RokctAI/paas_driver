import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:driver/domain/interface/interfaces.dart';
import '../../../../infrastructure/services/services.dart';
import '../state/profile_image_state.dart';

class ProfileImageNotifier extends StateNotifier<ProfileImageState> {
  final UserRepository _userRepository;
  final SettingsRepository _settingsRepository;

  ProfileImageNotifier(this._userRepository, this._settingsRepository)
    : super(const ProfileImageState());

  Future<void> updateProfileImage({
    required BuildContext context,
    required String path,
    String? firstname,
  }) async {
    String? url;
    final imageResponse = await _settingsRepository.uploadImage(
      path,
      UploadType.users,
    );
    imageResponse.when(
      success: (data) {
        url = data.imageData?.title;
      },
      failure: (failure, status) {
        debugPrint('==> upload profile image failure: $failure');
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
      },
    );
    if (url == null) {
      return;
    }
    final response = await _userRepository.updateProfileImage(
      imageUrl: url,
      firstName: firstname,
    );
    response.when(
      success: (data) {
        LocalStorage.setUser(data.data);
        setUrl(data.data?.img);
      },
      failure: (failure, status) {
        debugPrint('==> update profile image failure: $failure');
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
      },
    );
  }

  Future<void> editCarImage({
    required BuildContext context,
    required String path,
  }) async {
    final imageResponse = await _settingsRepository.uploadImage(
      path,
      UploadType.deliveryCar,
    );
    imageResponse.when(
      success: (data) {
        state = state.copyWith(carImageUrl: data.imageData?.title);
      },
      failure: (failure, status) {
        debugPrint('==> upload profile image failure: $failure');
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(failure),
        );
      },
    );
  }

  void setUrlCar(String? url) {
    state = state.copyWith(carImageUrl: url);
  }

  void changePhoto({
    String? path,
    String? firstname,
    required BuildContext context,
  }) {
    state = state.copyWith(path: path, imageUrl: null);
    if (path != null) {
      updateProfileImage(path: path, firstname: firstname, context: context);
    }
  }

  void setUrl(String? url) {
    state = state.copyWith(path: null, imageUrl: url);
  }
}
