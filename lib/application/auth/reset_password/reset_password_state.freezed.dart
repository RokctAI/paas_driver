// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reset_password_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResetPasswordState {

 bool get isLoading; bool get isSuccess; bool get isEmailError; bool get isPasswordInvalid; bool get isConfirmPasswordInvalid; bool get showPassword; bool get showConfirmPassword; String get email; String get phone; String get verificationId; String get verifyId; String get password; String get confirmPassword;
/// Create a copy of ResetPasswordState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPasswordStateCopyWith<ResetPasswordState> get copyWith => _$ResetPasswordStateCopyWithImpl<ResetPasswordState>(this as ResetPasswordState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isEmailError, isEmailError) || other.isEmailError == isEmailError)&&(identical(other.isPasswordInvalid, isPasswordInvalid) || other.isPasswordInvalid == isPasswordInvalid)&&(identical(other.isConfirmPasswordInvalid, isConfirmPasswordInvalid) || other.isConfirmPasswordInvalid == isConfirmPasswordInvalid)&&(identical(other.showPassword, showPassword) || other.showPassword == showPassword)&&(identical(other.showConfirmPassword, showConfirmPassword) || other.showConfirmPassword == showConfirmPassword)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.verifyId, verifyId) || other.verifyId == verifyId)&&(identical(other.password, password) || other.password == password)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,isEmailError,isPasswordInvalid,isConfirmPasswordInvalid,showPassword,showConfirmPassword,email,phone,verificationId,verifyId,password,confirmPassword);

@override
String toString() {
  return 'ResetPasswordState(isLoading: $isLoading, isSuccess: $isSuccess, isEmailError: $isEmailError, isPasswordInvalid: $isPasswordInvalid, isConfirmPasswordInvalid: $isConfirmPasswordInvalid, showPassword: $showPassword, showConfirmPassword: $showConfirmPassword, email: $email, phone: $phone, verificationId: $verificationId, verifyId: $verifyId, password: $password, confirmPassword: $confirmPassword)';
}


}

/// @nodoc
abstract mixin class $ResetPasswordStateCopyWith<$Res>  {
  factory $ResetPasswordStateCopyWith(ResetPasswordState value, $Res Function(ResetPasswordState) _then) = _$ResetPasswordStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isSuccess, bool isEmailError, bool isPasswordInvalid, bool isConfirmPasswordInvalid, bool showPassword, bool showConfirmPassword, String email, String phone, String verificationId, String verifyId, String password, String confirmPassword
});




}
/// @nodoc
class _$ResetPasswordStateCopyWithImpl<$Res>
    implements $ResetPasswordStateCopyWith<$Res> {
  _$ResetPasswordStateCopyWithImpl(this._self, this._then);

  final ResetPasswordState _self;
  final $Res Function(ResetPasswordState) _then;

/// Create a copy of ResetPasswordState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isSuccess = null,Object? isEmailError = null,Object? isPasswordInvalid = null,Object? isConfirmPasswordInvalid = null,Object? showPassword = null,Object? showConfirmPassword = null,Object? email = null,Object? phone = null,Object? verificationId = null,Object? verifyId = null,Object? password = null,Object? confirmPassword = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isEmailError: null == isEmailError ? _self.isEmailError : isEmailError // ignore: cast_nullable_to_non_nullable
as bool,isPasswordInvalid: null == isPasswordInvalid ? _self.isPasswordInvalid : isPasswordInvalid // ignore: cast_nullable_to_non_nullable
as bool,isConfirmPasswordInvalid: null == isConfirmPasswordInvalid ? _self.isConfirmPasswordInvalid : isConfirmPasswordInvalid // ignore: cast_nullable_to_non_nullable
as bool,showPassword: null == showPassword ? _self.showPassword : showPassword // ignore: cast_nullable_to_non_nullable
as bool,showConfirmPassword: null == showConfirmPassword ? _self.showConfirmPassword : showConfirmPassword // ignore: cast_nullable_to_non_nullable
as bool,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,verifyId: null == verifyId ? _self.verifyId : verifyId // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ResetPasswordState].
extension ResetPasswordStatePatterns on ResetPasswordState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResetPasswordState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResetPasswordState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResetPasswordState value)  $default,){
final _that = this;
switch (_that) {
case _ResetPasswordState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResetPasswordState value)?  $default,){
final _that = this;
switch (_that) {
case _ResetPasswordState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  bool isEmailError,  bool isPasswordInvalid,  bool isConfirmPasswordInvalid,  bool showPassword,  bool showConfirmPassword,  String email,  String phone,  String verificationId,  String verifyId,  String password,  String confirmPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResetPasswordState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.isEmailError,_that.isPasswordInvalid,_that.isConfirmPasswordInvalid,_that.showPassword,_that.showConfirmPassword,_that.email,_that.phone,_that.verificationId,_that.verifyId,_that.password,_that.confirmPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isSuccess,  bool isEmailError,  bool isPasswordInvalid,  bool isConfirmPasswordInvalid,  bool showPassword,  bool showConfirmPassword,  String email,  String phone,  String verificationId,  String verifyId,  String password,  String confirmPassword)  $default,) {final _that = this;
switch (_that) {
case _ResetPasswordState():
return $default(_that.isLoading,_that.isSuccess,_that.isEmailError,_that.isPasswordInvalid,_that.isConfirmPasswordInvalid,_that.showPassword,_that.showConfirmPassword,_that.email,_that.phone,_that.verificationId,_that.verifyId,_that.password,_that.confirmPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isSuccess,  bool isEmailError,  bool isPasswordInvalid,  bool isConfirmPasswordInvalid,  bool showPassword,  bool showConfirmPassword,  String email,  String phone,  String verificationId,  String verifyId,  String password,  String confirmPassword)?  $default,) {final _that = this;
switch (_that) {
case _ResetPasswordState() when $default != null:
return $default(_that.isLoading,_that.isSuccess,_that.isEmailError,_that.isPasswordInvalid,_that.isConfirmPasswordInvalid,_that.showPassword,_that.showConfirmPassword,_that.email,_that.phone,_that.verificationId,_that.verifyId,_that.password,_that.confirmPassword);case _:
  return null;

}
}

}

/// @nodoc


class _ResetPasswordState extends ResetPasswordState {
  const _ResetPasswordState({this.isLoading = false, this.isSuccess = false, this.isEmailError = false, this.isPasswordInvalid = false, this.isConfirmPasswordInvalid = false, this.showPassword = false, this.showConfirmPassword = false, this.email = '', this.phone = '', this.verificationId = '', this.verifyId = '', this.password = '', this.confirmPassword = ''}): super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSuccess;
@override@JsonKey() final  bool isEmailError;
@override@JsonKey() final  bool isPasswordInvalid;
@override@JsonKey() final  bool isConfirmPasswordInvalid;
@override@JsonKey() final  bool showPassword;
@override@JsonKey() final  bool showConfirmPassword;
@override@JsonKey() final  String email;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String verificationId;
@override@JsonKey() final  String verifyId;
@override@JsonKey() final  String password;
@override@JsonKey() final  String confirmPassword;

/// Create a copy of ResetPasswordState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResetPasswordStateCopyWith<_ResetPasswordState> get copyWith => __$ResetPasswordStateCopyWithImpl<_ResetPasswordState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResetPasswordState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.isEmailError, isEmailError) || other.isEmailError == isEmailError)&&(identical(other.isPasswordInvalid, isPasswordInvalid) || other.isPasswordInvalid == isPasswordInvalid)&&(identical(other.isConfirmPasswordInvalid, isConfirmPasswordInvalid) || other.isConfirmPasswordInvalid == isConfirmPasswordInvalid)&&(identical(other.showPassword, showPassword) || other.showPassword == showPassword)&&(identical(other.showConfirmPassword, showConfirmPassword) || other.showConfirmPassword == showConfirmPassword)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.verificationId, verificationId) || other.verificationId == verificationId)&&(identical(other.verifyId, verifyId) || other.verifyId == verifyId)&&(identical(other.password, password) || other.password == password)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSuccess,isEmailError,isPasswordInvalid,isConfirmPasswordInvalid,showPassword,showConfirmPassword,email,phone,verificationId,verifyId,password,confirmPassword);

@override
String toString() {
  return 'ResetPasswordState(isLoading: $isLoading, isSuccess: $isSuccess, isEmailError: $isEmailError, isPasswordInvalid: $isPasswordInvalid, isConfirmPasswordInvalid: $isConfirmPasswordInvalid, showPassword: $showPassword, showConfirmPassword: $showConfirmPassword, email: $email, phone: $phone, verificationId: $verificationId, verifyId: $verifyId, password: $password, confirmPassword: $confirmPassword)';
}


}

/// @nodoc
abstract mixin class _$ResetPasswordStateCopyWith<$Res> implements $ResetPasswordStateCopyWith<$Res> {
  factory _$ResetPasswordStateCopyWith(_ResetPasswordState value, $Res Function(_ResetPasswordState) _then) = __$ResetPasswordStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isSuccess, bool isEmailError, bool isPasswordInvalid, bool isConfirmPasswordInvalid, bool showPassword, bool showConfirmPassword, String email, String phone, String verificationId, String verifyId, String password, String confirmPassword
});




}
/// @nodoc
class __$ResetPasswordStateCopyWithImpl<$Res>
    implements _$ResetPasswordStateCopyWith<$Res> {
  __$ResetPasswordStateCopyWithImpl(this._self, this._then);

  final _ResetPasswordState _self;
  final $Res Function(_ResetPasswordState) _then;

/// Create a copy of ResetPasswordState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isSuccess = null,Object? isEmailError = null,Object? isPasswordInvalid = null,Object? isConfirmPasswordInvalid = null,Object? showPassword = null,Object? showConfirmPassword = null,Object? email = null,Object? phone = null,Object? verificationId = null,Object? verifyId = null,Object? password = null,Object? confirmPassword = null,}) {
  return _then(_ResetPasswordState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,isEmailError: null == isEmailError ? _self.isEmailError : isEmailError // ignore: cast_nullable_to_non_nullable
as bool,isPasswordInvalid: null == isPasswordInvalid ? _self.isPasswordInvalid : isPasswordInvalid // ignore: cast_nullable_to_non_nullable
as bool,isConfirmPasswordInvalid: null == isConfirmPasswordInvalid ? _self.isConfirmPasswordInvalid : isConfirmPasswordInvalid // ignore: cast_nullable_to_non_nullable
as bool,showPassword: null == showPassword ? _self.showPassword : showPassword // ignore: cast_nullable_to_non_nullable
as bool,showConfirmPassword: null == showConfirmPassword ? _self.showConfirmPassword : showConfirmPassword // ignore: cast_nullable_to_non_nullable
as bool,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,verificationId: null == verificationId ? _self.verificationId : verificationId // ignore: cast_nullable_to_non_nullable
as String,verifyId: null == verifyId ? _self.verifyId : verifyId // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
