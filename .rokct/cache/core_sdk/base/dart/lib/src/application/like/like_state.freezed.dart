// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'like_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LikeState {

 bool get isShopLoading; List<ShopData> get shops; int get likedShopsCount;
/// Create a copy of LikeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LikeStateCopyWith<LikeState> get copyWith => _$LikeStateCopyWithImpl<LikeState>(this as LikeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LikeState&&(identical(other.isShopLoading, isShopLoading) || other.isShopLoading == isShopLoading)&&const DeepCollectionEquality().equals(other.shops, shops)&&(identical(other.likedShopsCount, likedShopsCount) || other.likedShopsCount == likedShopsCount));
}


@override
int get hashCode => Object.hash(runtimeType,isShopLoading,const DeepCollectionEquality().hash(shops),likedShopsCount);

@override
String toString() {
  return 'LikeState(isShopLoading: $isShopLoading, shops: $shops, likedShopsCount: $likedShopsCount)';
}


}

/// @nodoc
abstract mixin class $LikeStateCopyWith<$Res>  {
  factory $LikeStateCopyWith(LikeState value, $Res Function(LikeState) _then) = _$LikeStateCopyWithImpl;
@useResult
$Res call({
 bool isShopLoading, List<ShopData> shops, int likedShopsCount
});




}
/// @nodoc
class _$LikeStateCopyWithImpl<$Res>
    implements $LikeStateCopyWith<$Res> {
  _$LikeStateCopyWithImpl(this._self, this._then);

  final LikeState _self;
  final $Res Function(LikeState) _then;

/// Create a copy of LikeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isShopLoading = null,Object? shops = null,Object? likedShopsCount = null,}) {
  return _then(_self.copyWith(
isShopLoading: null == isShopLoading ? _self.isShopLoading : isShopLoading // ignore: cast_nullable_to_non_nullable
as bool,shops: null == shops ? _self.shops : shops // ignore: cast_nullable_to_non_nullable
as List<ShopData>,likedShopsCount: null == likedShopsCount ? _self.likedShopsCount : likedShopsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LikeState].
extension LikeStatePatterns on LikeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LikeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LikeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LikeState value)  $default,){
final _that = this;
switch (_that) {
case _LikeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LikeState value)?  $default,){
final _that = this;
switch (_that) {
case _LikeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isShopLoading,  List<ShopData> shops,  int likedShopsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LikeState() when $default != null:
return $default(_that.isShopLoading,_that.shops,_that.likedShopsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isShopLoading,  List<ShopData> shops,  int likedShopsCount)  $default,) {final _that = this;
switch (_that) {
case _LikeState():
return $default(_that.isShopLoading,_that.shops,_that.likedShopsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isShopLoading,  List<ShopData> shops,  int likedShopsCount)?  $default,) {final _that = this;
switch (_that) {
case _LikeState() when $default != null:
return $default(_that.isShopLoading,_that.shops,_that.likedShopsCount);case _:
  return null;

}
}

}

/// @nodoc


class _LikeState extends LikeState {
  const _LikeState({this.isShopLoading = true, final  List<ShopData> shops = const [], this.likedShopsCount = 0}): _shops = shops,super._();
  

@override@JsonKey() final  bool isShopLoading;
 final  List<ShopData> _shops;
@override@JsonKey() List<ShopData> get shops {
  if (_shops is EqualUnmodifiableListView) return _shops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shops);
}

@override@JsonKey() final  int likedShopsCount;

/// Create a copy of LikeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LikeStateCopyWith<_LikeState> get copyWith => __$LikeStateCopyWithImpl<_LikeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LikeState&&(identical(other.isShopLoading, isShopLoading) || other.isShopLoading == isShopLoading)&&const DeepCollectionEquality().equals(other._shops, _shops)&&(identical(other.likedShopsCount, likedShopsCount) || other.likedShopsCount == likedShopsCount));
}


@override
int get hashCode => Object.hash(runtimeType,isShopLoading,const DeepCollectionEquality().hash(_shops),likedShopsCount);

@override
String toString() {
  return 'LikeState(isShopLoading: $isShopLoading, shops: $shops, likedShopsCount: $likedShopsCount)';
}


}

/// @nodoc
abstract mixin class _$LikeStateCopyWith<$Res> implements $LikeStateCopyWith<$Res> {
  factory _$LikeStateCopyWith(_LikeState value, $Res Function(_LikeState) _then) = __$LikeStateCopyWithImpl;
@override @useResult
$Res call({
 bool isShopLoading, List<ShopData> shops, int likedShopsCount
});




}
/// @nodoc
class __$LikeStateCopyWithImpl<$Res>
    implements _$LikeStateCopyWith<$Res> {
  __$LikeStateCopyWithImpl(this._self, this._then);

  final _LikeState _self;
  final $Res Function(_LikeState) _then;

/// Create a copy of LikeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isShopLoading = null,Object? shops = null,Object? likedShopsCount = null,}) {
  return _then(_LikeState(
isShopLoading: null == isShopLoading ? _self.isShopLoading : isShopLoading // ignore: cast_nullable_to_non_nullable
as bool,shops: null == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<ShopData>,likedShopsCount: null == likedShopsCount ? _self.likedShopsCount : likedShopsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
