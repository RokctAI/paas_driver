import 'package:base_sdk/src/handlers/api_result.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/user.dart';

import 'package:delivery_sdk/src/driver/application/profile/state/profile_image_state.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';

class ProfileImageNotifier extends StateNotifier<ProfileImageState> {
  final UserRepositoryFacade _userRepository;
  final GalleryRepositoryFacade _galleryRepository;

  ProfileImageNotifier(this._userRepository, this._galleryRepository)
      : super(const ProfileImageState());

  Future<void> updateProfileImage({
    required BuildContext context,
    required String path,
    String? firstname,
  }) async {
    String? url;
    final imageResponse =
        await _galleryRepository.uploadImage(path, UploadType.users);
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
      imageUrl: url ?? '',
      firstName: firstname ?? '',
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
    final imageResponse =
        // Legacy UploadType.deliveryCar has no base_sdk counterpart (adding
        // it would break products_sdk's exhaustive switch); the Frappe
        // gallery maps the courier's own uploads to the User doctype, which
        // is exactly what UploadType.users resolves to.
        await _galleryRepository.uploadImage(path, UploadType.users);
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

  void changePhoto(
      {String? path, String? firstname, required BuildContext context}) {
    state = state.copyWith(path: path, imageUrl: null);
    if (path != null) {
      updateProfileImage(path: path, firstname: firstname, context: context);
    }
  }

  void setUrl(String? url) {
    state = state.copyWith(path: null, imageUrl: url);
  }
}
