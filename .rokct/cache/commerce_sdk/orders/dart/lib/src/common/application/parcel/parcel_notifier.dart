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
import 'package:base_sdk/src/handlers/api_result.dart';
import 'package:base_sdk/src/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:base_sdk/src/domain/interface/parcel.dart';
import 'package:base_sdk/src/models/models.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/marker_image_cropper.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
// [refork] removed host router import
import 'package:url_launcher/url_launcher.dart';

import 'package:base_sdk/src/domain/interface/draw.dart';
import 'package:orders_sdk/src/common/application/parcel/parcel_state.dart';
import 'package:orders_sdk/src/common/infrastructure/repositories/parcel_repository.dart';

class ParcelNotifier extends StateNotifier<ParcelState> {
  final ParcelRepositoryFacade _parcelRepository;
  final DrawRepositoryFacade _drawRouting;

  ParcelNotifier(this._parcelRepository, this._drawRouting)
      : super(const ParcelState());

  Future<void> addReview(
    BuildContext context,
    String comment,
    double rating,
  ) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isButtonLoading: true);
      final response = await _parcelRepository.addReview(
        (state.parcel?.id ?? "").toString(),
        rating: rating,
        comment: comment,
      );
      response.when(
        success: (data) async {
          state = state.copyWith(isButtonLoading: false);
          context.maybePop(context);
        },
        failure: (failure, status) {
          state = state.copyWith(isButtonLoading: false);
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(context, failure);
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  changeExpand() {
    state = state.copyWith(expand: !state.expand);
  }

  setPayment(PaymentData selectPayment) {
    state = state.copyWith(selectPayment: selectPayment);
  }

  changeAnonymous() {
    state = state.copyWith(anonymous: !state.anonymous);
  }

  changeCodEnabled() {
    state = state.copyWith(codEnabled: !state.codEnabled);
  }

  Future<void> fetchTypes(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true);
      final response = await _parcelRepository.getTypes();
      response.when(
        success: (data) {
          state = state.copyWith(isLoading: false, types: data.data ?? []);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(status.toString()),
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> getCalculate(BuildContext context) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true, error: false);
      final response = await _parcelRepository.getCalculate(
        typeId: state.types[state.selectType]?.id ?? "",
        from: state.locationFrom ?? LocationModel(),
        to: state.locationTo ?? LocationModel(),
      );
      response.when(
        success: (data) {
          state = state.copyWith(isLoading: false, calculate: data);
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false, error: true);
          AppHelpers.showCheckTopSnackBar(context, failure);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> orderParcel({
    required BuildContext context,
    required String note,
    required String usernameTo,
    required String usernameFrom,
    required String phoneTo,
    required String phoneFrom,
    required String houseFrom,
    required String houseTo,
    required String floorTo,
    required String floorFrom,
    required String comment,
    required String value,
    required String instruction,
    required num totalPrice,
    num? codAmount,
  }) async {
    if (state.selectPayment == null) {
      AppHelpers.showCheckTopSnackBar(context, TrKeys.selectPaymentMethod);
      return;
    }
    if (state.codEnabled && (codAmount == null || codAmount <= 0)) {
      AppHelpers.showCheckTopSnackBarInfo(
        context,
        AppHelpers.getTranslation('enter_cash_amount_greater_than_zero'),
      );
      return;
    }
    final num wallet = LocalStorage.getWalletData()?.price ?? 0;
    if (state.selectPayment?.tag == "wallet" && wallet < totalPrice) {
      AppHelpers.showCheckTopSnackBarInfo(
        context,
        AppHelpers.getTranslation(TrKeys.notEnoughMoney),
      );
      return;
    }
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      state = state.copyWith(isLoading: true);
      // base_sdk owns ParcelRepositoryFacade and cannot be extended from this
      // repo, so the optional COD extension lives on the concrete
      // ParcelRepository that OrdersSdkDependencies always registers.
      final response = await (_parcelRepository as ParcelRepository).orderParcel(
        codAmount: state.codEnabled ? codAmount : null,
        typeId: state.types[state.selectType]?.id ?? "",
        from: state.locationFrom ?? LocationModel(),
        to: state.locationTo ?? LocationModel(),
        fromTitle: state.addressFrom ?? "",
        toTitle: state.addressTo ?? "",
        time:
            "${(state.time ?? TimeOfDay.now()).hour} : ${(state.time ?? TimeOfDay.now()).minute}",
        note: note,
        phoneFrom: phoneFrom,
        phoneTo: phoneTo,
        usernameTo: usernameTo,
        usernameFrom: usernameFrom,
        notify: state.anonymous,
        floorTo: floorTo,
        floorFrom: floorFrom,
        houseFrom: houseFrom,
        houseTo: houseTo,
        comment: comment,
        value: value,
        instruction: instruction,
      );
      response.when(
        success: (data) async {
          state = state.copyWith(isLoading: false);
          String id = state.selectPayment?.id ??
              (LocalStorage.getSelectedCurrency()?.id ?? "").toString();
          switch (state.selectPayment?.tag) {
            case 'cash':
            case 'wallet':
              _parcelRepository.createTransaction(
                orderId: data ?? 0,
                paymentId: id,
              );
              AppRoutes.I.replaceParcelListRoute(context);
              break;
            default:
              _parcelRepository.createTransaction(
                orderId: data ?? 0,
                paymentId: id,
              );
              AppRoutes.I.replaceParcelListRoute(context);
              await makePayment(
                context,
                state.selectPayment?.tag ?? 'cash',
                data.toString(),
              );
              break;
          }
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(status.toString()),
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> makePayment(
    BuildContext context,
    String name,
    String? orderId,
  ) async {
    try {
      final response = await _parcelRepository.process(
        (orderId ?? "").toString(),
        name,
      );
      response.when(
        success: (data) async {
          // ignore: deprecated_member_use
          await launch(data, enableJavaScript: true);
        },
        failure: (failure, status) {
          state = state.copyWith(isButtonLoading: false);
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(context, failure);
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        AppHelpers.showCheckTopSnackBar(
          context,
          AppHelpers.getTranslation(TrKeys.paymentMethodFailed),
        );
      }
    }
  }

  void selectType({required int index, required BuildContext context}) {
    state = state.copyWith(selectType: index);
    if (state.types.isNotEmpty &&
        state.addressFrom != null &&
        state.addressTo != null) {
      getCalculate(context);
    }
  }

  void setToAddress({
    required String? title,
    required LocationModel? location,
    required BuildContext context,
  }) {
    state = state.copyWith(addressTo: title, locationTo: location);
    if (state.types.isNotEmpty &&
        state.addressFrom != null &&
        state.addressTo != null) {
      getCalculate(context);
    }
  }

  void setFromAddress({
    required String? title,
    required LocationModel? location,
    required BuildContext context,
  }) {
    state = state.copyWith(addressFrom: title, locationFrom: location);
    if (state.types.isNotEmpty &&
        state.addressFrom != null &&
        state.addressTo != null) {
      getCalculate(context);
    }
  }

  void switchAddress({required BuildContext context}) {
    state = state.copyWith(
      addressFrom: state.addressTo,
      locationFrom: state.locationTo,
      addressTo: state.addressFrom,
      locationTo: state.locationFrom,
    );
    if (state.types.isNotEmpty &&
        state.addressFrom != null &&
        state.addressTo != null) {
      getCalculate(context);
    }
  }

  void setTime({required TimeOfDay time}) {
    state = state.copyWith(time: time);
  }

  Future<void> showParcel(
    BuildContext context,
    String orderId,
    bool isRefresh,
  ) async {
    final connected = await AppConnectivity.connectivity();
    if (connected) {
      if (!isRefresh) {
        state = state.copyWith(isLoading: true);
      }

      final response = await _parcelRepository.getSingleParcel(orderId);
      response.when(
        success: (data) async {
          final ImageCropperForMarker image = ImageCropperForMarker();
          if (!isRefresh) {
            state = state.copyWith(
              parcel: data,
              isLoading: false,
              isMapLoading: true,
            );
            Map<MarkerId, Marker> list = {
              const MarkerId("Shop"): Marker(
                markerId: const MarkerId("Shop"),
                position: LatLng(
                  data.addressFrom?.latitude ?? AppConstants.demoLatitude,
                  data.addressFrom?.longitude ?? AppConstants.demoLongitude,
                ),
                icon: await image.resizeAndCircle(data.user?.img ?? "", 120),
              ),
              const MarkerId("User"): Marker(
                markerId: const MarkerId("User"),
                position: LatLng(
                  data.addressTo?.latitude ?? AppConstants.demoLatitude,
                  data.addressTo?.longitude ?? AppConstants.demoLongitude,
                ),
                icon: await image.resizeAndCircle("", 120),
              ),
            };
            state = state.copyWith(markers: list, isMapLoading: false);
            if (context.mounted) {
              getRoutingAll(
                context: context,
                end: LatLng(
                  data.addressTo?.latitude ?? AppConstants.demoLatitude,
                  data.addressTo?.longitude ?? AppConstants.demoLongitude,
                ),
                start: LatLng(
                  data.addressFrom?.latitude ?? AppConstants.demoLatitude,
                  data.addressFrom?.longitude ?? AppConstants.demoLongitude,
                ),
              );
            }
          } else {
            state = state.copyWith(parcel: data);
            Map<MarkerId, Marker> list = {
              const MarkerId("Shop"): Marker(
                markerId: const MarkerId("Shop"),
                position: LatLng(
                  data.addressFrom?.latitude ?? AppConstants.demoLatitude,
                  data.addressFrom?.longitude ?? AppConstants.demoLongitude,
                ),
                icon: await image.resizeAndCircle(data.user?.img ?? "", 120),
              ),
              const MarkerId("User"): Marker(
                markerId: const MarkerId("User"),
                position: LatLng(
                  data.addressTo?.latitude ?? AppConstants.demoLatitude,
                  data.addressTo?.longitude ?? AppConstants.demoLongitude,
                ),
                icon: await image.resizeAndCircle("", 120),
              ),
            };

            state = state.copyWith(markers: list);
          }
        },
        failure: (failure, status) {
          if (!isRefresh) {
            state = state.copyWith(isLoading: false);
          }
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(context, failure);
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> getRoutingAll({
    required BuildContext context,
    required LatLng start,
    required LatLng end,
  }) async {
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(polylineCoordinates: []);
      final response = await _drawRouting.getRouting(start: start, end: end);
      response.when(
        success: (data) {
          List<LatLng> list = [];
          List ls = data.features[0].geometry.coordinates;
          for (int i = 0; i < ls.length; i++) {
            list.add(LatLng(ls[i][1], ls[i][0]));
          }
          state = state.copyWith(polylineCoordinates: list);
        },
        failure: (failure, status) {
          state = state.copyWith(polylineCoordinates: []);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }
}
