// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parcel_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ParcelState {

 bool get isActiveLoading; bool get isLoading; bool get isAvailableLoading; bool get isHistoryLoading; bool get paymentType; ParcelOrder? get order; List<ParcelOrder> get activeOrders; List<ParcelOrder> get availableOrders; List<ParcelOrder> get historyOrders; num get totalActiveOrder; int get deliveryTime; int get deliveryType;
/// Create a copy of ParcelState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParcelStateCopyWith<ParcelState> get copyWith => _$ParcelStateCopyWithImpl<ParcelState>(this as ParcelState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParcelState&&(identical(other.isActiveLoading, isActiveLoading) || other.isActiveLoading == isActiveLoading)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isAvailableLoading, isAvailableLoading) || other.isAvailableLoading == isAvailableLoading)&&(identical(other.isHistoryLoading, isHistoryLoading) || other.isHistoryLoading == isHistoryLoading)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.activeOrders, activeOrders)&&const DeepCollectionEquality().equals(other.availableOrders, availableOrders)&&const DeepCollectionEquality().equals(other.historyOrders, historyOrders)&&(identical(other.totalActiveOrder, totalActiveOrder) || other.totalActiveOrder == totalActiveOrder)&&(identical(other.deliveryTime, deliveryTime) || other.deliveryTime == deliveryTime)&&(identical(other.deliveryType, deliveryType) || other.deliveryType == deliveryType));
}


@override
int get hashCode => Object.hash(runtimeType,isActiveLoading,isLoading,isAvailableLoading,isHistoryLoading,paymentType,order,const DeepCollectionEquality().hash(activeOrders),const DeepCollectionEquality().hash(availableOrders),const DeepCollectionEquality().hash(historyOrders),totalActiveOrder,deliveryTime,deliveryType);

@override
String toString() {
  return 'ParcelState(isActiveLoading: $isActiveLoading, isLoading: $isLoading, isAvailableLoading: $isAvailableLoading, isHistoryLoading: $isHistoryLoading, paymentType: $paymentType, order: $order, activeOrders: $activeOrders, availableOrders: $availableOrders, historyOrders: $historyOrders, totalActiveOrder: $totalActiveOrder, deliveryTime: $deliveryTime, deliveryType: $deliveryType)';
}


}

/// @nodoc
abstract mixin class $ParcelStateCopyWith<$Res>  {
  factory $ParcelStateCopyWith(ParcelState value, $Res Function(ParcelState) _then) = _$ParcelStateCopyWithImpl;
@useResult
$Res call({
 bool isActiveLoading, bool isLoading, bool isAvailableLoading, bool isHistoryLoading, bool paymentType, ParcelOrder? order, List<ParcelOrder> activeOrders, List<ParcelOrder> availableOrders, List<ParcelOrder> historyOrders, num totalActiveOrder, int deliveryTime, int deliveryType
});




}
/// @nodoc
class _$ParcelStateCopyWithImpl<$Res>
    implements $ParcelStateCopyWith<$Res> {
  _$ParcelStateCopyWithImpl(this._self, this._then);

  final ParcelState _self;
  final $Res Function(ParcelState) _then;

/// Create a copy of ParcelState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isActiveLoading = null,Object? isLoading = null,Object? isAvailableLoading = null,Object? isHistoryLoading = null,Object? paymentType = null,Object? order = freezed,Object? activeOrders = null,Object? availableOrders = null,Object? historyOrders = null,Object? totalActiveOrder = null,Object? deliveryTime = null,Object? deliveryType = null,}) {
  return _then(_self.copyWith(
isActiveLoading: null == isActiveLoading ? _self.isActiveLoading : isActiveLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isAvailableLoading: null == isAvailableLoading ? _self.isAvailableLoading : isAvailableLoading // ignore: cast_nullable_to_non_nullable
as bool,isHistoryLoading: null == isHistoryLoading ? _self.isHistoryLoading : isHistoryLoading // ignore: cast_nullable_to_non_nullable
as bool,paymentType: null == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as ParcelOrder?,activeOrders: null == activeOrders ? _self.activeOrders : activeOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,availableOrders: null == availableOrders ? _self.availableOrders : availableOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,historyOrders: null == historyOrders ? _self.historyOrders : historyOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,totalActiveOrder: null == totalActiveOrder ? _self.totalActiveOrder : totalActiveOrder // ignore: cast_nullable_to_non_nullable
as num,deliveryTime: null == deliveryTime ? _self.deliveryTime : deliveryTime // ignore: cast_nullable_to_non_nullable
as int,deliveryType: null == deliveryType ? _self.deliveryType : deliveryType // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ParcelState].
extension ParcelStatePatterns on ParcelState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParcelState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParcelState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParcelState value)  $default,){
final _that = this;
switch (_that) {
case _ParcelState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParcelState value)?  $default,){
final _that = this;
switch (_that) {
case _ParcelState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActiveLoading,  bool isLoading,  bool isAvailableLoading,  bool isHistoryLoading,  bool paymentType,  ParcelOrder? order,  List<ParcelOrder> activeOrders,  List<ParcelOrder> availableOrders,  List<ParcelOrder> historyOrders,  num totalActiveOrder,  int deliveryTime,  int deliveryType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParcelState() when $default != null:
return $default(_that.isActiveLoading,_that.isLoading,_that.isAvailableLoading,_that.isHistoryLoading,_that.paymentType,_that.order,_that.activeOrders,_that.availableOrders,_that.historyOrders,_that.totalActiveOrder,_that.deliveryTime,_that.deliveryType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActiveLoading,  bool isLoading,  bool isAvailableLoading,  bool isHistoryLoading,  bool paymentType,  ParcelOrder? order,  List<ParcelOrder> activeOrders,  List<ParcelOrder> availableOrders,  List<ParcelOrder> historyOrders,  num totalActiveOrder,  int deliveryTime,  int deliveryType)  $default,) {final _that = this;
switch (_that) {
case _ParcelState():
return $default(_that.isActiveLoading,_that.isLoading,_that.isAvailableLoading,_that.isHistoryLoading,_that.paymentType,_that.order,_that.activeOrders,_that.availableOrders,_that.historyOrders,_that.totalActiveOrder,_that.deliveryTime,_that.deliveryType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActiveLoading,  bool isLoading,  bool isAvailableLoading,  bool isHistoryLoading,  bool paymentType,  ParcelOrder? order,  List<ParcelOrder> activeOrders,  List<ParcelOrder> availableOrders,  List<ParcelOrder> historyOrders,  num totalActiveOrder,  int deliveryTime,  int deliveryType)?  $default,) {final _that = this;
switch (_that) {
case _ParcelState() when $default != null:
return $default(_that.isActiveLoading,_that.isLoading,_that.isAvailableLoading,_that.isHistoryLoading,_that.paymentType,_that.order,_that.activeOrders,_that.availableOrders,_that.historyOrders,_that.totalActiveOrder,_that.deliveryTime,_that.deliveryType);case _:
  return null;

}
}

}

/// @nodoc


class _ParcelState extends ParcelState {
  const _ParcelState({this.isActiveLoading = false, this.isLoading = false, this.isAvailableLoading = false, this.isHistoryLoading = false, this.paymentType = false, this.order = null, final  List<ParcelOrder> activeOrders = const [], final  List<ParcelOrder> availableOrders = const [], final  List<ParcelOrder> historyOrders = const [], this.totalActiveOrder = 0, this.deliveryTime = 0, this.deliveryType = 0}): _activeOrders = activeOrders,_availableOrders = availableOrders,_historyOrders = historyOrders,super._();
  

@override@JsonKey() final  bool isActiveLoading;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isAvailableLoading;
@override@JsonKey() final  bool isHistoryLoading;
@override@JsonKey() final  bool paymentType;
@override@JsonKey() final  ParcelOrder? order;
 final  List<ParcelOrder> _activeOrders;
@override@JsonKey() List<ParcelOrder> get activeOrders {
  if (_activeOrders is EqualUnmodifiableListView) return _activeOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeOrders);
}

 final  List<ParcelOrder> _availableOrders;
@override@JsonKey() List<ParcelOrder> get availableOrders {
  if (_availableOrders is EqualUnmodifiableListView) return _availableOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableOrders);
}

 final  List<ParcelOrder> _historyOrders;
@override@JsonKey() List<ParcelOrder> get historyOrders {
  if (_historyOrders is EqualUnmodifiableListView) return _historyOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_historyOrders);
}

@override@JsonKey() final  num totalActiveOrder;
@override@JsonKey() final  int deliveryTime;
@override@JsonKey() final  int deliveryType;

/// Create a copy of ParcelState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParcelStateCopyWith<_ParcelState> get copyWith => __$ParcelStateCopyWithImpl<_ParcelState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParcelState&&(identical(other.isActiveLoading, isActiveLoading) || other.isActiveLoading == isActiveLoading)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isAvailableLoading, isAvailableLoading) || other.isAvailableLoading == isAvailableLoading)&&(identical(other.isHistoryLoading, isHistoryLoading) || other.isHistoryLoading == isHistoryLoading)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._activeOrders, _activeOrders)&&const DeepCollectionEquality().equals(other._availableOrders, _availableOrders)&&const DeepCollectionEquality().equals(other._historyOrders, _historyOrders)&&(identical(other.totalActiveOrder, totalActiveOrder) || other.totalActiveOrder == totalActiveOrder)&&(identical(other.deliveryTime, deliveryTime) || other.deliveryTime == deliveryTime)&&(identical(other.deliveryType, deliveryType) || other.deliveryType == deliveryType));
}


@override
int get hashCode => Object.hash(runtimeType,isActiveLoading,isLoading,isAvailableLoading,isHistoryLoading,paymentType,order,const DeepCollectionEquality().hash(_activeOrders),const DeepCollectionEquality().hash(_availableOrders),const DeepCollectionEquality().hash(_historyOrders),totalActiveOrder,deliveryTime,deliveryType);

@override
String toString() {
  return 'ParcelState(isActiveLoading: $isActiveLoading, isLoading: $isLoading, isAvailableLoading: $isAvailableLoading, isHistoryLoading: $isHistoryLoading, paymentType: $paymentType, order: $order, activeOrders: $activeOrders, availableOrders: $availableOrders, historyOrders: $historyOrders, totalActiveOrder: $totalActiveOrder, deliveryTime: $deliveryTime, deliveryType: $deliveryType)';
}


}

/// @nodoc
abstract mixin class _$ParcelStateCopyWith<$Res> implements $ParcelStateCopyWith<$Res> {
  factory _$ParcelStateCopyWith(_ParcelState value, $Res Function(_ParcelState) _then) = __$ParcelStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActiveLoading, bool isLoading, bool isAvailableLoading, bool isHistoryLoading, bool paymentType, ParcelOrder? order, List<ParcelOrder> activeOrders, List<ParcelOrder> availableOrders, List<ParcelOrder> historyOrders, num totalActiveOrder, int deliveryTime, int deliveryType
});




}
/// @nodoc
class __$ParcelStateCopyWithImpl<$Res>
    implements _$ParcelStateCopyWith<$Res> {
  __$ParcelStateCopyWithImpl(this._self, this._then);

  final _ParcelState _self;
  final $Res Function(_ParcelState) _then;

/// Create a copy of ParcelState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isActiveLoading = null,Object? isLoading = null,Object? isAvailableLoading = null,Object? isHistoryLoading = null,Object? paymentType = null,Object? order = freezed,Object? activeOrders = null,Object? availableOrders = null,Object? historyOrders = null,Object? totalActiveOrder = null,Object? deliveryTime = null,Object? deliveryType = null,}) {
  return _then(_ParcelState(
isActiveLoading: null == isActiveLoading ? _self.isActiveLoading : isActiveLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isAvailableLoading: null == isAvailableLoading ? _self.isAvailableLoading : isAvailableLoading // ignore: cast_nullable_to_non_nullable
as bool,isHistoryLoading: null == isHistoryLoading ? _self.isHistoryLoading : isHistoryLoading // ignore: cast_nullable_to_non_nullable
as bool,paymentType: null == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as ParcelOrder?,activeOrders: null == activeOrders ? _self._activeOrders : activeOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,availableOrders: null == availableOrders ? _self._availableOrders : availableOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,historyOrders: null == historyOrders ? _self._historyOrders : historyOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,totalActiveOrder: null == totalActiveOrder ? _self.totalActiveOrder : totalActiveOrder // ignore: cast_nullable_to_non_nullable
as num,deliveryTime: null == deliveryTime ? _self.deliveryTime : deliveryTime // ignore: cast_nullable_to_non_nullable
as int,deliveryType: null == deliveryType ? _self.deliveryType : deliveryType // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
