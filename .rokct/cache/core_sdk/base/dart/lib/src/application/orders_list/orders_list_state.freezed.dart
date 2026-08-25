// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'orders_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrdersListState {

 bool get isActiveLoading; bool get isHistoryLoading; bool get isRefundLoading; int get totalActiveCount; List<OrderActiveModel> get activeOrders; List<OrderActiveModel> get historyOrders; List<RefundModel> get refundOrders;
/// Create a copy of OrdersListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrdersListStateCopyWith<OrdersListState> get copyWith => _$OrdersListStateCopyWithImpl<OrdersListState>(this as OrdersListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrdersListState&&(identical(other.isActiveLoading, isActiveLoading) || other.isActiveLoading == isActiveLoading)&&(identical(other.isHistoryLoading, isHistoryLoading) || other.isHistoryLoading == isHistoryLoading)&&(identical(other.isRefundLoading, isRefundLoading) || other.isRefundLoading == isRefundLoading)&&(identical(other.totalActiveCount, totalActiveCount) || other.totalActiveCount == totalActiveCount)&&const DeepCollectionEquality().equals(other.activeOrders, activeOrders)&&const DeepCollectionEquality().equals(other.historyOrders, historyOrders)&&const DeepCollectionEquality().equals(other.refundOrders, refundOrders));
}


@override
int get hashCode => Object.hash(runtimeType,isActiveLoading,isHistoryLoading,isRefundLoading,totalActiveCount,const DeepCollectionEquality().hash(activeOrders),const DeepCollectionEquality().hash(historyOrders),const DeepCollectionEquality().hash(refundOrders));

@override
String toString() {
  return 'OrdersListState(isActiveLoading: $isActiveLoading, isHistoryLoading: $isHistoryLoading, isRefundLoading: $isRefundLoading, totalActiveCount: $totalActiveCount, activeOrders: $activeOrders, historyOrders: $historyOrders, refundOrders: $refundOrders)';
}


}

/// @nodoc
abstract mixin class $OrdersListStateCopyWith<$Res>  {
  factory $OrdersListStateCopyWith(OrdersListState value, $Res Function(OrdersListState) _then) = _$OrdersListStateCopyWithImpl;
@useResult
$Res call({
 bool isActiveLoading, bool isHistoryLoading, bool isRefundLoading, int totalActiveCount, List<OrderActiveModel> activeOrders, List<OrderActiveModel> historyOrders, List<RefundModel> refundOrders
});




}
/// @nodoc
class _$OrdersListStateCopyWithImpl<$Res>
    implements $OrdersListStateCopyWith<$Res> {
  _$OrdersListStateCopyWithImpl(this._self, this._then);

  final OrdersListState _self;
  final $Res Function(OrdersListState) _then;

/// Create a copy of OrdersListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isActiveLoading = null,Object? isHistoryLoading = null,Object? isRefundLoading = null,Object? totalActiveCount = null,Object? activeOrders = null,Object? historyOrders = null,Object? refundOrders = null,}) {
  return _then(_self.copyWith(
isActiveLoading: null == isActiveLoading ? _self.isActiveLoading : isActiveLoading // ignore: cast_nullable_to_non_nullable
as bool,isHistoryLoading: null == isHistoryLoading ? _self.isHistoryLoading : isHistoryLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefundLoading: null == isRefundLoading ? _self.isRefundLoading : isRefundLoading // ignore: cast_nullable_to_non_nullable
as bool,totalActiveCount: null == totalActiveCount ? _self.totalActiveCount : totalActiveCount // ignore: cast_nullable_to_non_nullable
as int,activeOrders: null == activeOrders ? _self.activeOrders : activeOrders // ignore: cast_nullable_to_non_nullable
as List<OrderActiveModel>,historyOrders: null == historyOrders ? _self.historyOrders : historyOrders // ignore: cast_nullable_to_non_nullable
as List<OrderActiveModel>,refundOrders: null == refundOrders ? _self.refundOrders : refundOrders // ignore: cast_nullable_to_non_nullable
as List<RefundModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrdersListState].
extension OrdersListStatePatterns on OrdersListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrdersListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrdersListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrdersListState value)  $default,){
final _that = this;
switch (_that) {
case _OrdersListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrdersListState value)?  $default,){
final _that = this;
switch (_that) {
case _OrdersListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isActiveLoading,  bool isHistoryLoading,  bool isRefundLoading,  int totalActiveCount,  List<OrderActiveModel> activeOrders,  List<OrderActiveModel> historyOrders,  List<RefundModel> refundOrders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrdersListState() when $default != null:
return $default(_that.isActiveLoading,_that.isHistoryLoading,_that.isRefundLoading,_that.totalActiveCount,_that.activeOrders,_that.historyOrders,_that.refundOrders);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isActiveLoading,  bool isHistoryLoading,  bool isRefundLoading,  int totalActiveCount,  List<OrderActiveModel> activeOrders,  List<OrderActiveModel> historyOrders,  List<RefundModel> refundOrders)  $default,) {final _that = this;
switch (_that) {
case _OrdersListState():
return $default(_that.isActiveLoading,_that.isHistoryLoading,_that.isRefundLoading,_that.totalActiveCount,_that.activeOrders,_that.historyOrders,_that.refundOrders);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isActiveLoading,  bool isHistoryLoading,  bool isRefundLoading,  int totalActiveCount,  List<OrderActiveModel> activeOrders,  List<OrderActiveModel> historyOrders,  List<RefundModel> refundOrders)?  $default,) {final _that = this;
switch (_that) {
case _OrdersListState() when $default != null:
return $default(_that.isActiveLoading,_that.isHistoryLoading,_that.isRefundLoading,_that.totalActiveCount,_that.activeOrders,_that.historyOrders,_that.refundOrders);case _:
  return null;

}
}

}

/// @nodoc


class _OrdersListState extends OrdersListState {
  const _OrdersListState({this.isActiveLoading = false, this.isHistoryLoading = false, this.isRefundLoading = false, this.totalActiveCount = 0, final  List<OrderActiveModel> activeOrders = const [], final  List<OrderActiveModel> historyOrders = const [], final  List<RefundModel> refundOrders = const []}): _activeOrders = activeOrders,_historyOrders = historyOrders,_refundOrders = refundOrders,super._();
  

@override@JsonKey() final  bool isActiveLoading;
@override@JsonKey() final  bool isHistoryLoading;
@override@JsonKey() final  bool isRefundLoading;
@override@JsonKey() final  int totalActiveCount;
 final  List<OrderActiveModel> _activeOrders;
@override@JsonKey() List<OrderActiveModel> get activeOrders {
  if (_activeOrders is EqualUnmodifiableListView) return _activeOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_activeOrders);
}

 final  List<OrderActiveModel> _historyOrders;
@override@JsonKey() List<OrderActiveModel> get historyOrders {
  if (_historyOrders is EqualUnmodifiableListView) return _historyOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_historyOrders);
}

 final  List<RefundModel> _refundOrders;
@override@JsonKey() List<RefundModel> get refundOrders {
  if (_refundOrders is EqualUnmodifiableListView) return _refundOrders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_refundOrders);
}


/// Create a copy of OrdersListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrdersListStateCopyWith<_OrdersListState> get copyWith => __$OrdersListStateCopyWithImpl<_OrdersListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrdersListState&&(identical(other.isActiveLoading, isActiveLoading) || other.isActiveLoading == isActiveLoading)&&(identical(other.isHistoryLoading, isHistoryLoading) || other.isHistoryLoading == isHistoryLoading)&&(identical(other.isRefundLoading, isRefundLoading) || other.isRefundLoading == isRefundLoading)&&(identical(other.totalActiveCount, totalActiveCount) || other.totalActiveCount == totalActiveCount)&&const DeepCollectionEquality().equals(other._activeOrders, _activeOrders)&&const DeepCollectionEquality().equals(other._historyOrders, _historyOrders)&&const DeepCollectionEquality().equals(other._refundOrders, _refundOrders));
}


@override
int get hashCode => Object.hash(runtimeType,isActiveLoading,isHistoryLoading,isRefundLoading,totalActiveCount,const DeepCollectionEquality().hash(_activeOrders),const DeepCollectionEquality().hash(_historyOrders),const DeepCollectionEquality().hash(_refundOrders));

@override
String toString() {
  return 'OrdersListState(isActiveLoading: $isActiveLoading, isHistoryLoading: $isHistoryLoading, isRefundLoading: $isRefundLoading, totalActiveCount: $totalActiveCount, activeOrders: $activeOrders, historyOrders: $historyOrders, refundOrders: $refundOrders)';
}


}

/// @nodoc
abstract mixin class _$OrdersListStateCopyWith<$Res> implements $OrdersListStateCopyWith<$Res> {
  factory _$OrdersListStateCopyWith(_OrdersListState value, $Res Function(_OrdersListState) _then) = __$OrdersListStateCopyWithImpl;
@override @useResult
$Res call({
 bool isActiveLoading, bool isHistoryLoading, bool isRefundLoading, int totalActiveCount, List<OrderActiveModel> activeOrders, List<OrderActiveModel> historyOrders, List<RefundModel> refundOrders
});




}
/// @nodoc
class __$OrdersListStateCopyWithImpl<$Res>
    implements _$OrdersListStateCopyWith<$Res> {
  __$OrdersListStateCopyWithImpl(this._self, this._then);

  final _OrdersListState _self;
  final $Res Function(_OrdersListState) _then;

/// Create a copy of OrdersListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isActiveLoading = null,Object? isHistoryLoading = null,Object? isRefundLoading = null,Object? totalActiveCount = null,Object? activeOrders = null,Object? historyOrders = null,Object? refundOrders = null,}) {
  return _then(_OrdersListState(
isActiveLoading: null == isActiveLoading ? _self.isActiveLoading : isActiveLoading // ignore: cast_nullable_to_non_nullable
as bool,isHistoryLoading: null == isHistoryLoading ? _self.isHistoryLoading : isHistoryLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefundLoading: null == isRefundLoading ? _self.isRefundLoading : isRefundLoading // ignore: cast_nullable_to_non_nullable
as bool,totalActiveCount: null == totalActiveCount ? _self.totalActiveCount : totalActiveCount // ignore: cast_nullable_to_non_nullable
as int,activeOrders: null == activeOrders ? _self._activeOrders : activeOrders // ignore: cast_nullable_to_non_nullable
as List<OrderActiveModel>,historyOrders: null == historyOrders ? _self._historyOrders : historyOrders // ignore: cast_nullable_to_non_nullable
as List<OrderActiveModel>,refundOrders: null == refundOrders ? _self._refundOrders : refundOrders // ignore: cast_nullable_to_non_nullable
as List<RefundModel>,
  ));
}


}

// dart format on
