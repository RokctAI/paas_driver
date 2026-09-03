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


import 'package:auto_route/auto_route.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:base_sdk/src/di/injection.dart';
import 'package:base_sdk/src/domain/interface/user.dart';
import 'package:base_sdk/src/models/data/address_old_data.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
// [refork] removed host router import

import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:base_sdk/src/application/profile/profile_host_capabilities.dart';
import 'package:base_sdk/src/application/profile/profile_state.dart';
import 'package:base_sdk/src/handlers/api_result.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  /// Null where the composing shell registered no [UserRepositoryFacade]
  /// (no users_sdk): every account call below is then a no-op — see
  /// [capabilities].
  final UserRepositoryFacade? _userRepository;

  /// Null where no [ShopsRepositoryFacade] is registered (no
  /// merchants_sdk): [createShop] is then a no-op.
  final ShopsRepositoryFacade? _shopsRepository;

  /// Null where no [GalleryRepositoryFacade] is registered (no
  /// products_sdk): [createShop] is then a no-op.
  final GalleryRepositoryFacade? _galleryRepository;

  /// Which facades this notifier holds — what the generic profile host
  /// renders its surface from. Derived from the constructor arguments, so
  /// a test handing in fakes and the production [ProfileNotifier.fromLocator]
  /// agree by construction.
  final ProfileHostCapabilities capabilities;

  ProfileNotifier(
    UserRepositoryFacade? userRepository,
    ShopsRepositoryFacade? shopsRepository,
    GalleryRepositoryFacade? galleryRepository,
  )   : _userRepository = userRepository,
        _shopsRepository = shopsRepository,
        _galleryRepository = galleryRepository,
        capabilities = ProfileHostCapabilities(
          hasAccount: userRepository != null,
          hasShops: shopsRepository != null,
          hasGallery: galleryRepository != null,
        ),
        super(const ProfileState());

  /// The production constructor behind `profileProvider`: resolves each
  /// facade from [locator] (`GetIt.instance` by default) only where it is
  /// registered. A shell that registers all three gets the same three
  /// singletons the provider always resolved; one that registers none — a
  /// radio composition — gets a notifier whose account calls are no-ops
  /// instead of a `Bad state: GetIt: Object/factory with type
  /// UserRepositoryFacade is not registered` out of the page's first build.
  factory ProfileNotifier.fromLocator({GetIt? locator}) {
    final resolved = locator ?? GetIt.instance;
    return ProfileNotifier(
      resolved.isRegistered<UserRepositoryFacade>()
          ? resolved.get<UserRepositoryFacade>()
          : null,
      resolved.isRegistered<ShopsRepositoryFacade>()
          ? resolved.get<ShopsRepositoryFacade>()
          : null,
      resolved.isRegistered<GalleryRepositoryFacade>()
          ? resolved.get<GalleryRepositoryFacade>()
          : null,
    );
  }

  /// Kept for callers that compiled against base_sdk 1.57.0, where this
  /// was the provider's constructor. Forwards to [fromLocator]: the
  /// facades are resolved once here, not lazily per call.
  factory ProfileNotifier.deferred() => ProfileNotifier.fromLocator();

  int page = 1;

  getTerm({required BuildContext context}) async {
    state = state.copyWith(isTermLoading: state.term == null);
    final res = await settingsRepository.getTerm();
    res.when(
      success: (l) {
        state = state.copyWith(isTermLoading: false, term: l);
      },
      failure: (r, s) {
        state = state.copyWith(isTermLoading: false);
        AppHelpers.showCheckTopSnackBar(context, r.toString());
      },
    );
  }

  getPolicy({required BuildContext context}) async {
    state = state.copyWith(isPolicyLoading: state.policy == null);
    final res = await settingsRepository.getPolicy();
    res.when(
      success: (l) {
        state = state.copyWith(isPolicyLoading: false, policy: l);
      },
      failure: (r, s) {
        state = state.copyWith(isPolicyLoading: false);
        AppHelpers.showCheckTopSnackBar(context, r.toString());
      },
    );
  }

  resetShopData() {
    state = state.copyWith(
      bgImage: "",
      logoImage: "",
      addressModel: null,
      isSaveLoading: false,
    );
  }

  findSelectIndex() {
    for (int i = 0; i < (state.userData?.addresses?.length ?? 0); i++) {
      if (state.userData?.addresses?[i].active ?? false) {
        state = state.copyWith(selectAddress: i);
        break;
      }
    }
  }

  void change(int index) {
    state = state.copyWith(selectAddress: index);
  }

  setAddress(dynamic data) {
    state = state.copyWith(addressModel: data);
  }

  setActiveAddress({String? id, required int index}) async {
    List<AddressNewModel> list = List.from(state.userData?.addresses ?? []);
    for (var element in list) {
      element.active = false;
    }
    list[index].active = true;
    ProfileData newUser = state.userData!.copyWith(addresses: list);
    state = state.copyWith(userData: newUser);
    _userRepository?.setActiveAddress(id: id ?? "");
  }

  deleteAddress({String? id, required int index}) async {
    List<AddressNewModel> list = List.from(state.userData?.addresses ?? []);
    list.removeAt(index);
    ProfileData newUser = state.userData!.copyWith(addresses: list);
    state = state.copyWith(userData: newUser);
    _userRepository?.deleteAddress(id: id ?? "");
  }

  setBgImage(String bgImage) {
    state = state.copyWith(bgImage: bgImage);
  }

  void setFile(String file) {
    List<String> list = List.from(state.filepath);
    list.add(file);
    state = state.copyWith(filepath: list);
  }

  void deleteFile(String value) {
    List<String> list = List.from(state.filepath);
    list.remove(value);
    state = state.copyWith(filepath: list);
  }

  setLogoImage(String logoImage) {
    state = state.copyWith(logoImage: logoImage);
  }

  Future<void> fetchUser(
    BuildContext context, {
    RefreshController? refreshController,
    VoidCallback? onSuccess,
  }) async {
    // Anonymous host (no UserRepositoryFacade registered): nothing to
    // fetch and no account to fetch it for — see [capabilities].
    final userRepository = _userRepository;
    if (userRepository == null) return;
    if (LocalStorage.getToken().isNotEmpty) {
      final connected = await AppConnectivity.connectivity();
      if (connected) {
        if (refreshController == null) {
          state = state.copyWith(isLoading: true);
        }
        final response = await userRepository.getProfileDetails();
        response.when(
          success: (data) async {
            LocalStorage.setWalletData(data.data?.wallet);
            LocalStorage.setUser(data.data);
            LocalStorage.setAddressSelected(
              AddressData(
                title: data.data?.addresses?.firstWhere(
                      (element) => element.active ?? false,
                      orElse: () {
                        return AddressNewModel();
                      },
                    ).title ??
                    "",
                address: data.data?.addresses
                        ?.firstWhere(
                          (element) => element.active ?? false,
                          orElse: () {
                            return AddressNewModel();
                          },
                        )
                        .address
                        ?.address ??
                    "",
                location: LocationModel(
                  longitude: data.data?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .location
                      ?.last,
                  latitude: data.data?.addresses
                      ?.firstWhere(
                        (element) => element.active ?? false,
                        orElse: () {
                          return AddressNewModel();
                        },
                      )
                      .location
                      ?.first,
                ),
              ),
            );
            if (refreshController == null) {
              state = state.copyWith(isLoading: false, userData: data.data);
            } else {
              state = state.copyWith(userData: data.data);
            }
            refreshController?.refreshCompleted();
            onSuccess?.call();
            findSelectIndex();
          },
          failure: (failure, status) {
            if (refreshController == null) {
              state = state.copyWith(isLoading: false);
            }
            if (status == 401) {
              context.router.popUntilRoot();
              AppRoutes.I.replaceLoginRoute(context);
            }
            AppHelpers.showCheckTopSnackBar(context, failure);
          },
        );
      } else {
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    }
  }

  Future<void> fetchReferral(
    BuildContext context, {
    RefreshController? refreshController,
  }) async {
    final userRepository = _userRepository;
    if (userRepository == null) return;
    if (LocalStorage.getToken().isNotEmpty) {
      final connected = await AppConnectivity.connectivity();
      if (connected) {
        if (refreshController == null) {
          state = state.copyWith(isReferralLoading: true);
        }
        final response = await userRepository.getReferralDetails();
        response.when(
          success: (data) async {
            if (refreshController == null) {
              state = state.copyWith(
                isReferralLoading: false,
                referralData: data,
              );
            } else {
              state = state.copyWith(referralData: data);
            }
            refreshController?.refreshCompleted();
          },
          failure: (failure, status) {
            if (refreshController == null) {
              state = state.copyWith(isReferralLoading: false);
            }
            AppHelpers.showCheckTopSnackBar(context, failure);
          },
        );
      } else {
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    }
  }

  Future<void> logOut() async {
    // firebase_messaging has no Windows/Linux implementation — on desktop
    // getToken() throws [core/no-app] and the backend logout call below
    // never fired. Same platform guard + fail-open idiom as comms'
    // firebase boot hook: skip the token sync where FCM does not exist and
    // proceed straight to the backend call.
    String fcm = "";
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      try {
        fcm = await FirebaseMessaging.instance.getToken() ?? "";
      } catch (e) {
        debugPrint('==> logout fcm token skipped: $e');
      }
    }
    _userRepository?.logoutAccount(fcm: fcm);
  }

  Future<void> deleteAccount(BuildContext context) async {
    final userRepository = _userRepository;
    if (userRepository == null) return;
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true);
      final response = await userRepository.deleteAccount();
      response.when(
        success: (data) async {
          context.router.popUntilRoot();
          AppRoutes.I.replaceLoginRoute(context);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  void setUser(ProfileData user) async {
    state = state.copyWith(userData: user);
  }

  void getWallet(
    BuildContext context, {
    RefreshController? refreshController,
  }) async {
    final userRepository = _userRepository;
    if (userRepository == null) return;
    page = 1;
    if (LocalStorage.getToken().isNotEmpty) {
      final connected = await AppConnectivity.connectivity();
      if (connected) {
        if (refreshController == null) {
          state = state.copyWith(isLoadingHistory: true);
        }
        final response = await userRepository.getWalletHistories(1);
        response.when(
          success: (data) async {
            if (refreshController == null) {
              state = state.copyWith(
                isLoadingHistory: false,
                walletHistory: data.data,
              );
            } else {
              state = state.copyWith(walletHistory: data.data);
            }
            refreshController?.refreshCompleted();
          },
          failure: (failure, status) {
            if (refreshController == null) {
              state = state.copyWith(isLoadingHistory: false);
            }
            AppHelpers.showCheckTopSnackBar(context, failure);
          },
        );
      } else {
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    }
  }

  void getWalletPage(
    BuildContext context,
    RefreshController refreshController,
  ) async {
    final userRepository = _userRepository;
    if (userRepository == null) return;
    if (LocalStorage.getToken().isNotEmpty) {
      final connected = await AppConnectivity.connectivity();
      if (connected) {
        final response = await userRepository.getWalletHistories(++page);
        response.when(
          success: (data) async {
            List<WalletData> list = List.from(state.walletHistory ?? []);
            list.addAll(data.data ?? []);
            state = state.copyWith(walletHistory: list);
            refreshController.loadComplete();
            if (data.data?.isEmpty ?? true) {
              refreshController.loadNoData();
            } else {
              refreshController.loadComplete();
            }
          },
          failure: (failure, status) {
            refreshController.loadNoData();
            --page;
            AppHelpers.showCheckTopSnackBar(context, failure);
          },
        );
      } else {
        if (context.mounted) {
          AppHelpers.showNoConnectionSnackBar(context);
        }
      }
    }
  }

  changeIndex(int index) {
    state = state.copyWith(typeIndex: index);
  }

  Future<void> createShop({
    required BuildContext context,
    required String tax,
    required String deliveryTo,
    required String deliveryFrom,
    required String phone,
    required String startPrice,
    required String name,
    required String desc,
    required String perKm,
    required AddressNewModel address,
    required String deliveryType,
    required String categoryId,
  }) async {
    // Shop creation needs both the shops and the gallery facade (logo,
    // background and document uploads precede the create call); a shell
    // registering either one only cannot offer it — see [capabilities].
    final galleryRepository = _galleryRepository;
    final shopsRepository = _shopsRepository;
    if (galleryRepository == null || shopsRepository == null) return;
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isSaveLoading: true);

      String? logoImage;
      String? backgroundImage;
      List<String>? files;
      final logoResponse = await galleryRepository.uploadImage(
        state.logoImage,
        UploadType.shopsLogo,
      );
      logoResponse.when(
        success: (data) {
          logoImage = data.imageData?.title;
        },
        failure: (failure, s) {
          debugPrint('===> upload logo image failure: $failure');
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
      final backgroundResponse = await galleryRepository.uploadImage(
        state.bgImage,
        UploadType.shopsBack,
      );
      backgroundResponse.when(
        success: (data) {
          backgroundImage = data.imageData?.title;
        },
        failure: (failure, s) {
          debugPrint('===> upload background image failure: $failure');
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
      final fileResponse = await galleryRepository.uploadMultiImage(
        state.filepath,
        UploadType.shopsBack,
      );
      fileResponse.when(
        success: (data) {
          files = data.data?.title;
        },
        failure: (failure, s) {
          debugPrint('===> upload document failure: $failure');
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
      final response = await shopsRepository.createShop(
        logoImage: logoImage,
        documents: files ?? [],
        backgroundImage: backgroundImage,
        tax: double.tryParse(tax) ?? 0,
        deliveryTo: double.tryParse(deliveryTo) ?? 0,
        deliveryFrom: double.tryParse(deliveryFrom) ?? 0,
        deliveryType: deliveryType,
        phone: phone,
        name: name,
        description: desc,
        startPrice: double.tryParse(startPrice) ?? 0,
        perKm: double.tryParse(perKm) ?? 0,
        address: address,
        category: categoryId,
      );
      response.when(
        success: (data) {
          state = state.copyWith(isSaveLoading: false);
          fetchUser(context, refreshController: RefreshController());
          context.maybePop();
        },
        failure: (failure, s) {
          state = state.copyWith(isSaveLoading: false);
          AppHelpers.showCheckTopSnackBar(context, failure);
          debugPrint('==> create shop failure: $failure');
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
