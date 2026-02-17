// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress_order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProgressOrderState {

 bool get isLoading; List<OrderDetailData> get progressOrders; num get totalProgressOrder;
/// Create a copy of ProgressOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressOrderStateCopyWith<ProgressOrderState> get copyWith => _$ProgressOrderStateCopyWithImpl<ProgressOrderState>(this as ProgressOrderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressOrderState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.progressOrders, progressOrders)&&(identical(other.totalProgressOrder, totalProgressOrder) || other.totalProgressOrder == totalProgressOrder));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(progressOrders),totalProgressOrder);

@override
String toString() {
  return 'ProgressOrderState(isLoading: $isLoading, progressOrders: $progressOrders, totalProgressOrder: $totalProgressOrder)';
}


}

/// @nodoc
abstract mixin class $ProgressOrderStateCopyWith<$Res>  {
  factory $ProgressOrderStateCopyWith(ProgressOrderState value, $Res Function(ProgressOrderState) _then) = _$ProgressOrderStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<OrderDetailData> progressOrders, num totalProgressOrder
});




}
/// @nodoc
class _$ProgressOrderStateCopyWithImpl<$Res>
    implements $ProgressOrderStateCopyWith<$Res> {
  _$ProgressOrderStateCopyWithImpl(this._self, this._then);

  final ProgressOrderState _self;
  final $Res Function(ProgressOrderState) _then;

/// Create a copy of ProgressOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? progressOrders = null,Object? totalProgressOrder = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,progressOrders: null == progressOrders ? _self.progressOrders : progressOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,totalProgressOrder: null == totalProgressOrder ? _self.totalProgressOrder : totalProgressOrder // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressOrderState].
extension ProgressOrderStatePatterns on ProgressOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressOrderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressOrderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressOrderState value)  $default,){
final _that = this;
switch (_that) {
case _ProgressOrderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressOrderState value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressOrderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderDetailData> progressOrders,  num totalProgressOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressOrderState() when $default != null:
return $default(_that.isLoading,_that.progressOrders,_that.totalProgressOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<OrderDetailData> progressOrders,  num totalProgressOrder)  $default,) {final _that = this;
switch (_that) {
case _ProgressOrderState():
return $default(_that.isLoading,_that.progressOrders,_that.totalProgressOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<OrderDetailData> progressOrders,  num totalProgressOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProgressOrderState() when $default != null:
return $default(_that.isLoading,_that.progressOrders,_that.totalProgressOrder);case _:
  return null;

}
}

}

/// @nodoc


class _ProgressOrderState extends ProgressOrderState {
  const _ProgressOrderState({this.isLoading = false, final  List<OrderDetailData> progressOrders = const [], this.totalProgressOrder = 0}): _progressOrders = progressOrders,super._();
  

@override@JsonKey() final  bool isLoading;
 final  List<OrderDetailData> _progressOrders;
@override@JsonKey() List<OrderDetailData> get progressOrders {
  if (_progressOrders is EqualUnmodifiableListView) return _progressOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_progressOrders);
}

@override@JsonKey() final  num totalProgressOrder;

/// Create a copy of ProgressOrderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressOrderStateCopyWith<_ProgressOrderState> get copyWith => __$ProgressOrderStateCopyWithImpl<_ProgressOrderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressOrderState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._progressOrders, _progressOrders)&&(identical(other.totalProgressOrder, totalProgressOrder) || other.totalProgressOrder == totalProgressOrder));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_progressOrders),totalProgressOrder);

@override
String toString() {
  return 'ProgressOrderState(isLoading: $isLoading, progressOrders: $progressOrders, totalProgressOrder: $totalProgressOrder)';
}


}

/// @nodoc
abstract mixin class _$ProgressOrderStateCopyWith<$Res> implements $ProgressOrderStateCopyWith<$Res> {
  factory _$ProgressOrderStateCopyWith(_ProgressOrderState value, $Res Function(_ProgressOrderState) _then) = __$ProgressOrderStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<OrderDetailData> progressOrders, num totalProgressOrder
});




}
/// @nodoc
class __$ProgressOrderStateCopyWithImpl<$Res>
    implements _$ProgressOrderStateCopyWith<$Res> {
  __$ProgressOrderStateCopyWithImpl(this._self, this._then);

  final _ProgressOrderState _self;
  final $Res Function(_ProgressOrderState) _then;

/// Create a copy of ProgressOrderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? progressOrders = null,Object? totalProgressOrder = null,}) {
  return _then(_ProgressOrderState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,progressOrders: null == progressOrders ? _self._progressOrders : progressOrders // ignore: cast_nullable_to_non_nullable
as List<OrderDetailData>,totalProgressOrder: null == totalProgressOrder ? _self.totalProgressOrder : totalProgressOrder // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
