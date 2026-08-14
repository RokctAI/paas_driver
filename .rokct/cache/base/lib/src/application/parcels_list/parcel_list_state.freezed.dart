// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parcel_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ParcelListState {

 bool get isActiveLoading; bool get isHistoryLoading; int get totalActiveCount; List<ParcelOrder> get activeOrders; List<ParcelOrder> get historyOrders;
/// Create a copy of ParcelListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParcelListStateCopyWith<ParcelListState> get copyWith => _$ParcelListStateCopyWithImpl<ParcelListState>(this as ParcelListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParcelListState&&(identical(other.isActiveLoading, isActiveLoading) || other.isActiveLoading == isActiveLoading)&&(identical(other.isHistoryLoading, isHistoryLoading) || other.isHistoryLoading == isHistoryLoading)&&(identical(other.totalActiveCount, totalActiveCount) || other.totalActiveCount == totalActiveCount)&&const DeepCollectionEquality().equals(other.activeOrders, activeOrders)&&const DeepCollectionEquality().equals(other.historyOrders, historyOrders));
}


@override
int get hashCode => Object.hash(runtimeType,isActiveLoading,isHistoryLoading,totalActiveCount,const DeepCollectionEquality().hash(activeOrders),const DeepCollectionEquality().hash(historyOrders));

@override
String toString() {
  return 'ParcelListState(isActiveLoading: $isActiveLoading, isHistoryLoading: $isHistoryLoading, totalActiveCount: $totalActiveCount, activeOrders: $activeOrders, historyOrders: $historyOrders)';
}


}

/// @nodoc
abstract mixin class $ParcelListStateCopyWith<$Res>  {
  factory $ParcelListStateCopyWith(ParcelListState value, $Res Function(ParcelListState) _then) = _$ParcelListStateCopyWithImpl;
@useResult
$Res call({
 bool isActiveLoading, bool isHistoryLoading, int totalActiveCount, List<ParcelOrder> activeOrders, List<ParcelOrder> historyOrders
});




}
/// @nodoc
class _$ParcelListStateCopyWithImpl<$Res>
    implements $ParcelListStateCopyWith<$Res> {
  _$ParcelListStateCopyWithImpl(this._self, this._then);

  final ParcelListState _self;
  final $Res Function(ParcelListState) _then;

/// Create a copy of ParcelListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isActiveLoading = null,Object? isHistoryLoading = null,Object? totalActiveCount = null,Object? activeOrders = null,Object? historyOrders = null,}) {
  return _then(_self.copyWith(
isActiveLoading: null == isActiveLoading ? _self.isActiveLoading : isActiveLoading // ignore: cast_nullable_to_non_nullable
as bool,isHistoryLoading: null == isHistoryLoading ? _self.isHistoryLoading : isHistoryLoading // ignore: cast_nullable_to_non_nullable
as bool,totalActiveCount: null == totalActiveCount ? _self.totalActiveCount : totalActiveCount // ignore: cast_nullable_to_non_nullable
as int,activeOrders: null == activeOrders ? _self.activeOrders : activeOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,historyOrders: null == historyOrders ? _self.historyOrders : historyOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,
  ));
}

}


/// Adds pattern-matching-related methods to [ParcelListState].
extension ParcelListStatePatterns on ParcelListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParcelListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParcelListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParcelListState value)  $default,){
final _that = this;
switch (_that) {
case _ParcelListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParcelListState value)?  $default,){
final _that = this;
switch (_that) {
case _ParcelListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActiveLoading,  bool isHistoryLoading,  int totalActiveCount,  List<ParcelOrder> activeOrders,  List<ParcelOrder> historyOrders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParcelListState() when $default != null:
return $default(_that.isActiveLoading,_that.isHistoryLoading,_that.totalActiveCount,_that.activeOrders,_that.historyOrders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActiveLoading,  bool isHistoryLoading,  int totalActiveCount,  List<ParcelOrder> activeOrders,  List<ParcelOrder> historyOrders)  $default,) {final _that = this;
switch (_that) {
case _ParcelListState():
return $default(_that.isActiveLoading,_that.isHistoryLoading,_that.totalActiveCount,_that.activeOrders,_that.historyOrders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActiveLoading,  bool isHistoryLoading,  int totalActiveCount,  List<ParcelOrder> activeOrders,  List<ParcelOrder> historyOrders)?  $default,) {final _that = this;
switch (_that) {
case _ParcelListState() when $default != null:
return $default(_that.isActiveLoading,_that.isHistoryLoading,_that.totalActiveCount,_that.activeOrders,_that.historyOrders);case _:
  return null;

}
}

}

/// @nodoc


class _ParcelListState extends ParcelListState {
  const _ParcelListState({this.isActiveLoading = false, this.isHistoryLoading = false, this.totalActiveCount = 0, final  List<ParcelOrder> activeOrders = const [], final  List<ParcelOrder> historyOrders = const []}): _activeOrders = activeOrders,_historyOrders = historyOrders,super._();
  

@override@JsonKey() final  bool isActiveLoading;
@override@JsonKey() final  bool isHistoryLoading;
@override@JsonKey() final  int totalActiveCount;
 final  List<ParcelOrder> _activeOrders;
@override@JsonKey() List<ParcelOrder> get activeOrders {
  if (_activeOrders is EqualUnmodifiableListView) return _activeOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeOrders);
}

 final  List<ParcelOrder> _historyOrders;
@override@JsonKey() List<ParcelOrder> get historyOrders {
  if (_historyOrders is EqualUnmodifiableListView) return _historyOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_historyOrders);
}


/// Create a copy of ParcelListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParcelListStateCopyWith<_ParcelListState> get copyWith => __$ParcelListStateCopyWithImpl<_ParcelListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParcelListState&&(identical(other.isActiveLoading, isActiveLoading) || other.isActiveLoading == isActiveLoading)&&(identical(other.isHistoryLoading, isHistoryLoading) || other.isHistoryLoading == isHistoryLoading)&&(identical(other.totalActiveCount, totalActiveCount) || other.totalActiveCount == totalActiveCount)&&const DeepCollectionEquality().equals(other._activeOrders, _activeOrders)&&const DeepCollectionEquality().equals(other._historyOrders, _historyOrders));
}


@override
int get hashCode => Object.hash(runtimeType,isActiveLoading,isHistoryLoading,totalActiveCount,const DeepCollectionEquality().hash(_activeOrders),const DeepCollectionEquality().hash(_historyOrders));

@override
String toString() {
  return 'ParcelListState(isActiveLoading: $isActiveLoading, isHistoryLoading: $isHistoryLoading, totalActiveCount: $totalActiveCount, activeOrders: $activeOrders, historyOrders: $historyOrders)';
}


}

/// @nodoc
abstract mixin class _$ParcelListStateCopyWith<$Res> implements $ParcelListStateCopyWith<$Res> {
  factory _$ParcelListStateCopyWith(_ParcelListState value, $Res Function(_ParcelListState) _then) = __$ParcelListStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActiveLoading, bool isHistoryLoading, int totalActiveCount, List<ParcelOrder> activeOrders, List<ParcelOrder> historyOrders
});




}
/// @nodoc
class __$ParcelListStateCopyWithImpl<$Res>
    implements _$ParcelListStateCopyWith<$Res> {
  __$ParcelListStateCopyWithImpl(this._self, this._then);

  final _ParcelListState _self;
  final $Res Function(_ParcelListState) _then;

/// Create a copy of ParcelListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isActiveLoading = null,Object? isHistoryLoading = null,Object? totalActiveCount = null,Object? activeOrders = null,Object? historyOrders = null,}) {
  return _then(_ParcelListState(
isActiveLoading: null == isActiveLoading ? _self.isActiveLoading : isActiveLoading // ignore: cast_nullable_to_non_nullable
as bool,isHistoryLoading: null == isHistoryLoading ? _self.isHistoryLoading : isHistoryLoading // ignore: cast_nullable_to_non_nullable
as bool,totalActiveCount: null == totalActiveCount ? _self.totalActiveCount : totalActiveCount // ignore: cast_nullable_to_non_nullable
as int,activeOrders: null == activeOrders ? _self._activeOrders : activeOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,historyOrders: null == historyOrders ? _self._historyOrders : historyOrders // ignore: cast_nullable_to_non_nullable
as List<ParcelOrder>,
  ));
}


}

// dart format on
