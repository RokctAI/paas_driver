// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderState {

 bool get isActive; bool get isOrder; bool get isLoading; bool get isMapLoading; bool get isButtonLoading; bool get isTodayWorkingDay; bool get isTomorrowWorkingDay; bool get isCheckShopOrder; bool get isAddLoading; bool get sendOtherUser; String? get promoCode; String? get office; String? get house; String? get floor; String? get note; String? get username; String? get phoneNumber; TimeOfDay get selectTime; DateTime? get selectDate; DeliveryPointData? get selectedDeliveryPoint; int get tabIndex; int get branchIndex; OrderActiveModel? get orderData; ShopData? get shopData; List<BranchModel>? get branches; GetCalculateModel? get calculateData; Map<MarkerId, Marker> get markers; Set<Marker> get shopMarkers; List<LatLng> get polylineCoordinates; List<ProductNote> get notes; List<String> get todayTimes; List<List<String>> get dailyTimes;
/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStateCopyWith<OrderState> get copyWith => _$OrderStateCopyWithImpl<OrderState>(this as OrderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isOrder, isOrder) || other.isOrder == isOrder)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isMapLoading, isMapLoading) || other.isMapLoading == isMapLoading)&&(identical(other.isButtonLoading, isButtonLoading) || other.isButtonLoading == isButtonLoading)&&(identical(other.isTodayWorkingDay, isTodayWorkingDay) || other.isTodayWorkingDay == isTodayWorkingDay)&&(identical(other.isTomorrowWorkingDay, isTomorrowWorkingDay) || other.isTomorrowWorkingDay == isTomorrowWorkingDay)&&(identical(other.isCheckShopOrder, isCheckShopOrder) || other.isCheckShopOrder == isCheckShopOrder)&&(identical(other.isAddLoading, isAddLoading) || other.isAddLoading == isAddLoading)&&(identical(other.sendOtherUser, sendOtherUser) || other.sendOtherUser == sendOtherUser)&&(identical(other.promoCode, promoCode) || other.promoCode == promoCode)&&(identical(other.office, office) || other.office == office)&&(identical(other.house, house) || other.house == house)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.note, note) || other.note == note)&&(identical(other.username, username) || other.username == username)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.selectTime, selectTime) || other.selectTime == selectTime)&&(identical(other.selectDate, selectDate) || other.selectDate == selectDate)&&(identical(other.selectedDeliveryPoint, selectedDeliveryPoint) || other.selectedDeliveryPoint == selectedDeliveryPoint)&&(identical(other.tabIndex, tabIndex) || other.tabIndex == tabIndex)&&(identical(other.branchIndex, branchIndex) || other.branchIndex == branchIndex)&&(identical(other.orderData, orderData) || other.orderData == orderData)&&(identical(other.shopData, shopData) || other.shopData == shopData)&&const DeepCollectionEquality().equals(other.branches, branches)&&(identical(other.calculateData, calculateData) || other.calculateData == calculateData)&&const DeepCollectionEquality().equals(other.markers, markers)&&const DeepCollectionEquality().equals(other.shopMarkers, shopMarkers)&&const DeepCollectionEquality().equals(other.polylineCoordinates, polylineCoordinates)&&const DeepCollectionEquality().equals(other.notes, notes)&&const DeepCollectionEquality().equals(other.todayTimes, todayTimes)&&const DeepCollectionEquality().equals(other.dailyTimes, dailyTimes));
}


@override
int get hashCode => Object.hashAll([runtimeType,isActive,isOrder,isLoading,isMapLoading,isButtonLoading,isTodayWorkingDay,isTomorrowWorkingDay,isCheckShopOrder,isAddLoading,sendOtherUser,promoCode,office,house,floor,note,username,phoneNumber,selectTime,selectDate,selectedDeliveryPoint,tabIndex,branchIndex,orderData,shopData,const DeepCollectionEquality().hash(branches),calculateData,const DeepCollectionEquality().hash(markers),const DeepCollectionEquality().hash(shopMarkers),const DeepCollectionEquality().hash(polylineCoordinates),const DeepCollectionEquality().hash(notes),const DeepCollectionEquality().hash(todayTimes),const DeepCollectionEquality().hash(dailyTimes)]);

@override
String toString() {
  return 'OrderState(isActive: $isActive, isOrder: $isOrder, isLoading: $isLoading, isMapLoading: $isMapLoading, isButtonLoading: $isButtonLoading, isTodayWorkingDay: $isTodayWorkingDay, isTomorrowWorkingDay: $isTomorrowWorkingDay, isCheckShopOrder: $isCheckShopOrder, isAddLoading: $isAddLoading, sendOtherUser: $sendOtherUser, promoCode: $promoCode, office: $office, house: $house, floor: $floor, note: $note, username: $username, phoneNumber: $phoneNumber, selectTime: $selectTime, selectDate: $selectDate, selectedDeliveryPoint: $selectedDeliveryPoint, tabIndex: $tabIndex, branchIndex: $branchIndex, orderData: $orderData, shopData: $shopData, branches: $branches, calculateData: $calculateData, markers: $markers, shopMarkers: $shopMarkers, polylineCoordinates: $polylineCoordinates, notes: $notes, todayTimes: $todayTimes, dailyTimes: $dailyTimes)';
}


}

/// @nodoc
abstract mixin class $OrderStateCopyWith<$Res>  {
  factory $OrderStateCopyWith(OrderState value, $Res Function(OrderState) _then) = _$OrderStateCopyWithImpl;
@useResult
$Res call({
 bool isActive, bool isOrder, bool isLoading, bool isMapLoading, bool isButtonLoading, bool isTodayWorkingDay, bool isTomorrowWorkingDay, bool isCheckShopOrder, bool isAddLoading, bool sendOtherUser, String? promoCode, String? office, String? house, String? floor, String? note, String? username, String? phoneNumber, TimeOfDay selectTime, DateTime? selectDate, DeliveryPointData? selectedDeliveryPoint, int tabIndex, int branchIndex, OrderActiveModel? orderData, ShopData? shopData, List<BranchModel>? branches, GetCalculateModel? calculateData, Map<MarkerId, Marker> markers, Set<Marker> shopMarkers, List<LatLng> polylineCoordinates, List<ProductNote> notes, List<String> todayTimes, List<List<String>> dailyTimes
});




}
/// @nodoc
class _$OrderStateCopyWithImpl<$Res>
    implements $OrderStateCopyWith<$Res> {
  _$OrderStateCopyWithImpl(this._self, this._then);

  final OrderState _self;
  final $Res Function(OrderState) _then;

/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isActive = null,Object? isOrder = null,Object? isLoading = null,Object? isMapLoading = null,Object? isButtonLoading = null,Object? isTodayWorkingDay = null,Object? isTomorrowWorkingDay = null,Object? isCheckShopOrder = null,Object? isAddLoading = null,Object? sendOtherUser = null,Object? promoCode = freezed,Object? office = freezed,Object? house = freezed,Object? floor = freezed,Object? note = freezed,Object? username = freezed,Object? phoneNumber = freezed,Object? selectTime = null,Object? selectDate = freezed,Object? selectedDeliveryPoint = freezed,Object? tabIndex = null,Object? branchIndex = null,Object? orderData = freezed,Object? shopData = freezed,Object? branches = freezed,Object? calculateData = freezed,Object? markers = null,Object? shopMarkers = null,Object? polylineCoordinates = null,Object? notes = null,Object? todayTimes = null,Object? dailyTimes = null,}) {
  return _then(_self.copyWith(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isOrder: null == isOrder ? _self.isOrder : isOrder // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isMapLoading: null == isMapLoading ? _self.isMapLoading : isMapLoading // ignore: cast_nullable_to_non_nullable
as bool,isButtonLoading: null == isButtonLoading ? _self.isButtonLoading : isButtonLoading // ignore: cast_nullable_to_non_nullable
as bool,isTodayWorkingDay: null == isTodayWorkingDay ? _self.isTodayWorkingDay : isTodayWorkingDay // ignore: cast_nullable_to_non_nullable
as bool,isTomorrowWorkingDay: null == isTomorrowWorkingDay ? _self.isTomorrowWorkingDay : isTomorrowWorkingDay // ignore: cast_nullable_to_non_nullable
as bool,isCheckShopOrder: null == isCheckShopOrder ? _self.isCheckShopOrder : isCheckShopOrder // ignore: cast_nullable_to_non_nullable
as bool,isAddLoading: null == isAddLoading ? _self.isAddLoading : isAddLoading // ignore: cast_nullable_to_non_nullable
as bool,sendOtherUser: null == sendOtherUser ? _self.sendOtherUser : sendOtherUser // ignore: cast_nullable_to_non_nullable
as bool,promoCode: freezed == promoCode ? _self.promoCode : promoCode // ignore: cast_nullable_to_non_nullable
as String?,office: freezed == office ? _self.office : office // ignore: cast_nullable_to_non_nullable
as String?,house: freezed == house ? _self.house : house // ignore: cast_nullable_to_non_nullable
as String?,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,selectTime: null == selectTime ? _self.selectTime : selectTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,selectDate: freezed == selectDate ? _self.selectDate : selectDate // ignore: cast_nullable_to_non_nullable
as DateTime?,selectedDeliveryPoint: freezed == selectedDeliveryPoint ? _self.selectedDeliveryPoint : selectedDeliveryPoint // ignore: cast_nullable_to_non_nullable
as DeliveryPointData?,tabIndex: null == tabIndex ? _self.tabIndex : tabIndex // ignore: cast_nullable_to_non_nullable
as int,branchIndex: null == branchIndex ? _self.branchIndex : branchIndex // ignore: cast_nullable_to_non_nullable
as int,orderData: freezed == orderData ? _self.orderData : orderData // ignore: cast_nullable_to_non_nullable
as OrderActiveModel?,shopData: freezed == shopData ? _self.shopData : shopData // ignore: cast_nullable_to_non_nullable
as ShopData?,branches: freezed == branches ? _self.branches : branches // ignore: cast_nullable_to_non_nullable
as List<BranchModel>?,calculateData: freezed == calculateData ? _self.calculateData : calculateData // ignore: cast_nullable_to_non_nullable
as GetCalculateModel?,markers: null == markers ? _self.markers : markers // ignore: cast_nullable_to_non_nullable
as Map<MarkerId, Marker>,shopMarkers: null == shopMarkers ? _self.shopMarkers : shopMarkers // ignore: cast_nullable_to_non_nullable
as Set<Marker>,polylineCoordinates: null == polylineCoordinates ? _self.polylineCoordinates : polylineCoordinates // ignore: cast_nullable_to_non_nullable
as List<LatLng>,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as List<ProductNote>,todayTimes: null == todayTimes ? _self.todayTimes : todayTimes // ignore: cast_nullable_to_non_nullable
as List<String>,dailyTimes: null == dailyTimes ? _self.dailyTimes : dailyTimes // ignore: cast_nullable_to_non_nullable
as List<List<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderState].
extension OrderStatePatterns on OrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderState value)  $default,){
final _that = this;
switch (_that) {
case _OrderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderState value)?  $default,){
final _that = this;
switch (_that) {
case _OrderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActive,  bool isOrder,  bool isLoading,  bool isMapLoading,  bool isButtonLoading,  bool isTodayWorkingDay,  bool isTomorrowWorkingDay,  bool isCheckShopOrder,  bool isAddLoading,  bool sendOtherUser,  String? promoCode,  String? office,  String? house,  String? floor,  String? note,  String? username,  String? phoneNumber,  TimeOfDay selectTime,  DateTime? selectDate,  DeliveryPointData? selectedDeliveryPoint,  int tabIndex,  int branchIndex,  OrderActiveModel? orderData,  ShopData? shopData,  List<BranchModel>? branches,  GetCalculateModel? calculateData,  Map<MarkerId, Marker> markers,  Set<Marker> shopMarkers,  List<LatLng> polylineCoordinates,  List<ProductNote> notes,  List<String> todayTimes,  List<List<String>> dailyTimes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderState() when $default != null:
return $default(_that.isActive,_that.isOrder,_that.isLoading,_that.isMapLoading,_that.isButtonLoading,_that.isTodayWorkingDay,_that.isTomorrowWorkingDay,_that.isCheckShopOrder,_that.isAddLoading,_that.sendOtherUser,_that.promoCode,_that.office,_that.house,_that.floor,_that.note,_that.username,_that.phoneNumber,_that.selectTime,_that.selectDate,_that.selectedDeliveryPoint,_that.tabIndex,_that.branchIndex,_that.orderData,_that.shopData,_that.branches,_that.calculateData,_that.markers,_that.shopMarkers,_that.polylineCoordinates,_that.notes,_that.todayTimes,_that.dailyTimes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActive,  bool isOrder,  bool isLoading,  bool isMapLoading,  bool isButtonLoading,  bool isTodayWorkingDay,  bool isTomorrowWorkingDay,  bool isCheckShopOrder,  bool isAddLoading,  bool sendOtherUser,  String? promoCode,  String? office,  String? house,  String? floor,  String? note,  String? username,  String? phoneNumber,  TimeOfDay selectTime,  DateTime? selectDate,  DeliveryPointData? selectedDeliveryPoint,  int tabIndex,  int branchIndex,  OrderActiveModel? orderData,  ShopData? shopData,  List<BranchModel>? branches,  GetCalculateModel? calculateData,  Map<MarkerId, Marker> markers,  Set<Marker> shopMarkers,  List<LatLng> polylineCoordinates,  List<ProductNote> notes,  List<String> todayTimes,  List<List<String>> dailyTimes)  $default,) {final _that = this;
switch (_that) {
case _OrderState():
return $default(_that.isActive,_that.isOrder,_that.isLoading,_that.isMapLoading,_that.isButtonLoading,_that.isTodayWorkingDay,_that.isTomorrowWorkingDay,_that.isCheckShopOrder,_that.isAddLoading,_that.sendOtherUser,_that.promoCode,_that.office,_that.house,_that.floor,_that.note,_that.username,_that.phoneNumber,_that.selectTime,_that.selectDate,_that.selectedDeliveryPoint,_that.tabIndex,_that.branchIndex,_that.orderData,_that.shopData,_that.branches,_that.calculateData,_that.markers,_that.shopMarkers,_that.polylineCoordinates,_that.notes,_that.todayTimes,_that.dailyTimes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActive,  bool isOrder,  bool isLoading,  bool isMapLoading,  bool isButtonLoading,  bool isTodayWorkingDay,  bool isTomorrowWorkingDay,  bool isCheckShopOrder,  bool isAddLoading,  bool sendOtherUser,  String? promoCode,  String? office,  String? house,  String? floor,  String? note,  String? username,  String? phoneNumber,  TimeOfDay selectTime,  DateTime? selectDate,  DeliveryPointData? selectedDeliveryPoint,  int tabIndex,  int branchIndex,  OrderActiveModel? orderData,  ShopData? shopData,  List<BranchModel>? branches,  GetCalculateModel? calculateData,  Map<MarkerId, Marker> markers,  Set<Marker> shopMarkers,  List<LatLng> polylineCoordinates,  List<ProductNote> notes,  List<String> todayTimes,  List<List<String>> dailyTimes)?  $default,) {final _that = this;
switch (_that) {
case _OrderState() when $default != null:
return $default(_that.isActive,_that.isOrder,_that.isLoading,_that.isMapLoading,_that.isButtonLoading,_that.isTodayWorkingDay,_that.isTomorrowWorkingDay,_that.isCheckShopOrder,_that.isAddLoading,_that.sendOtherUser,_that.promoCode,_that.office,_that.house,_that.floor,_that.note,_that.username,_that.phoneNumber,_that.selectTime,_that.selectDate,_that.selectedDeliveryPoint,_that.tabIndex,_that.branchIndex,_that.orderData,_that.shopData,_that.branches,_that.calculateData,_that.markers,_that.shopMarkers,_that.polylineCoordinates,_that.notes,_that.todayTimes,_that.dailyTimes);case _:
  return null;

}
}

}

/// @nodoc


class _OrderState extends OrderState {
  const _OrderState({this.isActive = false, this.isOrder = false, this.isLoading = false, this.isMapLoading = false, this.isButtonLoading = false, this.isTodayWorkingDay = false, this.isTomorrowWorkingDay = false, this.isCheckShopOrder = false, this.isAddLoading = false, this.sendOtherUser = false, this.promoCode = null, this.office = null, this.house = null, this.floor = null, this.note = null, this.username = null, this.phoneNumber = null, this.selectTime = const TimeOfDay(hour: 0, minute: 0), this.selectDate = null, this.selectedDeliveryPoint = null, this.tabIndex = 0, this.branchIndex = -1, this.orderData = null, this.shopData = null, final  List<BranchModel>? branches = const [], this.calculateData = null, final  Map<MarkerId, Marker> markers = const {}, final  Set<Marker> shopMarkers = const {}, final  List<LatLng> polylineCoordinates = const [], final  List<ProductNote> notes = const [], final  List<String> todayTimes = const [], final  List<List<String>> dailyTimes = const []}): _branches = branches,_markers = markers,_shopMarkers = shopMarkers,_polylineCoordinates = polylineCoordinates,_notes = notes,_todayTimes = todayTimes,_dailyTimes = dailyTimes,super._();
  

@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool isOrder;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isMapLoading;
@override@JsonKey() final  bool isButtonLoading;
@override@JsonKey() final  bool isTodayWorkingDay;
@override@JsonKey() final  bool isTomorrowWorkingDay;
@override@JsonKey() final  bool isCheckShopOrder;
@override@JsonKey() final  bool isAddLoading;
@override@JsonKey() final  bool sendOtherUser;
@override@JsonKey() final  String? promoCode;
@override@JsonKey() final  String? office;
@override@JsonKey() final  String? house;
@override@JsonKey() final  String? floor;
@override@JsonKey() final  String? note;
@override@JsonKey() final  String? username;
@override@JsonKey() final  String? phoneNumber;
@override@JsonKey() final  TimeOfDay selectTime;
@override@JsonKey() final  DateTime? selectDate;
@override@JsonKey() final  DeliveryPointData? selectedDeliveryPoint;
@override@JsonKey() final  int tabIndex;
@override@JsonKey() final  int branchIndex;
@override@JsonKey() final  OrderActiveModel? orderData;
@override@JsonKey() final  ShopData? shopData;
 final  List<BranchModel>? _branches;
@override@JsonKey() List<BranchModel>? get branches {
  final value = _branches;
  if (value == null) return null;
  if (_branches is EqualUnmodifiableListView) return _branches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey() final  GetCalculateModel? calculateData;
 final  Map<MarkerId, Marker> _markers;
@override@JsonKey() Map<MarkerId, Marker> get markers {
  if (_markers is EqualUnmodifiableMapView) return _markers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_markers);
}

 final  Set<Marker> _shopMarkers;
@override@JsonKey() Set<Marker> get shopMarkers {
  if (_shopMarkers is EqualUnmodifiableSetView) return _shopMarkers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_shopMarkers);
}

 final  List<LatLng> _polylineCoordinates;
@override@JsonKey() List<LatLng> get polylineCoordinates {
  if (_polylineCoordinates is EqualUnmodifiableListView) return _polylineCoordinates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_polylineCoordinates);
}

 final  List<ProductNote> _notes;
@override@JsonKey() List<ProductNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}

 final  List<String> _todayTimes;
@override@JsonKey() List<String> get todayTimes {
  if (_todayTimes is EqualUnmodifiableListView) return _todayTimes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_todayTimes);
}

 final  List<List<String>> _dailyTimes;
@override@JsonKey() List<List<String>> get dailyTimes {
  if (_dailyTimes is EqualUnmodifiableListView) return _dailyTimes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyTimes);
}


/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderStateCopyWith<_OrderState> get copyWith => __$OrderStateCopyWithImpl<_OrderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isOrder, isOrder) || other.isOrder == isOrder)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isMapLoading, isMapLoading) || other.isMapLoading == isMapLoading)&&(identical(other.isButtonLoading, isButtonLoading) || other.isButtonLoading == isButtonLoading)&&(identical(other.isTodayWorkingDay, isTodayWorkingDay) || other.isTodayWorkingDay == isTodayWorkingDay)&&(identical(other.isTomorrowWorkingDay, isTomorrowWorkingDay) || other.isTomorrowWorkingDay == isTomorrowWorkingDay)&&(identical(other.isCheckShopOrder, isCheckShopOrder) || other.isCheckShopOrder == isCheckShopOrder)&&(identical(other.isAddLoading, isAddLoading) || other.isAddLoading == isAddLoading)&&(identical(other.sendOtherUser, sendOtherUser) || other.sendOtherUser == sendOtherUser)&&(identical(other.promoCode, promoCode) || other.promoCode == promoCode)&&(identical(other.office, office) || other.office == office)&&(identical(other.house, house) || other.house == house)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.note, note) || other.note == note)&&(identical(other.username, username) || other.username == username)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.selectTime, selectTime) || other.selectTime == selectTime)&&(identical(other.selectDate, selectDate) || other.selectDate == selectDate)&&(identical(other.selectedDeliveryPoint, selectedDeliveryPoint) || other.selectedDeliveryPoint == selectedDeliveryPoint)&&(identical(other.tabIndex, tabIndex) || other.tabIndex == tabIndex)&&(identical(other.branchIndex, branchIndex) || other.branchIndex == branchIndex)&&(identical(other.orderData, orderData) || other.orderData == orderData)&&(identical(other.shopData, shopData) || other.shopData == shopData)&&const DeepCollectionEquality().equals(other._branches, _branches)&&(identical(other.calculateData, calculateData) || other.calculateData == calculateData)&&const DeepCollectionEquality().equals(other._markers, _markers)&&const DeepCollectionEquality().equals(other._shopMarkers, _shopMarkers)&&const DeepCollectionEquality().equals(other._polylineCoordinates, _polylineCoordinates)&&const DeepCollectionEquality().equals(other._notes, _notes)&&const DeepCollectionEquality().equals(other._todayTimes, _todayTimes)&&const DeepCollectionEquality().equals(other._dailyTimes, _dailyTimes));
}


@override
int get hashCode => Object.hashAll([runtimeType,isActive,isOrder,isLoading,isMapLoading,isButtonLoading,isTodayWorkingDay,isTomorrowWorkingDay,isCheckShopOrder,isAddLoading,sendOtherUser,promoCode,office,house,floor,note,username,phoneNumber,selectTime,selectDate,selectedDeliveryPoint,tabIndex,branchIndex,orderData,shopData,const DeepCollectionEquality().hash(_branches),calculateData,const DeepCollectionEquality().hash(_markers),const DeepCollectionEquality().hash(_shopMarkers),const DeepCollectionEquality().hash(_polylineCoordinates),const DeepCollectionEquality().hash(_notes),const DeepCollectionEquality().hash(_todayTimes),const DeepCollectionEquality().hash(_dailyTimes)]);

@override
String toString() {
  return 'OrderState(isActive: $isActive, isOrder: $isOrder, isLoading: $isLoading, isMapLoading: $isMapLoading, isButtonLoading: $isButtonLoading, isTodayWorkingDay: $isTodayWorkingDay, isTomorrowWorkingDay: $isTomorrowWorkingDay, isCheckShopOrder: $isCheckShopOrder, isAddLoading: $isAddLoading, sendOtherUser: $sendOtherUser, promoCode: $promoCode, office: $office, house: $house, floor: $floor, note: $note, username: $username, phoneNumber: $phoneNumber, selectTime: $selectTime, selectDate: $selectDate, selectedDeliveryPoint: $selectedDeliveryPoint, tabIndex: $tabIndex, branchIndex: $branchIndex, orderData: $orderData, shopData: $shopData, branches: $branches, calculateData: $calculateData, markers: $markers, shopMarkers: $shopMarkers, polylineCoordinates: $polylineCoordinates, notes: $notes, todayTimes: $todayTimes, dailyTimes: $dailyTimes)';
}


}

/// @nodoc
abstract mixin class _$OrderStateCopyWith<$Res> implements $OrderStateCopyWith<$Res> {
  factory _$OrderStateCopyWith(_OrderState value, $Res Function(_OrderState) _then) = __$OrderStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActive, bool isOrder, bool isLoading, bool isMapLoading, bool isButtonLoading, bool isTodayWorkingDay, bool isTomorrowWorkingDay, bool isCheckShopOrder, bool isAddLoading, bool sendOtherUser, String? promoCode, String? office, String? house, String? floor, String? note, String? username, String? phoneNumber, TimeOfDay selectTime, DateTime? selectDate, DeliveryPointData? selectedDeliveryPoint, int tabIndex, int branchIndex, OrderActiveModel? orderData, ShopData? shopData, List<BranchModel>? branches, GetCalculateModel? calculateData, Map<MarkerId, Marker> markers, Set<Marker> shopMarkers, List<LatLng> polylineCoordinates, List<ProductNote> notes, List<String> todayTimes, List<List<String>> dailyTimes
});




}
/// @nodoc
class __$OrderStateCopyWithImpl<$Res>
    implements _$OrderStateCopyWith<$Res> {
  __$OrderStateCopyWithImpl(this._self, this._then);

  final _OrderState _self;
  final $Res Function(_OrderState) _then;

/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isActive = null,Object? isOrder = null,Object? isLoading = null,Object? isMapLoading = null,Object? isButtonLoading = null,Object? isTodayWorkingDay = null,Object? isTomorrowWorkingDay = null,Object? isCheckShopOrder = null,Object? isAddLoading = null,Object? sendOtherUser = null,Object? promoCode = freezed,Object? office = freezed,Object? house = freezed,Object? floor = freezed,Object? note = freezed,Object? username = freezed,Object? phoneNumber = freezed,Object? selectTime = null,Object? selectDate = freezed,Object? selectedDeliveryPoint = freezed,Object? tabIndex = null,Object? branchIndex = null,Object? orderData = freezed,Object? shopData = freezed,Object? branches = freezed,Object? calculateData = freezed,Object? markers = null,Object? shopMarkers = null,Object? polylineCoordinates = null,Object? notes = null,Object? todayTimes = null,Object? dailyTimes = null,}) {
  return _then(_OrderState(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isOrder: null == isOrder ? _self.isOrder : isOrder // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isMapLoading: null == isMapLoading ? _self.isMapLoading : isMapLoading // ignore: cast_nullable_to_non_nullable
as bool,isButtonLoading: null == isButtonLoading ? _self.isButtonLoading : isButtonLoading // ignore: cast_nullable_to_non_nullable
as bool,isTodayWorkingDay: null == isTodayWorkingDay ? _self.isTodayWorkingDay : isTodayWorkingDay // ignore: cast_nullable_to_non_nullable
as bool,isTomorrowWorkingDay: null == isTomorrowWorkingDay ? _self.isTomorrowWorkingDay : isTomorrowWorkingDay // ignore: cast_nullable_to_non_nullable
as bool,isCheckShopOrder: null == isCheckShopOrder ? _self.isCheckShopOrder : isCheckShopOrder // ignore: cast_nullable_to_non_nullable
as bool,isAddLoading: null == isAddLoading ? _self.isAddLoading : isAddLoading // ignore: cast_nullable_to_non_nullable
as bool,sendOtherUser: null == sendOtherUser ? _self.sendOtherUser : sendOtherUser // ignore: cast_nullable_to_non_nullable
as bool,promoCode: freezed == promoCode ? _self.promoCode : promoCode // ignore: cast_nullable_to_non_nullable
as String?,office: freezed == office ? _self.office : office // ignore: cast_nullable_to_non_nullable
as String?,house: freezed == house ? _self.house : house // ignore: cast_nullable_to_non_nullable
as String?,floor: freezed == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,selectTime: null == selectTime ? _self.selectTime : selectTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,selectDate: freezed == selectDate ? _self.selectDate : selectDate // ignore: cast_nullable_to_non_nullable
as DateTime?,selectedDeliveryPoint: freezed == selectedDeliveryPoint ? _self.selectedDeliveryPoint : selectedDeliveryPoint // ignore: cast_nullable_to_non_nullable
as DeliveryPointData?,tabIndex: null == tabIndex ? _self.tabIndex : tabIndex // ignore: cast_nullable_to_non_nullable
as int,branchIndex: null == branchIndex ? _self.branchIndex : branchIndex // ignore: cast_nullable_to_non_nullable
as int,orderData: freezed == orderData ? _self.orderData : orderData // ignore: cast_nullable_to_non_nullable
as OrderActiveModel?,shopData: freezed == shopData ? _self.shopData : shopData // ignore: cast_nullable_to_non_nullable
as ShopData?,branches: freezed == branches ? _self._branches : branches // ignore: cast_nullable_to_non_nullable
as List<BranchModel>?,calculateData: freezed == calculateData ? _self.calculateData : calculateData // ignore: cast_nullable_to_non_nullable
as GetCalculateModel?,markers: null == markers ? _self._markers : markers // ignore: cast_nullable_to_non_nullable
as Map<MarkerId, Marker>,shopMarkers: null == shopMarkers ? _self._shopMarkers : shopMarkers // ignore: cast_nullable_to_non_nullable
as Set<Marker>,polylineCoordinates: null == polylineCoordinates ? _self._polylineCoordinates : polylineCoordinates // ignore: cast_nullable_to_non_nullable
as List<LatLng>,notes: null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<ProductNote>,todayTimes: null == todayTimes ? _self._todayTimes : todayTimes // ignore: cast_nullable_to_non_nullable
as List<String>,dailyTimes: null == dailyTimes ? _self._dailyTimes : dailyTimes // ignore: cast_nullable_to_non_nullable
as List<List<String>>,
  ));
}


}

// dart format on
