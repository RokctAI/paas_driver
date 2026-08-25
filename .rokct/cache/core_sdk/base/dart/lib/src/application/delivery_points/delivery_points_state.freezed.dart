// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_points_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliveryPointsState {

 bool get isLoading; List<DeliveryPointData> get deliveryPoints;
/// Create a copy of DeliveryPointsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryPointsStateCopyWith<DeliveryPointsState> get copyWith => _$DeliveryPointsStateCopyWithImpl<DeliveryPointsState>(this as DeliveryPointsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryPointsState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other.deliveryPoints, deliveryPoints));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(deliveryPoints));

@override
String toString() {
  return 'DeliveryPointsState(isLoading: $isLoading, deliveryPoints: $deliveryPoints)';
}


}

/// @nodoc
abstract mixin class $DeliveryPointsStateCopyWith<$Res>  {
  factory $DeliveryPointsStateCopyWith(DeliveryPointsState value, $Res Function(DeliveryPointsState) _then) = _$DeliveryPointsStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, List<DeliveryPointData> deliveryPoints
});




}
/// @nodoc
class _$DeliveryPointsStateCopyWithImpl<$Res>
    implements $DeliveryPointsStateCopyWith<$Res> {
  _$DeliveryPointsStateCopyWithImpl(this._self, this._then);

  final DeliveryPointsState _self;
  final $Res Function(DeliveryPointsState) _then;

/// Create a copy of DeliveryPointsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? deliveryPoints = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,deliveryPoints: null == deliveryPoints ? _self.deliveryPoints : deliveryPoints // ignore: cast_nullable_to_non_nullable
as List<DeliveryPointData>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryPointsState].
extension DeliveryPointsStatePatterns on DeliveryPointsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryPointsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryPointsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryPointsState value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryPointsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryPointsState value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryPointsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  List<DeliveryPointData> deliveryPoints)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryPointsState() when $default != null:
return $default(_that.isLoading,_that.deliveryPoints);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  List<DeliveryPointData> deliveryPoints)  $default,) {final _that = this;
switch (_that) {
case _DeliveryPointsState():
return $default(_that.isLoading,_that.deliveryPoints);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  List<DeliveryPointData> deliveryPoints)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryPointsState() when $default != null:
return $default(_that.isLoading,_that.deliveryPoints);case _:
  return null;

}
}

}

/// @nodoc


class _DeliveryPointsState extends DeliveryPointsState {
  const _DeliveryPointsState({this.isLoading = false, final  List<DeliveryPointData> deliveryPoints = const []}): _deliveryPoints = deliveryPoints,super._();
  

@override@JsonKey() final  bool isLoading;
 final  List<DeliveryPointData> _deliveryPoints;
@override@JsonKey() List<DeliveryPointData> get deliveryPoints {
  if (_deliveryPoints is EqualUnmodifiableListView) return _deliveryPoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveryPoints);
}


/// Create a copy of DeliveryPointsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryPointsStateCopyWith<_DeliveryPointsState> get copyWith => __$DeliveryPointsStateCopyWithImpl<_DeliveryPointsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryPointsState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&const DeepCollectionEquality().equals(other._deliveryPoints, _deliveryPoints));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,const DeepCollectionEquality().hash(_deliveryPoints));

@override
String toString() {
  return 'DeliveryPointsState(isLoading: $isLoading, deliveryPoints: $deliveryPoints)';
}


}

/// @nodoc
abstract mixin class _$DeliveryPointsStateCopyWith<$Res> implements $DeliveryPointsStateCopyWith<$Res> {
  factory _$DeliveryPointsStateCopyWith(_DeliveryPointsState value, $Res Function(_DeliveryPointsState) _then) = __$DeliveryPointsStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, List<DeliveryPointData> deliveryPoints
});




}
/// @nodoc
class __$DeliveryPointsStateCopyWithImpl<$Res>
    implements _$DeliveryPointsStateCopyWith<$Res> {
  __$DeliveryPointsStateCopyWithImpl(this._self, this._then);

  final _DeliveryPointsState _self;
  final $Res Function(_DeliveryPointsState) _then;

/// Create a copy of DeliveryPointsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? deliveryPoints = null,}) {
  return _then(_DeliveryPointsState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,deliveryPoints: null == deliveryPoints ? _self._deliveryPoints : deliveryPoints // ignore: cast_nullable_to_non_nullable
as List<DeliveryPointData>,
  ));
}


}

// dart format on
