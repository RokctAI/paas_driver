// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeState {

 bool get isLoading; bool get isGoUser; bool get isGoRestaurant; bool get isScrolling; List<LatLng> get polylineCoordinates; List<LatLng> get endPolylineCoordinates; Set<Marker> get markers; OrderDetailData? get orderDetail; ParcelOrder? get parcelDetail; Set<Polygon> get polygon; List<LatLng> get deliveryZone;
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeStateCopyWith<HomeState> get copyWith => _$HomeStateCopyWithImpl<HomeState>(this as HomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isGoUser, isGoUser) || other.isGoUser == isGoUser)&&(identical(other.isGoRestaurant, isGoRestaurant) || other.isGoRestaurant == isGoRestaurant)&&(identical(other.isScrolling, isScrolling) || other.isScrolling == isScrolling)&&const DeepCollectionEquality().equals(other.polylineCoordinates, polylineCoordinates)&&const DeepCollectionEquality().equals(other.endPolylineCoordinates, endPolylineCoordinates)&&const DeepCollectionEquality().equals(other.markers, markers)&&(identical(other.orderDetail, orderDetail) || other.orderDetail == orderDetail)&&(identical(other.parcelDetail, parcelDetail) || other.parcelDetail == parcelDetail)&&const DeepCollectionEquality().equals(other.polygon, polygon)&&const DeepCollectionEquality().equals(other.deliveryZone, deliveryZone));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isGoUser,isGoRestaurant,isScrolling,const DeepCollectionEquality().hash(polylineCoordinates),const DeepCollectionEquality().hash(endPolylineCoordinates),const DeepCollectionEquality().hash(markers),orderDetail,parcelDetail,const DeepCollectionEquality().hash(polygon),const DeepCollectionEquality().hash(deliveryZone));

@override
String toString() {
  return 'HomeState(isLoading: $isLoading, isGoUser: $isGoUser, isGoRestaurant: $isGoRestaurant, isScrolling: $isScrolling, polylineCoordinates: $polylineCoordinates, endPolylineCoordinates: $endPolylineCoordinates, markers: $markers, orderDetail: $orderDetail, parcelDetail: $parcelDetail, polygon: $polygon, deliveryZone: $deliveryZone)';
}


}

/// @nodoc
abstract mixin class $HomeStateCopyWith<$Res>  {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) _then) = _$HomeStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isGoUser, bool isGoRestaurant, bool isScrolling, List<LatLng> polylineCoordinates, List<LatLng> endPolylineCoordinates, Set<Marker> markers, OrderDetailData? orderDetail, ParcelOrder? parcelDetail, Set<Polygon> polygon, List<LatLng> deliveryZone
});




}
/// @nodoc
class _$HomeStateCopyWithImpl<$Res>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._self, this._then);

  final HomeState _self;
  final $Res Function(HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isGoUser = null,Object? isGoRestaurant = null,Object? isScrolling = null,Object? polylineCoordinates = null,Object? endPolylineCoordinates = null,Object? markers = null,Object? orderDetail = freezed,Object? parcelDetail = freezed,Object? polygon = null,Object? deliveryZone = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isGoUser: null == isGoUser ? _self.isGoUser : isGoUser // ignore: cast_nullable_to_non_nullable
as bool,isGoRestaurant: null == isGoRestaurant ? _self.isGoRestaurant : isGoRestaurant // ignore: cast_nullable_to_non_nullable
as bool,isScrolling: null == isScrolling ? _self.isScrolling : isScrolling // ignore: cast_nullable_to_non_nullable
as bool,polylineCoordinates: null == polylineCoordinates ? _self.polylineCoordinates : polylineCoordinates // ignore: cast_nullable_to_non_nullable
as List<LatLng>,endPolylineCoordinates: null == endPolylineCoordinates ? _self.endPolylineCoordinates : endPolylineCoordinates // ignore: cast_nullable_to_non_nullable
as List<LatLng>,markers: null == markers ? _self.markers : markers // ignore: cast_nullable_to_non_nullable
as Set<Marker>,orderDetail: freezed == orderDetail ? _self.orderDetail : orderDetail // ignore: cast_nullable_to_non_nullable
as OrderDetailData?,parcelDetail: freezed == parcelDetail ? _self.parcelDetail : parcelDetail // ignore: cast_nullable_to_non_nullable
as ParcelOrder?,polygon: null == polygon ? _self.polygon : polygon // ignore: cast_nullable_to_non_nullable
as Set<Polygon>,deliveryZone: null == deliveryZone ? _self.deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as List<LatLng>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeState value)  $default,){
final _that = this;
switch (_that) {
case _HomeState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isGoUser,  bool isGoRestaurant,  bool isScrolling,  List<LatLng> polylineCoordinates,  List<LatLng> endPolylineCoordinates,  Set<Marker> markers,  OrderDetailData? orderDetail,  ParcelOrder? parcelDetail,  Set<Polygon> polygon,  List<LatLng> deliveryZone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.isLoading,_that.isGoUser,_that.isGoRestaurant,_that.isScrolling,_that.polylineCoordinates,_that.endPolylineCoordinates,_that.markers,_that.orderDetail,_that.parcelDetail,_that.polygon,_that.deliveryZone);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isGoUser,  bool isGoRestaurant,  bool isScrolling,  List<LatLng> polylineCoordinates,  List<LatLng> endPolylineCoordinates,  Set<Marker> markers,  OrderDetailData? orderDetail,  ParcelOrder? parcelDetail,  Set<Polygon> polygon,  List<LatLng> deliveryZone)  $default,) {final _that = this;
switch (_that) {
case _HomeState():
return $default(_that.isLoading,_that.isGoUser,_that.isGoRestaurant,_that.isScrolling,_that.polylineCoordinates,_that.endPolylineCoordinates,_that.markers,_that.orderDetail,_that.parcelDetail,_that.polygon,_that.deliveryZone);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isGoUser,  bool isGoRestaurant,  bool isScrolling,  List<LatLng> polylineCoordinates,  List<LatLng> endPolylineCoordinates,  Set<Marker> markers,  OrderDetailData? orderDetail,  ParcelOrder? parcelDetail,  Set<Polygon> polygon,  List<LatLng> deliveryZone)?  $default,) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.isLoading,_that.isGoUser,_that.isGoRestaurant,_that.isScrolling,_that.polylineCoordinates,_that.endPolylineCoordinates,_that.markers,_that.orderDetail,_that.parcelDetail,_that.polygon,_that.deliveryZone);case _:
  return null;

}
}

}

/// @nodoc


class _HomeState extends HomeState {
  const _HomeState({this.isLoading = false, this.isGoUser = false, this.isGoRestaurant = false, this.isScrolling = false, final  List<LatLng> polylineCoordinates = const [], final  List<LatLng> endPolylineCoordinates = const [], final  Set<Marker> markers = const {}, this.orderDetail = null, this.parcelDetail = null, final  Set<Polygon> polygon = const {}, final  List<LatLng> deliveryZone = const []}): _polylineCoordinates = polylineCoordinates,_endPolylineCoordinates = endPolylineCoordinates,_markers = markers,_polygon = polygon,_deliveryZone = deliveryZone,super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isGoUser;
@override@JsonKey() final  bool isGoRestaurant;
@override@JsonKey() final  bool isScrolling;
 final  List<LatLng> _polylineCoordinates;
@override@JsonKey() List<LatLng> get polylineCoordinates {
  if (_polylineCoordinates is EqualUnmodifiableListView) return _polylineCoordinates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_polylineCoordinates);
}

 final  List<LatLng> _endPolylineCoordinates;
@override@JsonKey() List<LatLng> get endPolylineCoordinates {
  if (_endPolylineCoordinates is EqualUnmodifiableListView) return _endPolylineCoordinates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_endPolylineCoordinates);
}

 final  Set<Marker> _markers;
@override@JsonKey() Set<Marker> get markers {
  if (_markers is EqualUnmodifiableSetView) return _markers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_markers);
}

@override@JsonKey() final  OrderDetailData? orderDetail;
@override@JsonKey() final  ParcelOrder? parcelDetail;
 final  Set<Polygon> _polygon;
@override@JsonKey() Set<Polygon> get polygon {
  if (_polygon is EqualUnmodifiableSetView) return _polygon;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_polygon);
}

 final  List<LatLng> _deliveryZone;
@override@JsonKey() List<LatLng> get deliveryZone {
  if (_deliveryZone is EqualUnmodifiableListView) return _deliveryZone;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveryZone);
}


/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeStateCopyWith<_HomeState> get copyWith => __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isGoUser, isGoUser) || other.isGoUser == isGoUser)&&(identical(other.isGoRestaurant, isGoRestaurant) || other.isGoRestaurant == isGoRestaurant)&&(identical(other.isScrolling, isScrolling) || other.isScrolling == isScrolling)&&const DeepCollectionEquality().equals(other._polylineCoordinates, _polylineCoordinates)&&const DeepCollectionEquality().equals(other._endPolylineCoordinates, _endPolylineCoordinates)&&const DeepCollectionEquality().equals(other._markers, _markers)&&(identical(other.orderDetail, orderDetail) || other.orderDetail == orderDetail)&&(identical(other.parcelDetail, parcelDetail) || other.parcelDetail == parcelDetail)&&const DeepCollectionEquality().equals(other._polygon, _polygon)&&const DeepCollectionEquality().equals(other._deliveryZone, _deliveryZone));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isGoUser,isGoRestaurant,isScrolling,const DeepCollectionEquality().hash(_polylineCoordinates),const DeepCollectionEquality().hash(_endPolylineCoordinates),const DeepCollectionEquality().hash(_markers),orderDetail,parcelDetail,const DeepCollectionEquality().hash(_polygon),const DeepCollectionEquality().hash(_deliveryZone));

@override
String toString() {
  return 'HomeState(isLoading: $isLoading, isGoUser: $isGoUser, isGoRestaurant: $isGoRestaurant, isScrolling: $isScrolling, polylineCoordinates: $polylineCoordinates, endPolylineCoordinates: $endPolylineCoordinates, markers: $markers, orderDetail: $orderDetail, parcelDetail: $parcelDetail, polygon: $polygon, deliveryZone: $deliveryZone)';
}


}

/// @nodoc
abstract mixin class _$HomeStateCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$HomeStateCopyWith(_HomeState value, $Res Function(_HomeState) _then) = __$HomeStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isGoUser, bool isGoRestaurant, bool isScrolling, List<LatLng> polylineCoordinates, List<LatLng> endPolylineCoordinates, Set<Marker> markers, OrderDetailData? orderDetail, ParcelOrder? parcelDetail, Set<Polygon> polygon, List<LatLng> deliveryZone
});




}
/// @nodoc
class __$HomeStateCopyWithImpl<$Res>
    implements _$HomeStateCopyWith<$Res> {
  __$HomeStateCopyWithImpl(this._self, this._then);

  final _HomeState _self;
  final $Res Function(_HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isGoUser = null,Object? isGoRestaurant = null,Object? isScrolling = null,Object? polylineCoordinates = null,Object? endPolylineCoordinates = null,Object? markers = null,Object? orderDetail = freezed,Object? parcelDetail = freezed,Object? polygon = null,Object? deliveryZone = null,}) {
  return _then(_HomeState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isGoUser: null == isGoUser ? _self.isGoUser : isGoUser // ignore: cast_nullable_to_non_nullable
as bool,isGoRestaurant: null == isGoRestaurant ? _self.isGoRestaurant : isGoRestaurant // ignore: cast_nullable_to_non_nullable
as bool,isScrolling: null == isScrolling ? _self.isScrolling : isScrolling // ignore: cast_nullable_to_non_nullable
as bool,polylineCoordinates: null == polylineCoordinates ? _self._polylineCoordinates : polylineCoordinates // ignore: cast_nullable_to_non_nullable
as List<LatLng>,endPolylineCoordinates: null == endPolylineCoordinates ? _self._endPolylineCoordinates : endPolylineCoordinates // ignore: cast_nullable_to_non_nullable
as List<LatLng>,markers: null == markers ? _self._markers : markers // ignore: cast_nullable_to_non_nullable
as Set<Marker>,orderDetail: freezed == orderDetail ? _self.orderDetail : orderDetail // ignore: cast_nullable_to_non_nullable
as OrderDetailData?,parcelDetail: freezed == parcelDetail ? _self.parcelDetail : parcelDetail // ignore: cast_nullable_to_non_nullable
as ParcelOrder?,polygon: null == polygon ? _self._polygon : polygon // ignore: cast_nullable_to_non_nullable
as Set<Polygon>,deliveryZone: null == deliveryZone ? _self._deliveryZone : deliveryZone // ignore: cast_nullable_to_non_nullable
as List<LatLng>,
  ));
}


}

// dart format on
