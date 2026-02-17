// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'register_confirmation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RegisterConfirmationState {

 bool get isLoading; bool get isSuccess; bool get isResetPasswordSuccess; bool get isResending; bool get isTimeExpired; bool get isCodeError; bool get isConfirm; String get confirmCode; String get verificationCode; String get timerText;
/// Create a copy of RegisterConfirmationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterConfirmationStateCopyWith<RegisterConfirmationState> get copyWith => _$RegisterConfirmationStateCopyWithImpl<RegisterConfirmationState>(this as RegisterConfirmationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterConfirmationState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isResetPasswordSuccess, isResetPasswordSuccess) || other.isResetPasswordSuccess == isResetPasswordSuccess)&&(identical(other.isResending, isResending) || other.isResending == isResending)&&(identical(other.isTimeExpired, isTimeExpired) || other.isTimeExpired == isTimeExpired)&&(identical(other.isCodeError, isCodeError) || other.isCodeError == isCodeError)&&(identical(other.isConfirm, isConfirm) || other.isConfirm == isConfirm)&&(identical(other.confirmCode, confirmCode) || other.confirmCode == confirmCode)&&(identical(other.verificationCode, verificationCode) || other.verificationCode == verificationCode)&&(identical(other.timerText, timerText) || other.timerText == timerText));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,isResetPasswordSuccess,isResending,isTimeExpired,isCodeError,isConfirm,confirmCode,verificationCode,timerText);

@override
String toString() {
  return 'RegisterConfirmationState(isLoading: $isLoading, isSuccess: $isSuccess, isResetPasswordSuccess: $isResetPasswordSuccess, isResending: $isResending, isTimeExpired: $isTimeExpired, isCodeError: $isCodeError, isConfirm: $isConfirm, confirmCode: $confirmCode, verificationCode: $verificationCode, timerText: $timerText)';
}


}

/// @nodoc
abstract mixin class $RegisterConfirmationStateCopyWith<$Res>  {
  factory $RegisterConfirmationStateCopyWith(RegisterConfirmationState value, $Res Function(RegisterConfirmationState) _then) = _$RegisterConfirmationStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isSuccess, bool isResetPasswordSuccess, bool isResending, bool isTimeExpired, bool isCodeError, bool isConfirm, String confirmCode, String verificationCode, String timerText
});




}
/// @nodoc
class _$RegisterConfirmationStateCopyWithImpl<$Res>
    implements $RegisterConfirmationStateCopyWith<$Res> {
  _$RegisterConfirmationStateCopyWithImpl(this._self, this._then);

  final RegisterConfirmationState _self;
  final $Res Function(RegisterConfirmationState) _then;

/// Create a copy of RegisterConfirmationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isSuccess = null,Object? isResetPasswordSuccess = null,Object? isResending = null,Object? isTimeExpired = null,Object? isCodeError = null,Object? isConfirm = null,Object? confirmCode = null,Object? verificationCode = null,Object? timerText = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isResetPasswordSuccess: null == isResetPasswordSuccess ? _self.isResetPasswordSuccess : isResetPasswordSuccess // ignore: cast_nullable_to_non_nullable
as bool,isResending: null == isResending ? _self.isResending : isResending // ignore: cast_nullable_to_non_nullable
as bool,isTimeExpired: null == isTimeExpired ? _self.isTimeExpired : isTimeExpired // ignore: cast_nullable_to_non_nullable
as bool,isCodeError: null == isCodeError ? _self.isCodeError : isCodeError // ignore: cast_nullable_to_non_nullable
as bool,isConfirm: null == isConfirm ? _self.isConfirm : isConfirm // ignore: cast_nullable_to_non_nullable
as bool,confirmCode: null == confirmCode ? _self.confirmCode : confirmCode // ignore: cast_nullable_to_non_nullable
as String,verificationCode: null == verificationCode ? _self.verificationCode : verificationCode // ignore: cast_nullable_to_non_nullable
as String,timerText: null == timerText ? _self.timerText : timerText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterConfirmationState].
extension RegisterConfirmationStatePatterns on RegisterConfirmationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterConfirmationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterConfirmationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterConfirmationState value)  $default,){
final _that = this;
switch (_that) {
case _RegisterConfirmationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterConfirmationState value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterConfirmationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  bool isResetPasswordSuccess,  bool isResending,  bool isTimeExpired,  bool isCodeError,  bool isConfirm,  String confirmCode,  String verificationCode,  String timerText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterConfirmationState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.isResetPasswordSuccess,_that.isResending,_that.isTimeExpired,_that.isCodeError,_that.isConfirm,_that.confirmCode,_that.verificationCode,_that.timerText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  bool isResetPasswordSuccess,  bool isResending,  bool isTimeExpired,  bool isCodeError,  bool isConfirm,  String confirmCode,  String verificationCode,  String timerText)  $default,) {final _that = this;
switch (_that) {
case _RegisterConfirmationState():
return $default(_that.isLoading,_that.isSuccess,_that.isResetPasswordSuccess,_that.isResending,_that.isTimeExpired,_that.isCodeError,_that.isConfirm,_that.confirmCode,_that.verificationCode,_that.timerText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isSuccess,  bool isResetPasswordSuccess,  bool isResending,  bool isTimeExpired,  bool isCodeError,  bool isConfirm,  String confirmCode,  String verificationCode,  String timerText)?  $default,) {final _that = this;
switch (_that) {
case _RegisterConfirmationState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.isResetPasswordSuccess,_that.isResending,_that.isTimeExpired,_that.isCodeError,_that.isConfirm,_that.confirmCode,_that.verificationCode,_that.timerText);case _:
  return null;

}
}

}

/// @nodoc


class _RegisterConfirmationState extends RegisterConfirmationState {
  const _RegisterConfirmationState({this.isLoading = false, this.isSuccess = false, this.isResetPasswordSuccess = false, this.isResending = false, this.isTimeExpired = false, this.isCodeError = false, this.isConfirm = false, this.confirmCode = '', this.verificationCode = '', this.timerText = '05:00'}): super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSuccess;
@override@JsonKey() final  bool isResetPasswordSuccess;
@override@JsonKey() final  bool isResending;
@override@JsonKey() final  bool isTimeExpired;
@override@JsonKey() final  bool isCodeError;
@override@JsonKey() final  bool isConfirm;
@override@JsonKey() final  String confirmCode;
@override@JsonKey() final  String verificationCode;
@override@JsonKey() final  String timerText;

/// Create a copy of RegisterConfirmationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterConfirmationStateCopyWith<_RegisterConfirmationState> get copyWith => __$RegisterConfirmationStateCopyWithImpl<_RegisterConfirmationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterConfirmationState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isResetPasswordSuccess, isResetPasswordSuccess) || other.isResetPasswordSuccess == isResetPasswordSuccess)&&(identical(other.isResending, isResending) || other.isResending == isResending)&&(identical(other.isTimeExpired, isTimeExpired) || other.isTimeExpired == isTimeExpired)&&(identical(other.isCodeError, isCodeError) || other.isCodeError == isCodeError)&&(identical(other.isConfirm, isConfirm) || other.isConfirm == isConfirm)&&(identical(other.confirmCode, confirmCode) || other.confirmCode == confirmCode)&&(identical(other.verificationCode, verificationCode) || other.verificationCode == verificationCode)&&(identical(other.timerText, timerText) || other.timerText == timerText));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,isResetPasswordSuccess,isResending,isTimeExpired,isCodeError,isConfirm,confirmCode,verificationCode,timerText);

@override
String toString() {
  return 'RegisterConfirmationState(isLoading: $isLoading, isSuccess: $isSuccess, isResetPasswordSuccess: $isResetPasswordSuccess, isResending: $isResending, isTimeExpired: $isTimeExpired, isCodeError: $isCodeError, isConfirm: $isConfirm, confirmCode: $confirmCode, verificationCode: $verificationCode, timerText: $timerText)';
}


}

/// @nodoc
abstract mixin class _$RegisterConfirmationStateCopyWith<$Res> implements $RegisterConfirmationStateCopyWith<$Res> {
  factory _$RegisterConfirmationStateCopyWith(_RegisterConfirmationState value, $Res Function(_RegisterConfirmationState) _then) = __$RegisterConfirmationStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isSuccess, bool isResetPasswordSuccess, bool isResending, bool isTimeExpired, bool isCodeError, bool isConfirm, String confirmCode, String verificationCode, String timerText
});




}
/// @nodoc
class __$RegisterConfirmationStateCopyWithImpl<$Res>
    implements _$RegisterConfirmationStateCopyWith<$Res> {
  __$RegisterConfirmationStateCopyWithImpl(this._self, this._then);

  final _RegisterConfirmationState _self;
  final $Res Function(_RegisterConfirmationState) _then;

/// Create a copy of RegisterConfirmationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isSuccess = null,Object? isResetPasswordSuccess = null,Object? isResending = null,Object? isTimeExpired = null,Object? isCodeError = null,Object? isConfirm = null,Object? confirmCode = null,Object? verificationCode = null,Object? timerText = null,}) {
  return _then(_RegisterConfirmationState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isResetPasswordSuccess: null == isResetPasswordSuccess ? _self.isResetPasswordSuccess : isResetPasswordSuccess // ignore: cast_nullable_to_non_nullable
as bool,isResending: null == isResending ? _self.isResending : isResending // ignore: cast_nullable_to_non_nullable
as bool,isTimeExpired: null == isTimeExpired ? _self.isTimeExpired : isTimeExpired // ignore: cast_nullable_to_non_nullable
as bool,isCodeError: null == isCodeError ? _self.isCodeError : isCodeError // ignore: cast_nullable_to_non_nullable
as bool,isConfirm: null == isConfirm ? _self.isConfirm : isConfirm // ignore: cast_nullable_to_non_nullable
as bool,confirmCode: null == confirmCode ? _self.confirmCode : confirmCode // ignore: cast_nullable_to_non_nullable
as String,verificationCode: null == verificationCode ? _self.verificationCode : verificationCode // ignore: cast_nullable_to_non_nullable
as String,timerText: null == timerText ? _self.timerText : timerText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
