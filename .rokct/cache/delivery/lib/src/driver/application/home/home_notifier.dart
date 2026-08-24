// Copyright (c) 2026 RokctAI
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
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:delivery_sdk/src/driver/di/driver_delivery_di.dart';
import 'package:delivery_sdk/src/driver/infrastructure/models/data/order_detail.dart';
import 'package:base_sdk/src/models/data/parcel_order.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'package:delivery_sdk/src/driver/application/home/home_state.dart';
import 'package:base_sdk/src/constants/app_constants.dart';
import 'package:base_sdk/src/services/app_connectivity.dart';
import 'package:base_sdk/src/services/app_helpers.dart';
import 'package:base_sdk/src/services/enums.dart';
import 'package:base_sdk/src/services/local_storage.dart';
import 'package:base_sdk/src/services/marker_image_cropper.dart';
import 'package:base_sdk/src/services/tr_keys.dart';
import 'package:delivery_sdk/src/driver/infrastructure/services/courier_storage.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());
  final ImageCropperForMarker image = ImageCropperForMarker();

  fetchDeliveryZone({bool isFetch = false}) async {
    // The legacy host cached the zone on its own user model
    // (LocalStorage.getUser()?.deliveryZone); base_sdk's ProfileData carries
    // no such field, so the not-fetching path now reuses whatever the state
    // already holds and anything else fetches live from the courier repo.
    if (isFetch || state.deliveryZone.isEmpty) {
      final response = await courierRepository.getDeliveryZone();
      response.when(
        success: (data) {
          setDeliveryZone(data);
        },
        failure: (failure, status) {
          debugPrint('==> get delivery zone failure: $failure');
        },
      );
    }
  }

  setDeliveryZone(List<List<double>>? address) {
    if (address?.isNotEmpty ?? false) {
      final Set<Polygon> polygon = HashSet<Polygon>();
      final List<List<double>> addresses = address ?? [];
      List<LatLng> points = [];
      for (final address in addresses) {
        final latLng = LatLng(address[0], address[1]);
        points.add(latLng);
      }
      polygon.add(
        Polygon(
          polygonId: const PolygonId("zone"),
          points: points,
          fillColor: AppStyle.primary.withOpacity(0.01),
          strokeColor: AppStyle.primary,
          geodesic: false,
          strokeWidth: 8,
        ),
      );
      state = state.copyWith(
          polygon: polygon, isLoading: false, deliveryZone: points);
    }
  }

  void scrolling(bool scroll) {
    state = state.copyWith(isScrolling: scroll);
  }

  Future<void> getRoutingAll({
    required BuildContext context,
    required LatLng start,
    required LatLng end,
    required Marker market,
  }) async {
    if (await AppConnectivity.connectivity()) {
      state =
          state.copyWith(polylineCoordinates: [], markers: {}, isLoading: true);
      final response = await drawRepository.getRouting(start: start, end: end);
      response.when(
        success: (data) {
          List<LatLng> list = [];
          List ls = data.features[0].geometry.coordinates;
          for (int i = 0; i < ls.length; i++) {
            list.add(LatLng(ls[i][1], ls[i][0]));
          }
          state = state.copyWith(
              polylineCoordinates: list, markers: {market}, isLoading: false);
        },
        failure: (failure, status) {
          // if(status==400){
          //   AppHelpers.showCheckTopSnackBar(context, TrKeys.moreDistance);
          // }
          state = state
              .copyWith(polylineCoordinates: [], markers: {}, isLoading: false);
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> getRouting(
      {required BuildContext context,
      required LatLng start,
      required bool isOnline}) async {
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(isLoading: state.isLoading);
      final response = await courierRepository.setCurrentLocation(start);
      response.when(
        success: (data) {},
        failure: (failure, status) {
          if (status != 501) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          }
        },
      );
    }
  }

  Future<void> goMarket(
      {required BuildContext context,
      String? orderId,
      OrderDetailData? order,
      bool setOrder = false,
      required VoidCallback onSuccess}) async {
    state = state.copyWith(isGoUser: false, isLoading: true);
    if (await AppConnectivity.connectivity()) {
      if (setOrder) {
        final response = await orderRepository.setOrder(orderId ?? "0");
        response.when(
          success: (data) {
            state = state.copyWith(
              isLoading: false,
              orderDetail: order,
              isGoRestaurant: true,
            );
            onSuccess();
          },
          failure: (failure, status) {
            state = state.copyWith(isLoading: false);
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          },
        );
      } else {
        state = state.copyWith(
            isLoading: false, orderDetail: order, isGoRestaurant: true);
      }
    } else {
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> goMarketParcel(
      {required BuildContext context,
      String? parcelId,
      ParcelOrder? parcel,
      bool setOrder = false}) async {
    state =
        state.copyWith(isGoRestaurant: true, isGoUser: false, isLoading: true);
    if (await AppConnectivity.connectivity()) {
      if (setOrder) {
        final response = await parcelRepository.setParcel(parcelId ?? "0");
        response.when(
          success: (data) {
            state = state.copyWith(
              isLoading: false,
              parcelDetail: parcel,
            );
          },
          failure: (failure, status) {
            state = state.copyWith(isLoading: false);
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          },
        );
      } else {
        state = state.copyWith(isLoading: false, parcelDetail: parcel);
      }
    } else {
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> fetchCurrentOrder(BuildContext context) async {
    fetchDeliveryZone();
    state = state.copyWith(
      isGoRestaurant: false,
      isGoUser: false,
    );
    if (await AppConnectivity.connectivity()) {
      final response = await orderRepository.fetchCurrentOrder();
      response.when(
        success: (data) async {
          if (data.data?.isNotEmpty ?? false) {
            state = state.copyWith(orderDetail: data.data?.first);
            if (data.data?.first.status == "on_a_way") {
              getRoutingAll(
                // ignore: use_build_context_synchronously
                context: context,
                start: LatLng(
                  LocalStorage.getAddressSelected()?.latitude ??
                      AppConstants.demoLatitude,
                  LocalStorage.getAddressSelected()?.longitude ??
                      AppConstants.demoLongitude,
                ),
                end: LatLng(
                  double.parse(data.data?.first.location?.latitude ?? "0"),
                  double.parse(data.data?.first.location?.longitude ?? "0"),
                ),
                market: Marker(
                  markerId: const MarkerId("User"),
                  position: LatLng(
                    double.parse(data.data?.first.location?.latitude ?? "0"),
                    double.parse(data.data?.first.location?.longitude ?? "0"),
                  ),
                  icon: await image.resizeAndCircle(
                      data.data?.first.user?.img ?? "", 100),
                ),
              );
              state = state.copyWith(
                  isGoRestaurant: false, isGoUser: true, isLoading: false);
            } else {
              state = state.copyWith(
                isGoRestaurant: true,
                isGoUser: false,
              );
              getRoutingAll(
                  // ignore: use_build_context_synchronously
                  context: context,
                  start: LatLng(
                      LocalStorage.getAddressSelected()?.latitude ??
                          AppConstants.demoLatitude,
                      LocalStorage.getAddressSelected()?.longitude ??
                          AppConstants.demoLongitude),
                  end: LatLng(
                    double.parse(
                        data.data?.first.shop?.location?.latitude ?? "0"),
                    double.parse(
                        data.data?.first.shop?.location?.longitude ?? "0"),
                  ),
                  market: Marker(
                      markerId: const MarkerId("Shop"),
                      position: LatLng(
                        double.parse(
                            data.data?.first.shop?.location?.latitude ?? "0"),
                        double.parse(
                            data.data?.first.shop?.location?.longitude ?? "0"),
                      ),
                      icon: await image.resizeAndCircle(
                          data.data?.first.shop?.logoImg ?? "", 120)));
            }
          }
        },
        failure: (failure, status) {
          state = state.copyWith(isLoading: false);
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        },
      );
    } else {
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> goClient(BuildContext context, String? orderId,
      {OrderDetailData? order}) async {
    state = state.copyWith(isGoUser: true, isGoRestaurant: false);
    if (await AppConnectivity.connectivity()) {
      if (order != null) {
        state = state.copyWith(orderDetail: order);
        return;
      }
      if (orderId == null) {
        debugPrint('==> goClient aborted: order id is null');
        return;
      }
      final response =
          await orderRepository.updateOrder(orderId, "on_a_way");
      response.when(
        success: (data) {},
        failure: (failure, status) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        },
      );
      return;
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> goClientParcel(BuildContext context, String? parcelId,
      {ParcelOrder? parcel}) async {
    state = state.copyWith(isGoUser: true, isGoRestaurant: false);
    if (await AppConnectivity.connectivity()) {
      if (parcel != null) {
        state = state.copyWith(parcelDetail: parcel);
        return;
      }
      if (parcelId == null) {
        debugPrint('==> goClientParcel aborted: parcel id is null');
        return;
      }
      final response =
          await parcelRepository.updateParcel(parcelId, "on_a_way");
      response.when(
        success: (data) {},
        failure: (failure, status) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
          );
        },
      );
      return;
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> addReview(
      {required BuildContext context,
      String? comment,
      double? rating,
      String? orderId}) async {
    if (orderId == null) {
      debugPrint('==> addReview aborted: order id is null');
      return;
    }
    if (await AppConnectivity.connectivity()) {
      orderRepository.addReview(orderId,
          rating: rating ?? 0, comment: comment ?? "");
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> addReviewParcel(
      {required BuildContext context,
      String? comment,
      double? rating,
      String? parcelId}) async {
    if (parcelId == null) {
      debugPrint('==> addReviewParcel aborted: parcel id is null');
      return;
    }
    if (await AppConnectivity.connectivity()) {
      parcelRepository.addReviewParcel(parcelId,
          rating: rating ?? 0, comment: comment ?? "");
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> deliveredFinishParcel(
      {required BuildContext context, String? parcelId}) async {
    // Parcel Order docnames are strings; a missing id used to be sent as
    // the literal 0, which the backend silently ignored — abort loudly
    // instead so the delivered update is never a silent no-op.
    if (parcelId == null) {
      debugPrint(
          '==> deliveredFinishParcel aborted: parcel id is null, delivered '
          'update NOT sent');
      return;
    }
    state = state.copyWith(
      isGoUser: false,
      isGoRestaurant: false,
      polylineCoordinates: [],
      endPolylineCoordinates: [],
      markers: {},
    );
    if (await AppConnectivity.connectivity()) {
      final response =
          await parcelRepository.updateParcel(parcelId, "delivered");
      response.when(
        success: (data) {},
        failure: (failure, status) {
          debugPrint('==> parcel delivered status update failure: $failure');
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  /// Reads the driver's `can_convert_cod_to_credit` capability from the raw
  /// deliveryman settings map (Deliveryman Profile). Defaults to false on
  /// any failure so the credit action never shows up by accident.
  Future<bool> fetchCanConvertCodToCredit() async {
    if (!await AppConnectivity.connectivity()) {
      return false;
    }
    final response = await courierRepository.getDeliverymanSettingsRaw();
    return response.when(
      success: (data) {
        final value = data['can_convert_cod_to_credit'];
        return value == true || value == 1 || value == '1';
      },
      failure: (failure, status) => false,
    );
  }

  /// Confirms the cash amount physically received on a COD order. Only
  /// calls [onSuccess] when the backend accepted the confirmation, so a
  /// failed confirm never advances the delivered flow.
  Future<void> confirmCodCollection({
    required BuildContext context,
    String? orderId,
    required num amountReceived,
    VoidCallback? onSuccess,
  }) async {
    if (await AppConnectivity.connectivity()) {
      final response =
          await orderRepository.confirmCodCollection(orderId, amountReceived);
      response.when(
        success: (data) {
          onSuccess?.call();
        },
        failure: (failure, status) {
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  /// Flips an uncollected cash order to Credit (customer owes the shop).
  /// Backend enforces the per-driver capability; [onSuccess] only fires on
  /// acceptance.
  Future<void> convertCodToCredit({
    required BuildContext context,
    String? orderId,
    VoidCallback? onSuccess,
  }) async {
    if (await AppConnectivity.connectivity()) {
      final response = await orderRepository.convertCodToCredit(orderId);
      response.when(
        success: (data) {
          onSuccess?.call();
        },
        failure: (failure, status) {
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  /// Confirms the sender-declared cash collected from a parcel recipient.
  /// The backend settles the amount from the deliveryman's wallet to the
  /// sender's wallet; [onSuccess] only fires on acceptance.
  Future<void> confirmParcelCodCollection({
    required BuildContext context,
    String? parcelId,
    required num amountReceived,
    VoidCallback? onSuccess,
  }) async {
    if (await AppConnectivity.connectivity()) {
      final response = await parcelRepository.confirmParcelCodCollection(
          parcelId, amountReceived);
      response.when(
        success: (data) {
          onSuccess?.call();
        },
        failure: (failure, status) {
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  /// [recipientAgeVerified] threads the courier's ID-check confirmation
  /// for 18+ (contains_adult_items) orders through to the backend; the
  /// server refuses to complete a flagged order without it.
  Future<void> deliveredFinish(
      {required BuildContext context,
      String? orderId,
      bool recipientAgeVerified = false}) async {
    // Order docnames are Frappe hash strings; a missing id used to be sent
    // as the literal 0, which the backend silently ignored — the courier
    // saw the sheet close while the order never left "on_a_way". Abort
    // loudly instead, and surface a failed status update.
    if (orderId == null) {
      debugPrint(
          '==> deliveredFinish aborted: order id is null, delivered update '
          'NOT sent');
      return;
    }
    state = state.copyWith(
      isGoUser: false,
      isGoRestaurant: false,
      polylineCoordinates: [],
      endPolylineCoordinates: [],
      markers: {},
    );
    if (await AppConnectivity.connectivity()) {
      final response = await orderRepository.updateOrder(orderId, "delivered",
          recipientAgeVerified: recipientAgeVerified);
      response.when(
        success: (data) {},
        failure: (failure, status) {
          debugPrint('==> delivered status update failure: $failure');
          if (context.mounted) {
            AppHelpers.showCheckTopSnackBar(
              context,
              AppHelpers.getTranslation(failure),
            );
          }
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> cancelOrder(
      {required BuildContext context,
      required String orderId,
      required String note}) async {
    state = state.copyWith(isLoading: true);
    if (await AppConnectivity.connectivity()) {
      await orderRepository.cancelOrder(orderId, note);
      state = state.copyWith(
        isGoUser: false,
        isGoRestaurant: false,
        polylineCoordinates: [],
        endPolylineCoordinates: [],
        markers: {},
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> uploadImage({
    required BuildContext context,
    required String? orderId,
    required String path,
  }) async {
    final res = await galleryRepository.uploadImage(path, UploadType.products);
    res.when(success: (success) {
      orderRepository.uploadImage(orderId, success.imageData?.title);
    }, failure: (failure, status) {
      AppHelpers.showCheckTopSnackBar(context, failure);
    });
  }

  Future<void> setOnline({
    required BuildContext context,
  }) async {
    if (await AppConnectivity.connectivity()) {
      final response = await courierRepository.setOnline();
      response.when(
        success: (data) {
          CourierStorage.setOnline(!CourierStorage.getOnline());
        },
        failure: (failure, status) {
          AppHelpers.showCheckTopSnackBar(
            context,
            AppHelpers.getTranslation(failure),
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
