import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/models/data/shop_data.dart';
import 'package:base_sdk/src/models/data/translation.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:merchants_sdk/src/manager/application/restaurant/restaurant_state.dart';
import 'package:merchants_sdk/src/manager/domain/interface/seller_shop.dart';

/// Port of paas_manager `application/restaurant/restaurant_notifier.dart`.
///
/// Deltas from the legacy notifier, all forced by the SDK split:
/// - repositories: the legacy `UsersInterface`/`SettingsInterface` pair is
///   now [SellerShopRepositoryFacade] (this SDK) + base_sdk's
///   [GalleryRepositoryFacade] for image upload;
/// - `get_shop` does not return working days, so [fetchMyShop] fetches them
///   separately and merges into `shop.shopWorkingDays` (base's mutable
///   model);
/// - `setOnlineOffline` sends the explicit desired status (computed here)
///   and flips state optimistically — the Frappe endpoint sets, it does not
///   toggle;
/// - after a successful update the shop is refetched instead of trusting
///   `update_shop`'s raw `shop.as_dict()` echo, whose keys don't match the
///   read shape;
/// - the shop is persisted with `LocalStorage.setShopJson` (base_sdk keeps
///   the shop as raw JSON; there is no typed setter).
class RestaurantNotifier extends StateNotifier<RestaurantState> {
  final SellerShopRepositoryFacade _shopRepository;
  final GalleryRepositoryFacade _galleryRepository;
  String _title = '';
  String _description = '';
  String _phone = '';

  RestaurantNotifier(this._shopRepository, this._galleryRepository)
      : super(const RestaurantState());

  Future<void> updateWorkingDays(List<ShopWorkingDay> days) async {
    final shop = state.shop;
    if (shop != null) {
      shop.shopWorkingDays = days;
      LocalStorage.setShopJson(shop.toJson());
    }
    state = state.copyWith(shop: shop);
  }

  Future<void> fetchMyShop({VoidCallback? afterFetched}) async {
    final response = await _shopRepository.getMyShop();
    await response.when(
      success: (data) async {
        final shop = data.data;
        final daysResponse = await _shopRepository.getShopWorkingDays();
        daysResponse.when(
          success: (days) => shop?.shopWorkingDays = days,
          failure: (failure, status) =>
              debugPrint('==> error fetching working days $failure'),
        );
        LocalStorage.setShopJson(shop?.toJson());
        state = state.copyWith(
          shop: shop,
          orderPayment: data.orderPayment,
          pendingSync: false,
        );
        afterFetched?.call();
      },
      failure: (failure, status) async {
        // Backend unreachable: fall back to the cached shop, which for an
        // offline-created shop is the local-first record seeded by
        // createShop (temp `offline:` id, pending_sync flag) — the merge of
        // backend truth and not-yet-synced local state for this screen.
        final cached = LocalStorage.getShopJson();
        state = state.copyWith(
          shop: cached == null ? null : ShopData.fromJson(cached),
          pendingSync: cached?['pending_sync'] == true,
        );
        afterFetched?.call();
        debugPrint('==> error with fetching my shop $failure');
      },
    );
  }

  void setPhone(String value) {
    _phone = value.trim();
  }

  void setDescription(String value) {
    _description = value.trim();
  }

  void setTitle(String value) {
    _title = value.trim();
  }

  void setPayment(String value) {
    state = state.copyWith(orderPayment: value);
  }

  void setLogoImageFile(String? file) {
    state = file == null
        ? state.copyWith(clearLogoImageFile: true)
        : state.copyWith(logoImageFile: file);
  }

  void setBackgroundImageFile(String? file) {
    state = file == null
        ? state.copyWith(clearBackgroundImageFile: true)
        : state.copyWith(backgroundImageFile: file);
  }

  Future<void> updateShop(
    BuildContext context, {
    VoidCallback? updateSuccess,
  }) async {
    state = state.copyWith(isLoading: true);
    String? backUrl;
    if (state.backgroundImageFile != null) {
      final imageResponse = await _galleryRepository.uploadImage(
        state.backgroundImageFile!,
        UploadType.shopsBack,
      );
      imageResponse.when(
        success: (data) {
          backUrl = data.imageData?.title;
        },
        failure: (failure, status) {
          debugPrint('==> upload shop back image fail: $failure');
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    }
    String? logoUrl;
    if (state.logoImageFile != null) {
      final imageResponse = await _galleryRepository.uploadImage(
        state.logoImageFile!,
        UploadType.shopsLogo,
      );
      imageResponse.when(
        success: (data) {
          logoUrl = data.imageData?.title;
        },
        failure: (failure, status) {
          debugPrint('==> upload shop logo image fail: $failure');
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    }
    Translation? newTranslation = state.shop?.translation;
    newTranslation = (newTranslation ?? Translation()).copyWith(
      title: _title.isNotEmpty ? _title : newTranslation?.title,
      description:
          _description.isNotEmpty ? _description : newTranslation?.description,
    );

    final response = await _shopRepository.updateShop(
      backImg: backUrl ?? state.shop?.backgroundImg,
      logoImg: logoUrl ?? state.shop?.logoImg,
      tax: state.shop?.tax?.toString(),
      phone: _phone.isNotEmpty ? _phone : state.shop?.phone,
      minAmount: state.shop?.minAmount?.toString(),
      translation: newTranslation,
      deliveryTimeType: state.shop?.deliveryTime?.type,
      deliveryTimeFrom: state.shop?.deliveryTime?.from,
      deliveryTimeTo: state.shop?.deliveryTime?.to,
      orderPayment: state.orderPayment,
    );
    await response.when(
      success: (data) async {
        _title = '';
        _description = '';
        _phone = '';
        state = state.copyWith(
          isLoading: false,
          clearBackgroundImageFile: true,
          clearLogoImageFile: true,
        );
        await fetchMyShop();
        updateSuccess?.call();
      },
      failure: (failure, status) async {
        debugPrint('===> update shop fail $failure');
        state = state.copyWith(isLoading: false);
        AppHelpers.showCheckTopSnackBar(context, failure);
      },
    );
  }

  void setOnlineOffline() {
    final bool target = !(state.shop?.open ?? false);
    final shop = state.shop;
    if (shop != null) {
      shop.open = target;
      LocalStorage.setShopJson(shop.toJson());
    }
    state = state.copyWith(shop: shop);
    _shopRepository.setWorkingStatus(open: target);
  }
}
