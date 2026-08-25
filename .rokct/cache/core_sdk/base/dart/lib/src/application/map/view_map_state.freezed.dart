// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'view_map_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ViewMapState {

 bool get isLoading; bool get isActive; AddressNewModel? get place; bool get isSetAddress; bool get isScrolling;
/// Create a copy of ViewMapState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ViewMapStateCopyWith<ViewMapState> get copyWith => _$ViewMapStateCopyWithImpl<ViewMapState>(this as ViewMapState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ViewMapState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.place, place) || other.place == place)&&(identical(other.isSetAddress, isSetAddress) || other.isSetAddress == isSetAddress)&&(identical(other.isScrolling, isScrolling) || other.isScrolling == isScrolling));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isActive,place,isSetAddress,isScrolling);

@override
String toString() {
  return 'ViewMapState(isLoading: $isLoading, isActive: $isActive, place: $place, isSetAddress: $isSetAddress, isScrolling: $isScrolling)';
}


}

/// @nodoc
abstract mixin class $ViewMapStateCopyWith<$Res>  {
  factory $ViewMapStateCopyWith(ViewMapState value, $Res Function(ViewMapState) _then) = _$ViewMapStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isActive, AddressNewModel? place, bool isSetAddress, bool isScrolling
});




}
/// @nodoc
class _$ViewMapStateCopyWithImpl<$Res>
    implements $ViewMapStateCopyWith<$Res> {
  _$ViewMapStateCopyWithImpl(this._self, this._then);

  final ViewMapState _self;
  final $Res Function(ViewMapState) _then;

/// Create a copy of ViewMapState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isActive = null,Object? place = freezed,Object? isSetAddress = null,Object? isScrolling = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as AddressNewModel?,isSetAddress: null == isSetAddress ? _self.isSetAddress : isSetAddress // ignore: cast_nullable_to_non_nullable
as bool,isScrolling: null == isScrolling ? _self.isScrolling : isScrolling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ViewMapState].
extension ViewMapStatePatterns on ViewMapState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ViewMapState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ViewMapState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ViewMapState value)  $default,){
final _that = this;
switch (_that) {
case _ViewMapState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ViewMapState value)?  $default,){
final _that = this;
switch (_that) {
case _ViewMapState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isActive,  AddressNewModel? place,  bool isSetAddress,  bool isScrolling)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ViewMapState() when $default != null:
return $default(_that.isLoading,_that.isActive,_that.place,_that.isSetAddress,_that.isScrolling);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isActive,  AddressNewModel? place,  bool isSetAddress,  bool isScrolling)  $default,) {final _that = this;
switch (_that) {
case _ViewMapState():
return $default(_that.isLoading,_that.isActive,_that.place,_that.isSetAddress,_that.isScrolling);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isActive,  AddressNewModel? place,  bool isSetAddress,  bool isScrolling)?  $default,) {final _that = this;
switch (_that) {
case _ViewMapState() when $default != null:
return $default(_that.isLoading,_that.isActive,_that.place,_that.isSetAddress,_that.isScrolling);case _:
  return null;

}
}

}

/// @nodoc


class _ViewMapState extends ViewMapState {
  const _ViewMapState({this.isLoading = false, this.isActive = false, this.place = null, this.isSetAddress = false, this.isScrolling = false}): super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  AddressNewModel? place;
@override@JsonKey() final  bool isSetAddress;
@override@JsonKey() final  bool isScrolling;

/// Create a copy of ViewMapState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ViewMapStateCopyWith<_ViewMapState> get copyWith => __$ViewMapStateCopyWithImpl<_ViewMapState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ViewMapState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.place, place) || other.place == place)&&(identical(other.isSetAddress, isSetAddress) || other.isSetAddress == isSetAddress)&&(identical(other.isScrolling, isScrolling) || other.isScrolling == isScrolling));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isActive,place,isSetAddress,isScrolling);

@override
String toString() {
  return 'ViewMapState(isLoading: $isLoading, isActive: $isActive, place: $place, isSetAddress: $isSetAddress, isScrolling: $isScrolling)';
}


}

/// @nodoc
abstract mixin class _$ViewMapStateCopyWith<$Res> implements $ViewMapStateCopyWith<$Res> {
  factory _$ViewMapStateCopyWith(_ViewMapState value, $Res Function(_ViewMapState) _then) = __$ViewMapStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isActive, AddressNewModel? place, bool isSetAddress, bool isScrolling
});




}
/// @nodoc
class __$ViewMapStateCopyWithImpl<$Res>
    implements _$ViewMapStateCopyWith<$Res> {
  __$ViewMapStateCopyWithImpl(this._self, this._then);

  final _ViewMapState _self;
  final $Res Function(_ViewMapState) _then;

/// Create a copy of ViewMapState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isActive = null,Object? place = freezed,Object? isSetAddress = null,Object? isScrolling = null,}) {
  return _then(_ViewMapState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as AddressNewModel?,isSetAddress: null == isSetAddress ? _self.isSetAddress : isSetAddress // ignore: cast_nullable_to_non_nullable
as bool,isScrolling: null == isScrolling ? _self.isScrolling : isScrolling // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
