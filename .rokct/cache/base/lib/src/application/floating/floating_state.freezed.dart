// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'floating_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FloatingState {

 bool get isScrolling;
/// Create a copy of FloatingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FloatingStateCopyWith<FloatingState> get copyWith => _$FloatingStateCopyWithImpl<FloatingState>(this as FloatingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FloatingState&&(identical(other.isScrolling, isScrolling) || other.isScrolling == isScrolling));
}


@override
int get hashCode => Object.hash(runtimeType,isScrolling);

@override
String toString() {
  return 'FloatingState(isScrolling: $isScrolling)';
}


}

/// @nodoc
abstract mixin class $FloatingStateCopyWith<$Res>  {
  factory $FloatingStateCopyWith(FloatingState value, $Res Function(FloatingState) _then) = _$FloatingStateCopyWithImpl;
@useResult
$Res call({
 bool isScrolling
});




}
/// @nodoc
class _$FloatingStateCopyWithImpl<$Res>
    implements $FloatingStateCopyWith<$Res> {
  _$FloatingStateCopyWithImpl(this._self, this._then);

  final FloatingState _self;
  final $Res Function(FloatingState) _then;

/// Create a copy of FloatingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isScrolling = null,}) {
  return _then(_self.copyWith(
isScrolling: null == isScrolling ? _self.isScrolling : isScrolling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FloatingState].
extension FloatingStatePatterns on FloatingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FloatingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FloatingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FloatingState value)  $default,){
final _that = this;
switch (_that) {
case _FloatingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FloatingState value)?  $default,){
final _that = this;
switch (_that) {
case _FloatingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isScrolling)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FloatingState() when $default != null:
return $default(_that.isScrolling);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isScrolling)  $default,) {final _that = this;
switch (_that) {
case _FloatingState():
return $default(_that.isScrolling);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isScrolling)?  $default,) {final _that = this;
switch (_that) {
case _FloatingState() when $default != null:
return $default(_that.isScrolling);case _:
  return null;

}
}

}

/// @nodoc


class _FloatingState extends FloatingState {
  const _FloatingState({this.isScrolling = false}): super._();
  

@override@JsonKey() final  bool isScrolling;

/// Create a copy of FloatingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FloatingStateCopyWith<_FloatingState> get copyWith => __$FloatingStateCopyWithImpl<_FloatingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FloatingState&&(identical(other.isScrolling, isScrolling) || other.isScrolling == isScrolling));
}


@override
int get hashCode => Object.hash(runtimeType,isScrolling);

@override
String toString() {
  return 'FloatingState(isScrolling: $isScrolling)';
}


}

/// @nodoc
abstract mixin class _$FloatingStateCopyWith<$Res> implements $FloatingStateCopyWith<$Res> {
  factory _$FloatingStateCopyWith(_FloatingState value, $Res Function(_FloatingState) _then) = __$FloatingStateCopyWithImpl;
@override @useResult
$Res call({
 bool isScrolling
});




}
/// @nodoc
class __$FloatingStateCopyWithImpl<$Res>
    implements _$FloatingStateCopyWith<$Res> {
  __$FloatingStateCopyWithImpl(this._self, this._then);

  final _FloatingState _self;
  final $Res Function(_FloatingState) _then;

/// Create a copy of FloatingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isScrolling = null,}) {
  return _then(_FloatingState(
isScrolling: null == isScrolling ? _self.isScrolling : isScrolling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
