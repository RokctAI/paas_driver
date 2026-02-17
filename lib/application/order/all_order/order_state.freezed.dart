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

 bool get isActiveLoading; bool get isLoading; bool get isAvailableLoading; bool get isHistoryLoading; bool get paymentType; OrderDetailData? get order; List<OrderDetailData> get activeOrders; List<OrderDetailData> get availableOrders; List<OrderDetailData> get historyOrders; num get totalActiveOrder; int get deliveryTime; int get deliveryType; List<OrderDetailData> get deliveryOrders; List<OrderDetailData> get cancelOrders; List<OrderDetailData> get progressOrders;
/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStateCopyWith<OrderState> get copyWith => _$OrderStateCopyWithImpl<OrderState>(this as OrderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderState&&(identical(other.isActiveLoading, isActiveLoading) || other.isActiveLoading == isActiveLoading)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isAvailableLoading, isAvailableLoading) || other.isAvailableLoading == isAvailableLoading)&&(identical(other.isHistoryLoading, isHistoryLoading) || other.isHistoryLoading == isHistoryLoading)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.activeOrders, activeOrders)&&const DeepCollectionEquality().equals(other.availableOrders, availableOrders)&&const DeepCollectionEquality().equals(other.historyOrders, historyOrders)&&(identical(other.totalActiveOrder, totalActiveOrder) || other.totalActiveOrder == totalActiveOrder)&&(identical(other.deliveryTime, deliveryTime) || other.deliveryTime == deliveryTime)&&(identical(other.deliveryType, deliveryType) || other.deliveryType == deliveryType)&&const DeepCollectionEquality().equals(other.deliveryOrders, deliveryOrders)&&const DeepCollectionEquality().equals(other.cancelOrders, cancelOrders)&&const DeepCollectionEquality().equals(other.progressOrders, progressOrders));
}


@override
int get hashCode => Object.hash(runtimeType,isActiveLoading,isLoading,isAvailableLoading,isHistoryLoading,paymentType,order,const DeepCollectionEquality().hash(activeOrders),const DeepCollectionEquality().hash(availableOrders),const DeepCollectionEquality().hash(historyOrders),totalActiveOrder,deliveryTime,deliveryType,const DeepCollectionEquality().hash(deliveryOrders),const DeepCollectionEquality().hash(cancelOrders),const DeepCollectionEquality().hash(progressOrders));

@override
String toString() {
  return 'OrderState(isActiveLoading: $isActiveLoading, isLoading: $isLoading, isAvailableLoading: $isAvailableLoading, isHistoryLoading: $isHistoryLoading, paymentType: $paymentType, order: $order, activeOrders: $activeOrders, availableOrders: $availableOrders, historyOrders: $historyOrders, totalActiveOrder: $totalActiveOrder, deliveryTime: $deliveryTime, deliveryType: $deliveryType, deliveryOrders: $deliveryOrders, cancelOrders: $cancelOrders, progressOrders: $progressOrders)';
}


}

/// @nodoc
abstract mixin class $OrderStateCopyWith<$Res>  {
  factory $OrderStateCopyWith(OrderState value, $Res Function(OrderState) _then) = _$OrderStateCopyWithImpl;
@useResult
$Res call({
 bool isActiveLoading, bool isLoading, bool isAvailableLoading, bool isHistoryLoading, bool paymentType, OrderDetailData? order, List<OrderDetailData> activeOrders, List<OrderDetailData> availableOrders, List<OrderDetailData> historyOrders, num totalActiveOrder, int deliveryTime, int deliveryType, List<OrderDetailData> deliveryOrders, List<OrderDetailData> cancelOrders, List<OrderDetailData> progressOrders
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
@pragma('vm:prefer-inline') @override $Res call({Object? isActiveLoading = null,Object? isLoading = null,Object? isAvailableLoading = null,Object? isHistoryLoading = null,Object? paymentType = null,Object? order = freezed,Object? activeOrders = null,Object? availableOrders = null,Object? historyOrders = null,Object? totalActiveOrder = null,Object? deliveryTime = null,Object? deliveryType = null,Object? deliveryOrders = null,Object? cancelOrders = null,Object? progressOrders = null,}) {
  return _then(_self.copyWith(
isActiveLoading: null == isActiveLoading ? _self.isActiveLoading : isActiveLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isAvailableLoading: null == isAvailableLoading ? _self.isAvailableLoading : isAvailableLoading // ignore: cast_nullable_to_non_nullable
as bool,isHistoryLoading: null == isHistoryLoading ? _self.isHistoryLoading : isHistoryLoading // ignore: cast_nullable_to_non_nullable
as bool,paymentType: null == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as OrderDetailData?,activeOrders: null == activeOrders ? _self.activeOrders : activeOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,availableOrders: null == availableOrders ? _self.availableOrders : availableOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,historyOrders: null == historyOrders ? _self.historyOrders : historyOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,totalActiveOrder: null == totalActiveOrder ? _self.totalActiveOrder : totalActiveOrder // ignore: cast_nullable_to_non_nullable
as num,deliveryTime: null == deliveryTime ? _self.deliveryTime : deliveryTime // ignore: cast_nullable_to_non_nullable
as int,deliveryType: null == deliveryType ? _self.deliveryType : deliveryType // ignore: cast_nullable_to_non_nullable
as int,deliveryOrders: null == deliveryOrders ? _self.deliveryOrders : deliveryOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,cancelOrders: null == cancelOrders ? _self.cancelOrders : cancelOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,progressOrders: null == progressOrders ? _self.progressOrders : progressOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrdrState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrdrState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrdrState value)  $default,){
final _that = this;
switch (_that) {
case _OrdrState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrdrState value)?  $default,){
final _that = this;
switch (_that) {
case _OrdrState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActiveLoading,  bool isLoading,  bool isAvailableLoading,  bool isHistoryLoading,  bool paymentType,  OrderDetailData? order,  List<OrderDetailData> activeOrders,  List<OrderDetailData> availableOrders,  List<OrderDetailData> historyOrders,  num totalActiveOrder,  int deliveryTime,  int deliveryType,  List<OrderDetailData> deliveryOrders,  List<OrderDetailData> cancelOrders,  List<OrderDetailData> progressOrders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrdrState() when $default != null:
return $default(_that.isActiveLoading,_that.isLoading,_that.isAvailableLoading,_that.isHistoryLoading,_that.paymentType,_that.order,_that.activeOrders,_that.availableOrders,_that.historyOrders,_that.totalActiveOrder,_that.deliveryTime,_that.deliveryType,_that.deliveryOrders,_that.cancelOrders,_that.progressOrders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActiveLoading,  bool isLoading,  bool isAvailableLoading,  bool isHistoryLoading,  bool paymentType,  OrderDetailData? order,  List<OrderDetailData> activeOrders,  List<OrderDetailData> availableOrders,  List<OrderDetailData> historyOrders,  num totalActiveOrder,  int deliveryTime,  int deliveryType,  List<OrderDetailData> deliveryOrders,  List<OrderDetailData> cancelOrders,  List<OrderDetailData> progressOrders)  $default,) {final _that = this;
switch (_that) {
case _OrdrState():
return $default(_that.isActiveLoading,_that.isLoading,_that.isAvailableLoading,_that.isHistoryLoading,_that.paymentType,_that.order,_that.activeOrders,_that.availableOrders,_that.historyOrders,_that.totalActiveOrder,_that.deliveryTime,_that.deliveryType,_that.deliveryOrders,_that.cancelOrders,_that.progressOrders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActiveLoading,  bool isLoading,  bool isAvailableLoading,  bool isHistoryLoading,  bool paymentType,  OrderDetailData? order,  List<OrderDetailData> activeOrders,  List<OrderDetailData> availableOrders,  List<OrderDetailData> historyOrders,  num totalActiveOrder,  int deliveryTime,  int deliveryType,  List<OrderDetailData> deliveryOrders,  List<OrderDetailData> cancelOrders,  List<OrderDetailData> progressOrders)?  $default,) {final _that = this;
switch (_that) {
case _OrdrState() when $default != null:
return $default(_that.isActiveLoading,_that.isLoading,_that.isAvailableLoading,_that.isHistoryLoading,_that.paymentType,_that.order,_that.activeOrders,_that.availableOrders,_that.historyOrders,_that.totalActiveOrder,_that.deliveryTime,_that.deliveryType,_that.deliveryOrders,_that.cancelOrders,_that.progressOrders);case _:
  return null;

}
}

}

/// @nodoc


class _OrdrState extends OrderState {
  const _OrdrState({this.isActiveLoading = false, this.isLoading = false, this.isAvailableLoading = false, this.isHistoryLoading = false, this.paymentType = false, this.order = null, final  List<OrderDetailData> activeOrders = const [], final  List<OrderDetailData> availableOrders = const [], final  List<OrderDetailData> historyOrders = const [], this.totalActiveOrder = 0, this.deliveryTime = 0, this.deliveryType = 0, final  List<OrderDetailData> deliveryOrders = const [], final  List<OrderDetailData> cancelOrders = const [], final  List<OrderDetailData> progressOrders = const []}): _activeOrders = activeOrders,_availableOrders = availableOrders,_historyOrders = historyOrders,_deliveryOrders = deliveryOrders,_cancelOrders = cancelOrders,_progressOrders = progressOrders,super._();
  

@override@JsonKey() final  bool isActiveLoading;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isAvailableLoading;
@override@JsonKey() final  bool isHistoryLoading;
@override@JsonKey() final  bool paymentType;
@override@JsonKey() final  OrderDetailData? order;
 final  List<OrderDetailData> _activeOrders;
@override@JsonKey() List<OrderDetailData> get activeOrders {
  if (_activeOrders is EqualUnmodifiableListView) return _activeOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeOrders);
}

 final  List<OrderDetailData> _availableOrders;
@override@JsonKey() List<OrderDetailData> get availableOrders {
  if (_availableOrders is EqualUnmodifiableListView) return _availableOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableOrders);
}

 final  List<OrderDetailData> _historyOrders;
@override@JsonKey() List<OrderDetailData> get historyOrders {
  if (_historyOrders is EqualUnmodifiableListView) return _historyOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_historyOrders);
}

@override@JsonKey() final  num totalActiveOrder;
@override@JsonKey() final  int deliveryTime;
@override@JsonKey() final  int deliveryType;
 final  List<OrderDetailData> _deliveryOrders;
@override@JsonKey() List<OrderDetailData> get deliveryOrders {
  if (_deliveryOrders is EqualUnmodifiableListView) return _deliveryOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveryOrders);
}

 final  List<OrderDetailData> _cancelOrders;
@override@JsonKey() List<OrderDetailData> get cancelOrders {
  if (_cancelOrders is EqualUnmodifiableListView) return _cancelOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cancelOrders);
}

 final  List<OrderDetailData> _progressOrders;
@override@JsonKey() List<OrderDetailData> get progressOrders {
  if (_progressOrders is EqualUnmodifiableListView) return _progressOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_progressOrders);
}


/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrdrStateCopyWith<_OrdrState> get copyWith => __$OrdrStateCopyWithImpl<_OrdrState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrdrState&&(identical(other.isActiveLoading, isActiveLoading) || other.isActiveLoading == isActiveLoading)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isAvailableLoading, isAvailableLoading) || other.isAvailableLoading == isAvailableLoading)&&(identical(other.isHistoryLoading, isHistoryLoading) || other.isHistoryLoading == isHistoryLoading)&&(identical(other.paymentType, paymentType) || other.paymentType == paymentType)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._activeOrders, _activeOrders)&&const DeepCollectionEquality().equals(other._availableOrders, _availableOrders)&&const DeepCollectionEquality().equals(other._historyOrders, _historyOrders)&&(identical(other.totalActiveOrder, totalActiveOrder) || other.totalActiveOrder == totalActiveOrder)&&(identical(other.deliveryTime, deliveryTime) || other.deliveryTime == deliveryTime)&&(identical(other.deliveryType, deliveryType) || other.deliveryType == deliveryType)&&const DeepCollectionEquality().equals(other._deliveryOrders, _deliveryOrders)&&const DeepCollectionEquality().equals(other._cancelOrders, _cancelOrders)&&const DeepCollectionEquality().equals(other._progressOrders, _progressOrders));
}


@override
int get hashCode => Object.hash(runtimeType,isActiveLoading,isLoading,isAvailableLoading,isHistoryLoading,paymentType,order,const DeepCollectionEquality().hash(_activeOrders),const DeepCollectionEquality().hash(_availableOrders),const DeepCollectionEquality().hash(_historyOrders),totalActiveOrder,deliveryTime,deliveryType,const DeepCollectionEquality().hash(_deliveryOrders),const DeepCollectionEquality().hash(_cancelOrders),const DeepCollectionEquality().hash(_progressOrders));

@override
String toString() {
  return 'OrderState(isActiveLoading: $isActiveLoading, isLoading: $isLoading, isAvailableLoading: $isAvailableLoading, isHistoryLoading: $isHistoryLoading, paymentType: $paymentType, order: $order, activeOrders: $activeOrders, availableOrders: $availableOrders, historyOrders: $historyOrders, totalActiveOrder: $totalActiveOrder, deliveryTime: $deliveryTime, deliveryType: $deliveryType, deliveryOrders: $deliveryOrders, cancelOrders: $cancelOrders, progressOrders: $progressOrders)';
}


}

/// @nodoc
abstract mixin class _$OrdrStateCopyWith<$Res> implements $OrderStateCopyWith<$Res> {
  factory _$OrdrStateCopyWith(_OrdrState value, $Res Function(_OrdrState) _then) = __$OrdrStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActiveLoading, bool isLoading, bool isAvailableLoading, bool isHistoryLoading, bool paymentType, OrderDetailData? order, List<OrderDetailData> activeOrders, List<OrderDetailData> availableOrders, List<OrderDetailData> historyOrders, num totalActiveOrder, int deliveryTime, int deliveryType, List<OrderDetailData> deliveryOrders, List<OrderDetailData> cancelOrders, List<OrderDetailData> progressOrders
});




}
/// @nodoc
class __$OrdrStateCopyWithImpl<$Res>
    implements _$OrdrStateCopyWith<$Res> {
  __$OrdrStateCopyWithImpl(this._self, this._then);

  final _OrdrState _self;
  final $Res Function(_OrdrState) _then;

/// Create a copy of OrderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isActiveLoading = null,Object? isLoading = null,Object? isAvailableLoading = null,Object? isHistoryLoading = null,Object? paymentType = null,Object? order = freezed,Object? activeOrders = null,Object? availableOrders = null,Object? historyOrders = null,Object? totalActiveOrder = null,Object? deliveryTime = null,Object? deliveryType = null,Object? deliveryOrders = null,Object? cancelOrders = null,Object? progressOrders = null,}) {
  return _then(_OrdrState(
isActiveLoading: null == isActiveLoading ? _self.isActiveLoading : isActiveLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isAvailableLoading: null == isAvailableLoading ? _self.isAvailableLoading : isAvailableLoading // ignore: cast_nullable_to_non_nullable
as bool,isHistoryLoading: null == isHistoryLoading ? _self.isHistoryLoading : isHistoryLoading // ignore: cast_nullable_to_non_nullable
as bool,paymentType: null == paymentType ? _self.paymentType : paymentType // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as OrderDetailData?,activeOrders: null == activeOrders ? _self._activeOrders : activeOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,availableOrders: null == availableOrders ? _self._availableOrders : availableOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,historyOrders: null == historyOrders ? _self._historyOrders : historyOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,totalActiveOrder: null == totalActiveOrder ? _self.totalActiveOrder : totalActiveOrder // ignore: cast_nullable_to_non_nullable
as num,deliveryTime: null == deliveryTime ? _self.deliveryTime : deliveryTime // ignore: cast_nullable_to_non_nullable
as int,deliveryType: null == deliveryType ? _self.deliveryType : deliveryType // ignore: cast_nullable_to_non_nullable
as int,deliveryOrders: null == deliveryOrders ? _self._deliveryOrders : deliveryOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,cancelOrders: null == cancelOrders ? _self._cancelOrders : cancelOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,progressOrders: null == progressOrders ? _self._progressOrders : progressOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,
  ));
}


}

// dart format on
