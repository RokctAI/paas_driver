// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promo_code_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PromoCodeState {

 bool get isActive; bool get isLoading;
/// Create a copy of PromoCodeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromoCodeStateCopyWith<PromoCodeState> get copyWith => _$PromoCodeStateCopyWithImpl<PromoCodeState>(this as PromoCodeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromoCodeState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,isActive,isLoading);

@override
String toString() {
  return 'PromoCodeState(isActive: $isActive, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $PromoCodeStateCopyWith<$Res>  {
  factory $PromoCodeStateCopyWith(PromoCodeState value, $Res Function(PromoCodeState) _then) = _$PromoCodeStateCopyWithImpl;
@useResult
$Res call({
 bool isActive, bool isLoading
});




}
/// @nodoc
class _$PromoCodeStateCopyWithImpl<$Res>
    implements $PromoCodeStateCopyWith<$Res> {
  _$PromoCodeStateCopyWithImpl(this._self, this._then);

  final PromoCodeState _self;
  final $Res Function(PromoCodeState) _then;

/// Create a copy of PromoCodeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isActive = null,Object? isLoading = null,}) {
  return _then(_self.copyWith(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PromoCodeState].
extension PromoCodeStatePatterns on PromoCodeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromoCodeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromoCodeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromoCodeState value)  $default,){
final _that = this;
switch (_that) {
case _PromoCodeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromoCodeState value)?  $default,){
final _that = this;
switch (_that) {
case _PromoCodeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActive,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromoCodeState() when $default != null:
return $default(_that.isActive,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActive,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _PromoCodeState():
return $default(_that.isActive,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActive,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _PromoCodeState() when $default != null:
return $default(_that.isActive,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _PromoCodeState extends PromoCodeState {
  const _PromoCodeState({this.isActive = false, this.isLoading = false}): super._();
  

@override@JsonKey() final  bool isActive;
@override@JsonKey() final  bool isLoading;

/// Create a copy of PromoCodeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromoCodeStateCopyWith<_PromoCodeState> get copyWith => __$PromoCodeStateCopyWithImpl<_PromoCodeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromoCodeState&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,isActive,isLoading);

@override
String toString() {
  return 'PromoCodeState(isActive: $isActive, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$PromoCodeStateCopyWith<$Res> implements $PromoCodeStateCopyWith<$Res> {
  factory _$PromoCodeStateCopyWith(_PromoCodeState value, $Res Function(_PromoCodeState) _then) = __$PromoCodeStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActive, bool isLoading
});




}
/// @nodoc
class __$PromoCodeStateCopyWithImpl<$Res>
    implements _$PromoCodeStateCopyWith<$Res> {
  __$PromoCodeStateCopyWithImpl(this._self, this._then);

  final _PromoCodeState _self;
  final $Res Function(_PromoCodeState) _then;

/// Create a copy of PromoCodeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isActive = null,Object? isLoading = null,}) {
  return _then(_PromoCodeState(
isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
