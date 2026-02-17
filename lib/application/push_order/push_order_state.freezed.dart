// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PushOrderState {

 bool get isTimeOut; bool get isLoading; String get timerText;
/// Create a copy of PushOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushOrderStateCopyWith<PushOrderState> get copyWith => _$PushOrderStateCopyWithImpl<PushOrderState>(this as PushOrderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushOrderState&&(identical(other.isTimeOut, isTimeOut) || other.isTimeOut == isTimeOut)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.timerText, timerText) || other.timerText == timerText));
}


@override
int get hashCode => Object.hash(runtimeType,isTimeOut,isLoading,timerText);

@override
String toString() {
  return 'PushOrderState(isTimeOut: $isTimeOut, isLoading: $isLoading, timerText: $timerText)';
}


}

/// @nodoc
abstract mixin class $PushOrderStateCopyWith<$Res>  {
  factory $PushOrderStateCopyWith(PushOrderState value, $Res Function(PushOrderState) _then) = _$PushOrderStateCopyWithImpl;
@useResult
$Res call({
 bool isTimeOut, bool isLoading, String timerText
});




}
/// @nodoc
class _$PushOrderStateCopyWithImpl<$Res>
    implements $PushOrderStateCopyWith<$Res> {
  _$PushOrderStateCopyWithImpl(this._self, this._then);

  final PushOrderState _self;
  final $Res Function(PushOrderState) _then;

/// Create a copy of PushOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isTimeOut = null,Object? isLoading = null,Object? timerText = null,}) {
  return _then(_self.copyWith(
isTimeOut: null == isTimeOut ? _self.isTimeOut : isTimeOut // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,timerText: null == timerText ? _self.timerText : timerText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PushOrderState].
extension PushOrderStatePatterns on PushOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PushOrderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PushOrderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PushOrderState value)  $default,){
final _that = this;
switch (_that) {
case _PushOrderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PushOrderState value)?  $default,){
final _that = this;
switch (_that) {
case _PushOrderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isTimeOut,  bool isLoading,  String timerText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PushOrderState() when $default != null:
return $default(_that.isTimeOut,_that.isLoading,_that.timerText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isTimeOut,  bool isLoading,  String timerText)  $default,) {final _that = this;
switch (_that) {
case _PushOrderState():
return $default(_that.isTimeOut,_that.isLoading,_that.timerText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isTimeOut,  bool isLoading,  String timerText)?  $default,) {final _that = this;
switch (_that) {
case _PushOrderState() when $default != null:
return $default(_that.isTimeOut,_that.isLoading,_that.timerText);case _:
  return null;

}
}

}

/// @nodoc


class _PushOrderState extends PushOrderState {
  const _PushOrderState({this.isTimeOut = false, this.isLoading = false, this.timerText = '0 s'}): super._();
  

@override@JsonKey() final  bool isTimeOut;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  String timerText;

/// Create a copy of PushOrderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushOrderStateCopyWith<_PushOrderState> get copyWith => __$PushOrderStateCopyWithImpl<_PushOrderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushOrderState&&(identical(other.isTimeOut, isTimeOut) || other.isTimeOut == isTimeOut)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.timerText, timerText) || other.timerText == timerText));
}


@override
int get hashCode => Object.hash(runtimeType,isTimeOut,isLoading,timerText);

@override
String toString() {
  return 'PushOrderState(isTimeOut: $isTimeOut, isLoading: $isLoading, timerText: $timerText)';
}


}

/// @nodoc
abstract mixin class _$PushOrderStateCopyWith<$Res> implements $PushOrderStateCopyWith<$Res> {
  factory _$PushOrderStateCopyWith(_PushOrderState value, $Res Function(_PushOrderState) _then) = __$PushOrderStateCopyWithImpl;
@override @useResult
$Res call({
 bool isTimeOut, bool isLoading, String timerText
});




}
/// @nodoc
class __$PushOrderStateCopyWithImpl<$Res>
    implements _$PushOrderStateCopyWith<$Res> {
  __$PushOrderStateCopyWithImpl(this._self, this._then);

  final _PushOrderState _self;
  final $Res Function(_PushOrderState) _then;

/// Create a copy of PushOrderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isTimeOut = null,Object? isLoading = null,Object? timerText = null,}) {
  return _then(_PushOrderState(
isTimeOut: null == isTimeOut ? _self.isTimeOut : isTimeOut // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,timerText: null == timerText ? _self.timerText : timerText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
