// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivered_order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliveredOrderState {

 bool get isLoading; List<OrderDetailData> get deliveredOrders; num get totalDeliveredOrder;
/// Create a copy of DeliveredOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveredOrderStateCopyWith<DeliveredOrderState> get copyWith => _$DeliveredOrderStateCopyWithImpl<DeliveredOrderState>(this as DeliveredOrderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveredOrderState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.deliveredOrders, deliveredOrders)&&(identical(other.totalDeliveredOrder, totalDeliveredOrder) || other.totalDeliveredOrder == totalDeliveredOrder));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(deliveredOrders),totalDeliveredOrder);

@override
String toString() {
  return 'DeliveredOrderState(isLoading: $isLoading, deliveredOrders: $deliveredOrders, totalDeliveredOrder: $totalDeliveredOrder)';
}


}

/// @nodoc
abstract mixin class $DeliveredOrderStateCopyWith<$Res>  {
  factory $DeliveredOrderStateCopyWith(DeliveredOrderState value, $Res Function(DeliveredOrderState) _then) = _$DeliveredOrderStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<OrderDetailData> deliveredOrders, num totalDeliveredOrder
});




}
/// @nodoc
class _$DeliveredOrderStateCopyWithImpl<$Res>
    implements $DeliveredOrderStateCopyWith<$Res> {
  _$DeliveredOrderStateCopyWithImpl(this._self, this._then);

  final DeliveredOrderState _self;
  final $Res Function(DeliveredOrderState) _then;

/// Create a copy of DeliveredOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? deliveredOrders = null,Object? totalDeliveredOrder = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,deliveredOrders: null == deliveredOrders ? _self.deliveredOrders : deliveredOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,totalDeliveredOrder: null == totalDeliveredOrder ? _self.totalDeliveredOrder : totalDeliveredOrder // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveredOrderState].
extension DeliveredOrderStatePatterns on DeliveredOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveredOrderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveredOrderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveredOrderState value)  $default,){
final _that = this;
switch (_that) {
case _DeliveredOrderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveredOrderState value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveredOrderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderDetailData> deliveredOrders,  num totalDeliveredOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveredOrderState() when $default != null:
return $default(_that.isLoading,_that.deliveredOrders,_that.totalDeliveredOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderDetailData> deliveredOrders,  num totalDeliveredOrder)  $default,) {final _that = this;
switch (_that) {
case _DeliveredOrderState():
return $default(_that.isLoading,_that.deliveredOrders,_that.totalDeliveredOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<OrderDetailData> deliveredOrders,  num totalDeliveredOrder)?  $default,) {final _that = this;
switch (_that) {
case _DeliveredOrderState() when $default != null:
return $default(_that.isLoading,_that.deliveredOrders,_that.totalDeliveredOrder);case _:
  return null;

}
}

}

/// @nodoc


class _DeliveredOrderState extends DeliveredOrderState {
  const _DeliveredOrderState({this.isLoading = false, final  List<OrderDetailData> deliveredOrders = const [], this.totalDeliveredOrder = 0}): _deliveredOrders = deliveredOrders,super._();
  

@override@JsonKey() final  bool isLoading;
 final  List<OrderDetailData> _deliveredOrders;
@override@JsonKey() List<OrderDetailData> get deliveredOrders {
  if (_deliveredOrders is EqualUnmodifiableListView) return _deliveredOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveredOrders);
}

@override@JsonKey() final  num totalDeliveredOrder;

/// Create a copy of DeliveredOrderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveredOrderStateCopyWith<_DeliveredOrderState> get copyWith => __$DeliveredOrderStateCopyWithImpl<_DeliveredOrderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveredOrderState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._deliveredOrders, _deliveredOrders)&&(identical(other.totalDeliveredOrder, totalDeliveredOrder) || other.totalDeliveredOrder == totalDeliveredOrder));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_deliveredOrders),totalDeliveredOrder);

@override
String toString() {
  return 'DeliveredOrderState(isLoading: $isLoading, deliveredOrders: $deliveredOrders, totalDeliveredOrder: $totalDeliveredOrder)';
}


}

/// @nodoc
abstract mixin class _$DeliveredOrderStateCopyWith<$Res> implements $DeliveredOrderStateCopyWith<$Res> {
  factory _$DeliveredOrderStateCopyWith(_DeliveredOrderState value, $Res Function(_DeliveredOrderState) _then) = __$DeliveredOrderStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<OrderDetailData> deliveredOrders, num totalDeliveredOrder
});




}
/// @nodoc
class __$DeliveredOrderStateCopyWithImpl<$Res>
    implements _$DeliveredOrderStateCopyWith<$Res> {
  __$DeliveredOrderStateCopyWithImpl(this._self, this._then);

  final _DeliveredOrderState _self;
  final $Res Function(_DeliveredOrderState) _then;

/// Create a copy of DeliveredOrderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? deliveredOrders = null,Object? totalDeliveredOrder = null,}) {
  return _then(_DeliveredOrderState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,deliveredOrders: null == deliveredOrders ? _self._deliveredOrders : deliveredOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,totalDeliveredOrder: null == totalDeliveredOrder ? _self.totalDeliveredOrder : totalDeliveredOrder // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
