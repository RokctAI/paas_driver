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


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/models/request/edit_profile.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/presentation/theme/theme.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/marker_image_cropper.dart';
import 'package:base_sdk/src/application/edit_profile/edit_profile_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final UserRepositoryFacade _userRepository;
  final GalleryRepositoryFacade? _galleryRepository;

  EditProfileNotifier(this._userRepository, this._galleryRepository)
      : super(const EditProfileState());

  void setUser(ProfileData user) {
    state = state.copyWith(
      email: user.email ?? "",
      firstName: user.firstname ?? "",
      lastName: user.lastname ?? "",
      phone: user.phone ?? "",
      secondPhone: user.secondPhone ?? "",
      gender: user.gender ?? "",
      birth: user.birthday ?? "",
    );
  }

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setFirstName(String firstName) {
    state = state.copyWith(firstName: firstName);
  }

  void setLastName(String lastName) {
    state = state.copyWith(lastName: lastName);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void setSecondPhone(String phone) {
    state = state.copyWith(secondPhone: phone);
  }

  void setBirth(String birth) {
    state = state.copyWith(birth: birth);
  }

  void setGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  getPhotoWithUrl(String url) async {
    ImageCropperForMarker imageMarker = ImageCropperForMarker();
    final file = await imageMarker.urlToFile(url);
    state = state.copyWith(imagePath: file.path);
  }

  Future<void> getPhoto() async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Image Cropper',
            toolbarColor: AppStyle.white,
            toolbarWidgetColor: AppStyle.black,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
          IOSUiSettings(title: 'Image Cropper', minimumAspectRatio: 1),
        ],
      );
      state = state.copyWith(imagePath: croppedFile?.path ?? "");
    }
  }

  Future<void> editProfile(BuildContext context, ProfileData user) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true, isSuccess: false);
      String? newImage;
      if (state.imagePath.isNotEmpty) {
        state = state.copyWith(url: "");
        if (context.mounted) {
          await updateProfileImage(context, state.imagePath);
        }
        // Uploading only stores the file; attach it to the account
        // (api.user.update_profile_image), since update_user_profile
        // ignores images.
        if (state.url.isNotEmpty && state.url != user.img) {
          final attached = await _userRepository.updateProfileImage(
            firstName: user.firstname ?? "",
            imageUrl: state.url,
          );
          attached.when(
            success: (_) => newImage = state.url,
            failure: (failure, status) {
              debugPrint('==> attach profile image failure: $failure');
              if (context.mounted) {
                AppHelpers.showCheckTopSnackBar(
                  context,
                  AppHelpers.getTranslation(status.toString()),
                );
              }
            },
          );
        }
      }
      final edited = EditProfile(
        firstname: state.firstName.isEmpty ? user.firstname : state.firstName,
        lastname: state.lastName.isEmpty ? user.lastname : state.lastName,
        birthday: state.birth.isEmpty ? user.birthday : state.birth,
        phone: state.phone.isEmpty ? user.phone : state.phone,
        email: state.email.isEmpty ? user.email : state.email,
        secondPhone: state.secondPhone,
        gender: state.gender.isEmpty ? user.gender : state.gender,
      );
      final response = await _userRepository.editProfile(user: edited);
      ProfileData? saved;
      bool ok = false;
      response.when(
        success: (data) {
          ok = true;
          saved = data.data;
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(status.toString()),
            );
          }
        },
      );
      if (!ok) return;
      // update_user_profile answers only {status, message}, no profile.
      // Storing that empty answer blanked the signed-in user, so read the
      // saved profile back, or keep the edits on the current user when
      // that read fails.
      if (saved == null) {
        final fresh = await _userRepository.getProfileDetails();
        fresh.when(
          success: (data) => saved = data.data,
          failure: (_, __) {},
        );
      }
      saved ??= user.copyWith(
        firstname: edited.firstname,
        lastname: edited.lastname,
        birthday: edited.birthday,
        phone: edited.phone,
        gender: edited.gender,
        img: newImage,
      );
      LocalStorage.setUser(saved);
      state = state.copyWith(
        userData: saved,
        isLoading: false,
        isSuccess: true,
      );
      if (context.mounted) Navigator.pop(context);
    } else {
      if (context.mounted) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      }
    }
  }

  Future<void> updateProfileImage(BuildContext context, String path) async {
    final connected = await AppConnectivity.connectivity();
    final gallery = _galleryRepository;
    if (gallery == null) {
      // No gallery facade in this composition: the avatar cannot be
      // uploaded, so the profile keeps its current image.
      debugPrint('==> profile image not uploaded: no GalleryRepositoryFacade');
      return;
    }
    if (connected) {
      String? url;
      final imageResponse = await gallery.uploadImage(
        path,
        UploadType.users,
      );
      imageResponse.when(
        success: (data) {
          url = data.imageData?.title;
          state = state.copyWith(url: url ?? "");
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          debugPrint('==> upload profile image failure: $failure');
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(status.toString()),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        state = state.copyWith(isLoading: false);
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
        );
      }
    }
  }
}
