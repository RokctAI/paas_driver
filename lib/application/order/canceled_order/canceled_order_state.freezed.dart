// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'canceled_order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CanceledOrderState {

 bool get isLoading; List<OrderDetailData> get canceledOrders; num get totalCanceledOrder;
/// Create a copy of CanceledOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CanceledOrderStateCopyWith<CanceledOrderState> get copyWith => _$CanceledOrderStateCopyWithImpl<CanceledOrderState>(this as CanceledOrderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CanceledOrderState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.canceledOrders, canceledOrders)&&(identical(other.totalCanceledOrder, totalCanceledOrder) || other.totalCanceledOrder == totalCanceledOrder));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(canceledOrders),totalCanceledOrder);

@override
String toString() {
  return 'CanceledOrderState(isLoading: $isLoading, canceledOrders: $canceledOrders, totalCanceledOrder: $totalCanceledOrder)';
}


}

/// @nodoc
abstract mixin class $CanceledOrderStateCopyWith<$Res>  {
  factory $CanceledOrderStateCopyWith(CanceledOrderState value, $Res Function(CanceledOrderState) _then) = _$CanceledOrderStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<OrderDetailData> canceledOrders, num totalCanceledOrder
});




}
/// @nodoc
class _$CanceledOrderStateCopyWithImpl<$Res>
    implements $CanceledOrderStateCopyWith<$Res> {
  _$CanceledOrderStateCopyWithImpl(this._self, this._then);

  final CanceledOrderState _self;
  final $Res Function(CanceledOrderState) _then;

/// Create a copy of CanceledOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? canceledOrders = null,Object? totalCanceledOrder = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,canceledOrders: null == canceledOrders ? _self.canceledOrders : canceledOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,totalCanceledOrder: null == totalCanceledOrder ? _self.totalCanceledOrder : totalCanceledOrder // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [CanceledOrderState].
extension CanceledOrderStatePatterns on CanceledOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CanceledOrderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CanceledOrderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CanceledOrderState value)  $default,){
final _that = this;
switch (_that) {
case _CanceledOrderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CanceledOrderState value)?  $default,){
final _that = this;
switch (_that) {
case _CanceledOrderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderDetailData> canceledOrders,  num totalCanceledOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CanceledOrderState() when $default != null:
return $default(_that.isLoading,_that.canceledOrders,_that.totalCanceledOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderDetailData> canceledOrders,  num totalCanceledOrder)  $default,) {final _that = this;
switch (_that) {
case _CanceledOrderState():
return $default(_that.isLoading,_that.canceledOrders,_that.totalCanceledOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<OrderDetailData> canceledOrders,  num totalCanceledOrder)?  $default,) {final _that = this;
switch (_that) {
case _CanceledOrderState() when $default != null:
return $default(_that.isLoading,_that.canceledOrders,_that.totalCanceledOrder);case _:
  return null;

}
}

}

/// @nodoc


class _CanceledOrderState extends CanceledOrderState {
  const _CanceledOrderState({this.isLoading = false, final  List<OrderDetailData> canceledOrders = const [], this.totalCanceledOrder = 0}): _canceledOrders = canceledOrders,super._();
  

@override@JsonKey() final  bool isLoading;
 final  List<OrderDetailData> _canceledOrders;
@override@JsonKey() List<OrderDetailData> get canceledOrders {
  if (_canceledOrders is EqualUnmodifiableListView) return _canceledOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_canceledOrders);
}

@override@JsonKey() final  num totalCanceledOrder;

/// Create a copy of CanceledOrderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CanceledOrderStateCopyWith<_CanceledOrderState> get copyWith => __$CanceledOrderStateCopyWithImpl<_CanceledOrderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CanceledOrderState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._canceledOrders, _canceledOrders)&&(identical(other.totalCanceledOrder, totalCanceledOrder) || other.totalCanceledOrder == totalCanceledOrder));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_canceledOrders),totalCanceledOrder);

@override
String toString() {
  return 'CanceledOrderState(isLoading: $isLoading, canceledOrders: $canceledOrders, totalCanceledOrder: $totalCanceledOrder)';
}


}

/// @nodoc
abstract mixin class _$CanceledOrderStateCopyWith<$Res> implements $CanceledOrderStateCopyWith<$Res> {
  factory _$CanceledOrderStateCopyWith(_CanceledOrderState value, $Res Function(_CanceledOrderState) _then) = __$CanceledOrderStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<OrderDetailData> canceledOrders, num totalCanceledOrder
});




}
/// @nodoc
class __$CanceledOrderStateCopyWithImpl<$Res>
    implements _$CanceledOrderStateCopyWith<$Res> {
  __$CanceledOrderStateCopyWithImpl(this._self, this._then);

  final _CanceledOrderState _self;
  final $Res Function(_CanceledOrderState) _then;

/// Create a copy of CanceledOrderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? canceledOrders = null,Object? totalCanceledOrder = null,}) {
  return _then(_CanceledOrderState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,canceledOrders: null == canceledOrders ? _self._canceledOrders : canceledOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,totalCanceledOrder: null == totalCanceledOrder ? _self.totalCanceledOrder : totalCanceledOrder // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
