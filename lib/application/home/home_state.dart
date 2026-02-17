import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:driver/infrastructure/models/data/order_detail.dart';
import 'package:driver/infrastructure/models/data/parcel_order.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(false) bool isLoading,
    @Default(false) bool isGoUser,
    @Default(false) bool isGoRestaurant,
    @Default(false) bool isScrolling,
    @Default([]) List<LatLng> polylineCoordinates,
    @Default([]) List<LatLng> endPolylineCoordinates,
    @Default({}) Set<Marker> markers,
    @Default(null) OrderDetailData? orderDetail,
    @Default(null) ParcelOrder? parcelDetail,
    @Default({}) Set<Polygon> polygon,
    @Default([]) List<LatLng> deliveryZone,
  }) = _HomeState;

  const HomeState._();
}
