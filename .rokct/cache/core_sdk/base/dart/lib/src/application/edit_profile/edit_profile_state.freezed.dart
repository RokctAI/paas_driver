// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_profile_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditProfileState {

 bool get isLoading; bool get checked; bool get isSuccess; String get email; String get firstName; String get lastName; String get phone; String get secondPhone; String get birth; String get gender; String get url; String get imagePath; ProfileData? get userData;
/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditProfileStateCopyWith<EditProfileState> get copyWith => _$EditProfileStateCopyWithImpl<EditProfileState>(this as EditProfileState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditProfileState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.secondPhone, secondPhone) || other.secondPhone == secondPhone)&&(identical(other.birth, birth) || other.birth == birth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.url, url) || other.url == url)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.userData, userData) || other.userData == userData));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,checked,isSuccess,email,firstName,lastName,phone,secondPhone,birth,gender,url,imagePath,userData);

@override
String toString() {
  return 'EditProfileState(isLoading: $isLoading, checked: $checked, isSuccess: $isSuccess, email: $email, firstName: $firstName, lastName: $lastName, phone: $phone, secondPhone: $secondPhone, birth: $birth, gender: $gender, url: $url, imagePath: $imagePath, userData: $userData)';
}


}

/// @nodoc
abstract mixin class $EditProfileStateCopyWith<$Res>  {
  factory $EditProfileStateCopyWith(EditProfileState value, $Res Function(EditProfileState) _then) = _$EditProfileStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool checked, bool isSuccess, String email, String firstName, String lastName, String phone, String secondPhone, String birth, String gender, String url, String imagePath, ProfileData? userData
});




}
/// @nodoc
class _$EditProfileStateCopyWithImpl<$Res>
    implements $EditProfileStateCopyWith<$Res> {
  _$EditProfileStateCopyWithImpl(this._self, this._then);

  final EditProfileState _self;
  final $Res Function(EditProfileState) _then;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? checked = null,Object? isSuccess = null,Object? email = null,Object? firstName = null,Object? lastName = null,Object? phone = null,Object? secondPhone = null,Object? birth = null,Object? gender = null,Object? url = null,Object? imagePath = null,Object? userData = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,secondPhone: null == secondPhone ? _self.secondPhone : secondPhone // ignore: cast_nullable_to_non_nullable
as String,birth: null == birth ? _self.birth : birth // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,userData: freezed == userData ? _self.userData : userData // ignore: cast_nullable_to_non_nullable
as ProfileData?,
  ));
}

}


/// Adds pattern-matching-related methods to [EditProfileState].
extension EditProfileStatePatterns on EditProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditProfileState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditProfileState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditProfileState value)  $default,){
final _that = this;
switch (_that) {
case _EditProfileState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditProfileState value)?  $default,){
final _that = this;
switch (_that) {
case _EditProfileState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool checked,  bool isSuccess,  String email,  String firstName,  String lastName,  String phone,  String secondPhone,  String birth,  String gender,  String url,  String imagePath,  ProfileData? userData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditProfileState() when $default != null:
return $default(_that.isLoading,_that.checked,_that.isSuccess,_that.email,_that.firstName,_that.lastName,_that.phone,_that.secondPhone,_that.birth,_that.gender,_that.url,_that.imagePath,_that.userData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool checked,  bool isSuccess,  String email,  String firstName,  String lastName,  String phone,  String secondPhone,  String birth,  String gender,  String url,  String imagePath,  ProfileData? userData)  $default,) {final _that = this;
switch (_that) {
case _EditProfileState():
return $default(_that.isLoading,_that.checked,_that.isSuccess,_that.email,_that.firstName,_that.lastName,_that.phone,_that.secondPhone,_that.birth,_that.gender,_that.url,_that.imagePath,_that.userData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool checked,  bool isSuccess,  String email,  String firstName,  String lastName,  String phone,  String secondPhone,  String birth,  String gender,  String url,  String imagePath,  ProfileData? userData)?  $default,) {final _that = this;
switch (_that) {
case _EditProfileState() when $default != null:
return $default(_that.isLoading,_that.checked,_that.isSuccess,_that.email,_that.firstName,_that.lastName,_that.phone,_that.secondPhone,_that.birth,_that.gender,_that.url,_that.imagePath,_that.userData);case _:
  return null;

}
}

}

/// @nodoc


class _EditProfileState extends EditProfileState {
  const _EditProfileState({this.isLoading = false, this.checked = false, this.isSuccess = false, this.email = "", this.firstName = "", this.lastName = "", this.phone = "", this.secondPhone = "", this.birth = "", this.gender = "", this.url = "", this.imagePath = "", this.userData = null}): super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool checked;
@override@JsonKey() final  bool isSuccess;
@override@JsonKey() final  String email;
@override@JsonKey() final  String firstName;
@override@JsonKey() final  String lastName;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String secondPhone;
@override@JsonKey() final  String birth;
@override@JsonKey() final  String gender;
@override@JsonKey() final  String url;
@override@JsonKey() final  String imagePath;
@override@JsonKey() final  ProfileData? userData;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditProfileStateCopyWith<_EditProfileState> get copyWith => __$EditProfileStateCopyWithImpl<_EditProfileState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditProfileState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.checked, checked) || other.checked == checked)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess)&&(identical(other.email, email) || other.email == email)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.secondPhone, secondPhone) || other.secondPhone == secondPhone)&&(identical(other.birth, birth) || other.birth == birth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.url, url) || other.url == url)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.userData, userData) || other.userData == userData));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,checked,isSuccess,email,firstName,lastName,phone,secondPhone,birth,gender,url,imagePath,userData);

@override
String toString() {
  return 'EditProfileState(isLoading: $isLoading, checked: $checked, isSuccess: $isSuccess, email: $email, firstName: $firstName, lastName: $lastName, phone: $phone, secondPhone: $secondPhone, birth: $birth, gender: $gender, url: $url, imagePath: $imagePath, userData: $userData)';
}


}

/// @nodoc
abstract mixin class _$EditProfileStateCopyWith<$Res> implements $EditProfileStateCopyWith<$Res> {
  factory _$EditProfileStateCopyWith(_EditProfileState value, $Res Function(_EditProfileState) _then) = __$EditProfileStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool checked, bool isSuccess, String email, String firstName, String lastName, String phone, String secondPhone, String birth, String gender, String url, String imagePath, ProfileData? userData
});




}
/// @nodoc
class __$EditProfileStateCopyWithImpl<$Res>
    implements _$EditProfileStateCopyWith<$Res> {
  __$EditProfileStateCopyWithImpl(this._self, this._then);

  final _EditProfileState _self;
  final $Res Function(_EditProfileState) _then;

/// Create a copy of EditProfileState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? checked = null,Object? isSuccess = null,Object? email = null,Object? firstName = null,Object? lastName = null,Object? phone = null,Object? secondPhone = null,Object? birth = null,Object? gender = null,Object? url = null,Object? imagePath = null,Object? userData = freezed,}) {
  return _then(_EditProfileState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,checked: null == checked ? _self.checked : checked // ignore: cast_nullable_to_non_nullable
as bool,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,secondPhone: null == secondPhone ? _self.secondPhone : secondPhone // ignore: cast_nullable_to_non_nullable
as String,birth: null == birth ? _self.birth : birth // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,userData: freezed == userData ? _self.userData : userData // ignore: cast_nullable_to_non_nullable
as ProfileData?,
  ));
}


}

// dart format on
