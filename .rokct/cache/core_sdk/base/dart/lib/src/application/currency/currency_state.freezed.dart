// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'currency_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CurrencyState {

 List<CurrencyData> get list; bool get isLoading; int get index;
/// Create a copy of CurrencyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrencyStateCopyWith<CurrencyState> get copyWith => _$CurrencyStateCopyWithImpl<CurrencyState>(this as CurrencyState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrencyState&&const DeepCollectionEquality().equals(other.list, list)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(list),isLoading,index);

@override
String toString() {
  return 'CurrencyState(list: $list, isLoading: $isLoading, index: $index)';
}


}

/// @nodoc
abstract mixin class $CurrencyStateCopyWith<$Res>  {
  factory $CurrencyStateCopyWith(CurrencyState value, $Res Function(CurrencyState) _then) = _$CurrencyStateCopyWithImpl;
@useResult
$Res call({
 List<CurrencyData> list, bool isLoading, int index
});




}
/// @nodoc
class _$CurrencyStateCopyWithImpl<$Res>
    implements $CurrencyStateCopyWith<$Res> {
  _$CurrencyStateCopyWithImpl(this._self, this._then);

  final CurrencyState _self;
  final $Res Function(CurrencyState) _then;

/// Create a copy of CurrencyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? list = null,Object? isLoading = null,Object? index = null,}) {
  return _then(_self.copyWith(
list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<CurrencyData>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CurrencyState].
extension CurrencyStatePatterns on CurrencyState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurrencyState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurrencyState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurrencyState value)  $default,){
final _that = this;
switch (_that) {
case _CurrencyState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurrencyState value)?  $default,){
final _that = this;
switch (_that) {
case _CurrencyState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CurrencyData> list,  bool isLoading,  int index)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurrencyState() when $default != null:
return $default(_that.list,_that.isLoading,_that.index);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CurrencyData> list,  bool isLoading,  int index)  $default,) {final _that = this;
switch (_that) {
case _CurrencyState():
return $default(_that.list,_that.isLoading,_that.index);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CurrencyData> list,  bool isLoading,  int index)?  $default,) {final _that = this;
switch (_that) {
case _CurrencyState() when $default != null:
return $default(_that.list,_that.isLoading,_that.index);case _:
  return null;

}
}

}

/// @nodoc


class _CurrencyState extends CurrencyState {
  const _CurrencyState({final  List<CurrencyData> list = const [], this.isLoading = true, this.index = 0}): _list = list,super._();
  

 final  List<CurrencyData> _list;
@override@JsonKey() List<CurrencyData> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  int index;

/// Create a copy of CurrencyState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrencyStateCopyWith<_CurrencyState> get copyWith => __$CurrencyStateCopyWithImpl<_CurrencyState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurrencyState&&const DeepCollectionEquality().equals(other._list, _list)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_list),isLoading,index);

@override
String toString() {
  return 'CurrencyState(list: $list, isLoading: $isLoading, index: $index)';
}


}

/// @nodoc
abstract mixin class _$CurrencyStateCopyWith<$Res> implements $CurrencyStateCopyWith<$Res> {
  factory _$CurrencyStateCopyWith(_CurrencyState value, $Res Function(_CurrencyState) _then) = __$CurrencyStateCopyWithImpl;
@override @useResult
$Res call({
 List<CurrencyData> list, bool isLoading, int index
});




}
/// @nodoc
class __$CurrencyStateCopyWithImpl<$Res>
    implements _$CurrencyStateCopyWith<$Res> {
  __$CurrencyStateCopyWithImpl(this._self, this._then);

  final _CurrencyState _self;
  final $Res Function(_CurrencyState) _then;

/// Create a copy of CurrencyState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? list = null,Object? isLoading = null,Object? index = null,}) {
  return _then(_CurrencyState(
list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<CurrencyData>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
