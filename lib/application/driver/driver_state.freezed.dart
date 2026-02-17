// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DriverState {

 DeliveryResponse? get driverData;
/// Create a copy of DriverState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverStateCopyWith<DriverState> get copyWith => _$DriverStateCopyWithImpl<DriverState>(this as DriverState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverState&&(identical(other.driverData, driverData) || other.driverData == driverData));
}


@override
int get hashCode => Object.hash(runtimeType,driverData);

@override
String toString() {
  return 'DriverState(driverData: $driverData)';
}


}

/// @nodoc
abstract mixin class $DriverStateCopyWith<$Res>  {
  factory $DriverStateCopyWith(DriverState value, $Res Function(DriverState) _then) = _$DriverStateCopyWithImpl;
@useResult
$Res call({
 DeliveryResponse? driverData
});




}
/// @nodoc
class _$DriverStateCopyWithImpl<$Res>
    implements $DriverStateCopyWith<$Res> {
  _$DriverStateCopyWithImpl(this._self, this._then);

  final DriverState _self;
  final $Res Function(DriverState) _then;

/// Create a copy of DriverState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? driverData = freezed,}) {
  return _then(_self.copyWith(
driverData: freezed == driverData ? _self.driverData : driverData // ignore: cast_nullable_to_non_nullable
as DeliveryResponse?,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverState].
extension DriverStatePatterns on DriverState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverState value)  $default,){
final _that = this;
switch (_that) {
case _DriverState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverState value)?  $default,){
final _that = this;
switch (_that) {
case _DriverState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DeliveryResponse? driverData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverState() when $default != null:
return $default(_that.driverData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DeliveryResponse? driverData)  $default,) {final _that = this;
switch (_that) {
case _DriverState():
return $default(_that.driverData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DeliveryResponse? driverData)?  $default,) {final _that = this;
switch (_that) {
case _DriverState() when $default != null:
return $default(_that.driverData);case _:
  return null;

}
}

}

/// @nodoc


class _DriverState extends DriverState {
  const _DriverState({this.driverData}): super._();
  

@override final  DeliveryResponse? driverData;

/// Create a copy of DriverState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverStateCopyWith<_DriverState> get copyWith => __$DriverStateCopyWithImpl<_DriverState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverState&&(identical(other.driverData, driverData) || other.driverData == driverData));
}


@override
int get hashCode => Object.hash(runtimeType,driverData);

@override
String toString() {
  return 'DriverState(driverData: $driverData)';
}


}

/// @nodoc
abstract mixin class _$DriverStateCopyWith<$Res> implements $DriverStateCopyWith<$Res> {
  factory _$DriverStateCopyWith(_DriverState value, $Res Function(_DriverState) _then) = __$DriverStateCopyWithImpl;
@override @useResult
$Res call({
 DeliveryResponse? driverData
});




}
/// @nodoc
class __$DriverStateCopyWithImpl<$Res>
    implements _$DriverStateCopyWith<$Res> {
  __$DriverStateCopyWithImpl(this._self, this._then);

  final _DriverState _self;
  final $Res Function(_DriverState) _then;

/// Create a copy of DriverState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? driverData = freezed,}) {
  return _then(_DriverState(
driverData: freezed == driverData ? _self.driverData : driverData // ignore: cast_nullable_to_non_nullable
as DeliveryResponse?,
  ));
}


}

// dart format on
