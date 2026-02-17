// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_edit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfileEditState {

 bool get isLoading; bool get isEmailEditable; bool get isPhoneEditable; bool get isFirstnameError; bool get isLastnameError; bool get isPasswordError; bool get isConfirmPasswordError; bool get showPassword; bool get showConfirmPassword; String get firstname; String get lastname; String get phone; String get email; String get password; String get confirmPassword;
/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileEditStateCopyWith<ProfileEditState> get copyWith => _$ProfileEditStateCopyWithImpl<ProfileEditState>(this as ProfileEditState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileEditState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isEmailEditable, isEmailEditable) || other.isEmailEditable == isEmailEditable)&&(identical(other.isPhoneEditable, isPhoneEditable) || other.isPhoneEditable == isPhoneEditable)&&(identical(other.isFirstnameError, isFirstnameError) || other.isFirstnameError == isFirstnameError)&&(identical(other.isLastnameError, isLastnameError) || other.isLastnameError == isLastnameError)&&(identical(other.isPasswordError, isPasswordError) || other.isPasswordError == isPasswordError)&&(identical(other.isConfirmPasswordError, isConfirmPasswordError) || other.isConfirmPasswordError == isConfirmPasswordError)&&(identical(other.showPassword, showPassword) || other.showPassword == showPassword)&&(identical(other.showConfirmPassword, showConfirmPassword) || other.showConfirmPassword == showConfirmPassword)&&(identical(other.firstname, firstname) || other.firstname == firstname)&&(identical(other.lastname, lastname) || other.lastname == lastname)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isEmailEditable,isPhoneEditable,isFirstnameError,isLastnameError,isPasswordError,isConfirmPasswordError,showPassword,showConfirmPassword,firstname,lastname,phone,email,password,confirmPassword);

@override
String toString() {
  return 'ProfileEditState(isLoading: $isLoading, isEmailEditable: $isEmailEditable, isPhoneEditable: $isPhoneEditable, isFirstnameError: $isFirstnameError, isLastnameError: $isLastnameError, isPasswordError: $isPasswordError, isConfirmPasswordError: $isConfirmPasswordError, showPassword: $showPassword, showConfirmPassword: $showConfirmPassword, firstname: $firstname, lastname: $lastname, phone: $phone, email: $email, password: $password, confirmPassword: $confirmPassword)';
}


}

/// @nodoc
abstract mixin class $ProfileEditStateCopyWith<$Res>  {
  factory $ProfileEditStateCopyWith(ProfileEditState value, $Res Function(ProfileEditState) _then) = _$ProfileEditStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isEmailEditable, bool isPhoneEditable, bool isFirstnameError, bool isLastnameError, bool isPasswordError, bool isConfirmPasswordError, bool showPassword, bool showConfirmPassword, String firstname, String lastname, String phone, String email, String password, String confirmPassword
});




}
/// @nodoc
class _$ProfileEditStateCopyWithImpl<$Res>
    implements $ProfileEditStateCopyWith<$Res> {
  _$ProfileEditStateCopyWithImpl(this._self, this._then);

  final ProfileEditState _self;
  final $Res Function(ProfileEditState) _then;

/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isEmailEditable = null,Object? isPhoneEditable = null,Object? isFirstnameError = null,Object? isLastnameError = null,Object? isPasswordError = null,Object? isConfirmPasswordError = null,Object? showPassword = null,Object? showConfirmPassword = null,Object? firstname = null,Object? lastname = null,Object? phone = null,Object? email = null,Object? password = null,Object? confirmPassword = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isEmailEditable: null == isEmailEditable ? _self.isEmailEditable : isEmailEditable // ignore: cast_nullable_to_non_nullable
as bool,isPhoneEditable: null == isPhoneEditable ? _self.isPhoneEditable : isPhoneEditable // ignore: cast_nullable_to_non_nullable
as bool,isFirstnameError: null == isFirstnameError ? _self.isFirstnameError : isFirstnameError // ignore: cast_nullable_to_non_nullable
as bool,isLastnameError: null == isLastnameError ? _self.isLastnameError : isLastnameError // ignore: cast_nullable_to_non_nullable
as bool,isPasswordError: null == isPasswordError ? _self.isPasswordError : isPasswordError // ignore: cast_nullable_to_non_nullable
as bool,isConfirmPasswordError: null == isConfirmPasswordError ? _self.isConfirmPasswordError : isConfirmPasswordError // ignore: cast_nullable_to_non_nullable
as bool,showPassword: null == showPassword ? _self.showPassword : showPassword // ignore: cast_nullable_to_non_nullable
as bool,showConfirmPassword: null == showConfirmPassword ? _self.showConfirmPassword : showConfirmPassword // ignore: cast_nullable_to_non_nullable
as bool,firstname: null == firstname ? _self.firstname : firstname // ignore: cast_nullable_to_non_nullable
as String,lastname: null == lastname ? _self.lastname : lastname // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileEditState].
extension ProfileEditStatePatterns on ProfileEditState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileEditState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileEditState value)  $default,){
final _that = this;
switch (_that) {
case _ProfileEditState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileEditState value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isEmailEditable,  bool isPhoneEditable,  bool isFirstnameError,  bool isLastnameError,  bool isPasswordError,  bool isConfirmPasswordError,  bool showPassword,  bool showConfirmPassword,  String firstname,  String lastname,  String phone,  String email,  String password,  String confirmPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
return $default(_that.isLoading,_that.isEmailEditable,_that.isPhoneEditable,_that.isFirstnameError,_that.isLastnameError,_that.isPasswordError,_that.isConfirmPasswordError,_that.showPassword,_that.showConfirmPassword,_that.firstname,_that.lastname,_that.phone,_that.email,_that.password,_that.confirmPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isEmailEditable,  bool isPhoneEditable,  bool isFirstnameError,  bool isLastnameError,  bool isPasswordError,  bool isConfirmPasswordError,  bool showPassword,  bool showConfirmPassword,  String firstname,  String lastname,  String phone,  String email,  String password,  String confirmPassword)  $default,) {final _that = this;
switch (_that) {
case _ProfileEditState():
return $default(_that.isLoading,_that.isEmailEditable,_that.isPhoneEditable,_that.isFirstnameError,_that.isLastnameError,_that.isPasswordError,_that.isConfirmPasswordError,_that.showPassword,_that.showConfirmPassword,_that.firstname,_that.lastname,_that.phone,_that.email,_that.password,_that.confirmPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isEmailEditable,  bool isPhoneEditable,  bool isFirstnameError,  bool isLastnameError,  bool isPasswordError,  bool isConfirmPasswordError,  bool showPassword,  bool showConfirmPassword,  String firstname,  String lastname,  String phone,  String email,  String password,  String confirmPassword)?  $default,) {final _that = this;
switch (_that) {
case _ProfileEditState() when $default != null:
return $default(_that.isLoading,_that.isEmailEditable,_that.isPhoneEditable,_that.isFirstnameError,_that.isLastnameError,_that.isPasswordError,_that.isConfirmPasswordError,_that.showPassword,_that.showConfirmPassword,_that.firstname,_that.lastname,_that.phone,_that.email,_that.password,_that.confirmPassword);case _:
  return null;

}
}

}

/// @nodoc


class _ProfileEditState extends ProfileEditState {
  const _ProfileEditState({this.isLoading = false, this.isEmailEditable = true, this.isPhoneEditable = true, this.isFirstnameError = false, this.isLastnameError = false, this.isPasswordError = false, this.isConfirmPasswordError = false, this.showPassword = false, this.showConfirmPassword = false, this.firstname = '', this.lastname = '', this.phone = '', this.email = '', this.password = '', this.confirmPassword = ''}): super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isEmailEditable;
@override@JsonKey() final  bool isPhoneEditable;
@override@JsonKey() final  bool isFirstnameError;
@override@JsonKey() final  bool isLastnameError;
@override@JsonKey() final  bool isPasswordError;
@override@JsonKey() final  bool isConfirmPasswordError;
@override@JsonKey() final  bool showPassword;
@override@JsonKey() final  bool showConfirmPassword;
@override@JsonKey() final  String firstname;
@override@JsonKey() final  String lastname;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String email;
@override@JsonKey() final  String password;
@override@JsonKey() final  String confirmPassword;

/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileEditStateCopyWith<_ProfileEditState> get copyWith => __$ProfileEditStateCopyWithImpl<_ProfileEditState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileEditState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isEmailEditable, isEmailEditable) || other.isEmailEditable == isEmailEditable)&&(identical(other.isPhoneEditable, isPhoneEditable) || other.isPhoneEditable == isPhoneEditable)&&(identical(other.isFirstnameError, isFirstnameError) || other.isFirstnameError == isFirstnameError)&&(identical(other.isLastnameError, isLastnameError) || other.isLastnameError == isLastnameError)&&(identical(other.isPasswordError, isPasswordError) || other.isPasswordError == isPasswordError)&&(identical(other.isConfirmPasswordError, isConfirmPasswordError) || other.isConfirmPasswordError == isConfirmPasswordError)&&(identical(other.showPassword, showPassword) || other.showPassword == showPassword)&&(identical(other.showConfirmPassword, showConfirmPassword) || other.showConfirmPassword == showConfirmPassword)&&(identical(other.firstname, firstname) || other.firstname == firstname)&&(identical(other.lastname, lastname) || other.lastname == lastname)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isEmailEditable,isPhoneEditable,isFirstnameError,isLastnameError,isPasswordError,isConfirmPasswordError,showPassword,showConfirmPassword,firstname,lastname,phone,email,password,confirmPassword);

@override
String toString() {
  return 'ProfileEditState(isLoading: $isLoading, isEmailEditable: $isEmailEditable, isPhoneEditable: $isPhoneEditable, isFirstnameError: $isFirstnameError, isLastnameError: $isLastnameError, isPasswordError: $isPasswordError, isConfirmPasswordError: $isConfirmPasswordError, showPassword: $showPassword, showConfirmPassword: $showConfirmPassword, firstname: $firstname, lastname: $lastname, phone: $phone, email: $email, password: $password, confirmPassword: $confirmPassword)';
}


}

/// @nodoc
abstract mixin class _$ProfileEditStateCopyWith<$Res> implements $ProfileEditStateCopyWith<$Res> {
  factory _$ProfileEditStateCopyWith(_ProfileEditState value, $Res Function(_ProfileEditState) _then) = __$ProfileEditStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isEmailEditable, bool isPhoneEditable, bool isFirstnameError, bool isLastnameError, bool isPasswordError, bool isConfirmPasswordError, bool showPassword, bool showConfirmPassword, String firstname, String lastname, String phone, String email, String password, String confirmPassword
});




}
/// @nodoc
class __$ProfileEditStateCopyWithImpl<$Res>
    implements _$ProfileEditStateCopyWith<$Res> {
  __$ProfileEditStateCopyWithImpl(this._self, this._then);

  final _ProfileEditState _self;
  final $Res Function(_ProfileEditState) _then;

/// Create a copy of ProfileEditState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isEmailEditable = null,Object? isPhoneEditable = null,Object? isFirstnameError = null,Object? isLastnameError = null,Object? isPasswordError = null,Object? isConfirmPasswordError = null,Object? showPassword = null,Object? showConfirmPassword = null,Object? firstname = null,Object? lastname = null,Object? phone = null,Object? email = null,Object? password = null,Object? confirmPassword = null,}) {
  return _then(_ProfileEditState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isEmailEditable: null == isEmailEditable ? _self.isEmailEditable : isEmailEditable // ignore: cast_nullable_to_non_nullable
as bool,isPhoneEditable: null == isPhoneEditable ? _self.isPhoneEditable : isPhoneEditable // ignore: cast_nullable_to_non_nullable
as bool,isFirstnameError: null == isFirstnameError ? _self.isFirstnameError : isFirstnameError // ignore: cast_nullable_to_non_nullable
as bool,isLastnameError: null == isLastnameError ? _self.isLastnameError : isLastnameError // ignore: cast_nullable_to_non_nullable
as bool,isPasswordError: null == isPasswordError ? _self.isPasswordError : isPasswordError // ignore: cast_nullable_to_non_nullable
as bool,isConfirmPasswordError: null == isConfirmPasswordError ? _self.isConfirmPasswordError : isConfirmPasswordError // ignore: cast_nullable_to_non_nullable
as bool,showPassword: null == showPassword ? _self.showPassword : showPassword // ignore: cast_nullable_to_non_nullable
as bool,showConfirmPassword: null == showConfirmPassword ? _self.showConfirmPassword : showConfirmPassword // ignore: cast_nullable_to_non_nullable
as bool,firstname: null == firstname ? _self.firstname : firstname // ignore: cast_nullable_to_non_nullable
as String,lastname: null == lastname ? _self.lastname : lastname // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
