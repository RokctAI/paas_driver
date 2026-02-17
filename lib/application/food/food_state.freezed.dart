// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'food_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FoodState {

 bool get toggle; int get timeIndex;
/// Create a copy of FoodState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FoodStateCopyWith<FoodState> get copyWith => _$FoodStateCopyWithImpl<FoodState>(this as FoodState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FoodState&&(identical(other.toggle, toggle) || other.toggle == toggle)&&(identical(other.timeIndex, timeIndex) || other.timeIndex == timeIndex));
}


@override
int get hashCode => Object.hash(runtimeType,toggle,timeIndex);

@override
String toString() {
  return 'FoodState(toggle: $toggle, timeIndex: $timeIndex)';
}


}

/// @nodoc
abstract mixin class $FoodStateCopyWith<$Res>  {
  factory $FoodStateCopyWith(FoodState value, $Res Function(FoodState) _then) = _$FoodStateCopyWithImpl;
@useResult
$Res call({
 bool toggle, int timeIndex
});




}
/// @nodoc
class _$FoodStateCopyWithImpl<$Res>
    implements $FoodStateCopyWith<$Res> {
  _$FoodStateCopyWithImpl(this._self, this._then);

  final FoodState _self;
  final $Res Function(FoodState) _then;

/// Create a copy of FoodState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? toggle = null,Object? timeIndex = null,}) {
  return _then(_self.copyWith(
toggle: null == toggle ? _self.toggle : toggle // ignore: cast_nullable_to_non_nullable
as bool,timeIndex: null == timeIndex ? _self.timeIndex : timeIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FoodState].
extension FoodStatePatterns on FoodState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FoodState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FoodState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FoodState value)  $default,){
final _that = this;
switch (_that) {
case _FoodState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FoodState value)?  $default,){
final _that = this;
switch (_that) {
case _FoodState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool toggle,  int timeIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FoodState() when $default != null:
return $default(_that.toggle,_that.timeIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool toggle,  int timeIndex)  $default,) {final _that = this;
switch (_that) {
case _FoodState():
return $default(_that.toggle,_that.timeIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool toggle,  int timeIndex)?  $default,) {final _that = this;
switch (_that) {
case _FoodState() when $default != null:
return $default(_that.toggle,_that.timeIndex);case _:
  return null;

}
}

}

/// @nodoc


class _FoodState extends FoodState {
  const _FoodState({this.toggle = true, this.timeIndex = 0}): super._();
  

@override@JsonKey() final  bool toggle;
@override@JsonKey() final  int timeIndex;

/// Create a copy of FoodState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FoodStateCopyWith<_FoodState> get copyWith => __$FoodStateCopyWithImpl<_FoodState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FoodState&&(identical(other.toggle, toggle) || other.toggle == toggle)&&(identical(other.timeIndex, timeIndex) || other.timeIndex == timeIndex));
}


@override
int get hashCode => Object.hash(runtimeType,toggle,timeIndex);

@override
String toString() {
  return 'FoodState(toggle: $toggle, timeIndex: $timeIndex)';
}


}

/// @nodoc
abstract mixin class _$FoodStateCopyWith<$Res> implements $FoodStateCopyWith<$Res> {
  factory _$FoodStateCopyWith(_FoodState value, $Res Function(_FoodState) _then) = __$FoodStateCopyWithImpl;
@override @useResult
$Res call({
 bool toggle, int timeIndex
});




}
/// @nodoc
class __$FoodStateCopyWithImpl<$Res>
    implements _$FoodStateCopyWith<$Res> {
  __$FoodStateCopyWithImpl(this._self, this._then);

  final _FoodState _self;
  final $Res Function(_FoodState) _then;

/// Create a copy of FoodState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? toggle = null,Object? timeIndex = null,}) {
  return _then(_FoodState(
toggle: null == toggle ? _self.toggle : toggle // ignore: cast_nullable_to_non_nullable
as bool,timeIndex: null == timeIndex ? _self.timeIndex : timeIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
