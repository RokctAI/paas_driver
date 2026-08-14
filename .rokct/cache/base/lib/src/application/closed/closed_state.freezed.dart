// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'closed_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ClosedState {

 int get currentIndex;
/// Create a copy of ClosedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClosedStateCopyWith<ClosedState> get copyWith => _$ClosedStateCopyWithImpl<ClosedState>(this as ClosedState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClosedState&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentIndex);

@override
String toString() {
  return 'ClosedState(currentIndex: $currentIndex)';
}


}

/// @nodoc
abstract mixin class $ClosedStateCopyWith<$Res>  {
  factory $ClosedStateCopyWith(ClosedState value, $Res Function(ClosedState) _then) = _$ClosedStateCopyWithImpl;
@useResult
$Res call({
 int currentIndex
});




}
/// @nodoc
class _$ClosedStateCopyWithImpl<$Res>
    implements $ClosedStateCopyWith<$Res> {
  _$ClosedStateCopyWithImpl(this._self, this._then);

  final ClosedState _self;
  final $Res Function(ClosedState) _then;

/// Create a copy of ClosedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentIndex = null,}) {
  return _then(_self.copyWith(
currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ClosedState].
extension ClosedStatePatterns on ClosedState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClosedState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClosedState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClosedState value)  $default,){
final _that = this;
switch (_that) {
case _ClosedState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClosedState value)?  $default,){
final _that = this;
switch (_that) {
case _ClosedState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClosedState() when $default != null:
return $default(_that.currentIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentIndex)  $default,) {final _that = this;
switch (_that) {
case _ClosedState():
return $default(_that.currentIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentIndex)?  $default,) {final _that = this;
switch (_that) {
case _ClosedState() when $default != null:
return $default(_that.currentIndex);case _:
  return null;

}
}

}

/// @nodoc


class _ClosedState extends ClosedState {
  const _ClosedState({this.currentIndex = 0}): super._();
  

@override@JsonKey() final  int currentIndex;

/// Create a copy of ClosedState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClosedStateCopyWith<_ClosedState> get copyWith => __$ClosedStateCopyWithImpl<_ClosedState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClosedState&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex));
}


@override
int get hashCode => Object.hash(runtimeType,currentIndex);

@override
String toString() {
  return 'ClosedState(currentIndex: $currentIndex)';
}


}

/// @nodoc
abstract mixin class _$ClosedStateCopyWith<$Res> implements $ClosedStateCopyWith<$Res> {
  factory _$ClosedStateCopyWith(_ClosedState value, $Res Function(_ClosedState) _then) = __$ClosedStateCopyWithImpl;
@override @useResult
$Res call({
 int currentIndex
});




}
/// @nodoc
class __$ClosedStateCopyWithImpl<$Res>
    implements _$ClosedStateCopyWith<$Res> {
  __$ClosedStateCopyWithImpl(this._self, this._then);

  final _ClosedState _self;
  final $Res Function(_ClosedState) _then;

/// Create a copy of ClosedState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentIndex = null,}) {
  return _then(_ClosedState(
currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
