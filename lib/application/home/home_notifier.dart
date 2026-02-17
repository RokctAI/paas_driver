import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/domain/di/dependency_manager.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';
import 'package:driver/infrastructure/models/data/parcel_order.dart';
import 'package:driver/presentation/styles/style.dart';
import '../../infrastructure/services/services.dart';
import 'home_state.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());
  final ImageCropperMarker image = ImageCropperMarker();

  Future<void> fetchDeliveryZone({bool isFetch = false}) async {
    if (isFetch) {
      final response = await userRepository.getDeliveryZone();
      response.when(
        success: (data) {
          setDeliveryZone(data.data);
        },
        failure: (failure, status) {
          debugPrint('==> get delivery zone failure: $failure');
        },
      );
    } else {
      setDeliveryZone(LocalStorage.getUser()?.deliveryZone);
    }
  }

  void setDeliveryZone(List<List<double>>? address) {
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
          fillColor: Style.primary.withValues(alpha: 0.01),
          strokeColor: Style.primary,
          geodesic: false,
          strokeWidth: 8,
        ),
      );
      state = state.copyWith(
        polygon: polygon,
        isLoading: false,
        deliveryZone: points,
      );
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
      state = state.copyWith(
        polylineCoordinates: [],
        markers: {},
        isLoading: true,
      );
      final response = await drawRepository.getRouting(start: start, end: end);
      response.when(
        success: (data) {
          List<LatLng> list = [];
          List ls = data.features[0].geometry.coordinates;
          for (int i = 0; i < ls.length; i++) {
            list.add(LatLng(ls[i][1], ls[i][0]));
          }
          state = state.copyWith(
            polylineCoordinates: list,
            markers: {market},
            isLoading: false,
          );
        },
        failure: (failure, status) {
          // if(status==400){
          //   AppHelpers.showCheckTopSnackBar(context, TrKeys.moreDistance);
          // }
          state = state.copyWith(
            polylineCoordinates: [],
            markers: {},
            isLoading: false,
          );
        },
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> getRouting({
    required BuildContext context,
    required LatLng start,
    required bool isOnline,
  }) async {
    if (await AppConnectivity.connectivity()) {
      state = state.copyWith(isLoading: state.isLoading);
      final response = await userRepository.setCurrentLocation(start);
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

  Future<void> goMarket({
    required BuildContext context,
    String? orderId,
    OrderDetailData? order,
    bool setOrder = false,
    required VoidCallback onSuccess,
  }) async {
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
          isLoading: false,
          orderDetail: order,
          isGoRestaurant: true,
        );
      }
    } else {
      state = state.copyWith(isLoading: false);
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> goMarketParcel({
    required BuildContext context,
    String? parcelId,
    ParcelOrder? parcel,
    bool setOrder = false,
  }) async {
    state = state.copyWith(
      isGoRestaurant: true,
      isGoUser: false,
      isLoading: true,
    );
    if (await AppConnectivity.connectivity()) {
      if (setOrder) {
        final response = await parcelRepository.setParcel(parcelId ?? "0");
        response.when(
          success: (data) {
            state = state.copyWith(isLoading: false, parcelDetail: parcel);
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
    state = state.copyWith(isGoRestaurant: false, isGoUser: false);
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
                    data.data?.first.user?.img ?? "",
                    100,
                  ),
                ),
              );
              state = state.copyWith(
                isGoRestaurant: false,
                isGoUser: true,
                isLoading: false,
              );
            } else {
              state = state.copyWith(isGoRestaurant: true, isGoUser: false);
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
                  double.parse(
                    data.data?.first.shop?.location?.latitude ?? "0",
                  ),
                  double.parse(
                    data.data?.first.shop?.location?.longitude ?? "0",
                  ),
                ),
                market: Marker(
                  markerId: const MarkerId("Shop"),
                  position: LatLng(
                    double.parse(
                      data.data?.first.shop?.location?.latitude ?? "0",
                    ),
                    double.parse(
                      data.data?.first.shop?.location?.longitude ?? "0",
                    ),
                  ),
                  icon: await image.resizeAndCircle(
                    data.data?.first.shop?.logoImg ?? "",
                    120,
                  ),
                ),
              );
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

  Future<void> goClient(
    BuildContext context,
    int? orderId, {
    OrderDetailData? order,
  }) async {
    state = state.copyWith(isGoUser: true, isGoRestaurant: false);
    if (await AppConnectivity.connectivity()) {
      if (order != null) {
        state = state.copyWith(orderDetail: order);
        return;
      }
      final response = await orderRepository.updateOrder(
        orderId ?? 0,
        "on_a_way",
      );
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

  Future<void> goClientParcel(
    BuildContext context,
    int? parcelId, {
    ParcelOrder? parcel,
  }) async {
    state = state.copyWith(isGoUser: true, isGoRestaurant: false);
    if (await AppConnectivity.connectivity()) {
      if (parcel != null) {
        state = state.copyWith(parcelDetail: parcel);
        return;
      }
      final response = await parcelRepository.updateParcel(
        parcelId ?? 0,
        "on_a_way",
      );
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

  Future<void> addReview({
    required BuildContext context,
    String? comment,
    double? rating,
    int? orderId,
  }) async {
    if (await AppConnectivity.connectivity()) {
      orderRepository.addReview(
        orderId ?? 0,
        rating: rating ?? 0,
        comment: comment ?? "",
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> addReviewParcel({
    required BuildContext context,
    String? comment,
    double? rating,
    int? parcelId,
  }) async {
    if (await AppConnectivity.connectivity()) {
      parcelRepository.addReviewParcel(
        parcelId ?? 0,
        rating: rating ?? 0,
        comment: comment ?? "",
      );
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> deliveredFinishParcel({
    required BuildContext context,
    int? parcelId,
  }) async {
    state = state.copyWith(
      isGoUser: false,
      isGoRestaurant: false,
      polylineCoordinates: [],
      endPolylineCoordinates: [],
      markers: {},
    );
    if (await AppConnectivity.connectivity()) {
      parcelRepository.updateParcel(parcelId ?? 0, "delivered");
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> deliveredFinish({
    required BuildContext context,
    int? orderId,
  }) async {
    state = state.copyWith(
      isGoUser: false,
      isGoRestaurant: false,
      polylineCoordinates: [],
      endPolylineCoordinates: [],
      markers: {},
    );
    if (await AppConnectivity.connectivity()) {
      orderRepository.updateOrder(orderId ?? 0, "delivered");
    } else {
      if (context.mounted) {
        AppHelpers.showNoConnectionSnackBar(context);
      }
    }
  }

  Future<void> cancelOrder({
    required BuildContext context,
    required int orderId,
    required String note,
  }) async {
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
    required int? orderId,
    required String path,
  }) async {
    final res = await settingsRepository.uploadImage(path, UploadType.products);
    res.when(
      success: (success) {
        orderRepository.uploadImage(orderId, success.imageData?.title);
      },
      failure: (failure, status) {
        AppHelpers.showCheckTopSnackBar(context, failure);
      },
    );
  }

  Future<void> setOnline({required BuildContext context}) async {
    if (await AppConnectivity.connectivity()) {
      final response = await userRepository.setOnline();
      response.when(
        success: (data) {
          LocalStorage.setOnline(!LocalStorage.getOnline());
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
