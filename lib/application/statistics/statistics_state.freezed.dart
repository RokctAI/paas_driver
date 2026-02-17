// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistics_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StatisticsState {

 bool get isLoading; bool get isRefresh; List<Series<OrdinalSales, String>> get list; List<StatisticsOrder> get listOfOrder; StatisticsIncomeResponse? get countData;
/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatisticsStateCopyWith<StatisticsState> get copyWith => _$StatisticsStateCopyWithImpl<StatisticsState>(this as StatisticsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatisticsState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefresh, isRefresh) || other.isRefresh == isRefresh)&&const DeepCollectionEquality().equals(other.list, list)&&const DeepCollectionEquality().equals(other.listOfOrder, listOfOrder)&&(identical(other.countData, countData) || other.countData == countData));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isRefresh,const DeepCollectionEquality().hash(list),const DeepCollectionEquality().hash(listOfOrder),countData);

@override
String toString() {
  return 'StatisticsState(isLoading: $isLoading, isRefresh: $isRefresh, list: $list, listOfOrder: $listOfOrder, countData: $countData)';
}


}

/// @nodoc
abstract mixin class $StatisticsStateCopyWith<$Res>  {
  factory $StatisticsStateCopyWith(StatisticsState value, $Res Function(StatisticsState) _then) = _$StatisticsStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isRefresh, List<Series<OrdinalSales, String>> list, List<StatisticsOrder> listOfOrder, StatisticsIncomeResponse? countData
});




}
/// @nodoc
class _$StatisticsStateCopyWithImpl<$Res>
    implements $StatisticsStateCopyWith<$Res> {
  _$StatisticsStateCopyWithImpl(this._self, this._then);

  final StatisticsState _self;
  final $Res Function(StatisticsState) _then;

/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isRefresh = null,Object? list = null,Object? listOfOrder = null,Object? countData = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefresh: null == isRefresh ? _self.isRefresh : isRefresh // ignore: cast_nullable_to_non_nullable
as bool,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<Series<OrdinalSales, String>>,listOfOrder: null == listOfOrder ? _self.listOfOrder : listOfOrder // ignore: cast_nullable_to_non_nullable
as List<StatisticsOrder>,countData: freezed == countData ? _self.countData : countData // ignore: cast_nullable_to_non_nullable
as StatisticsIncomeResponse?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatisticsState].
extension StatisticsStatePatterns on StatisticsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatisticsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatisticsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatisticsState value)  $default,){
final _that = this;
switch (_that) {
case _StatisticsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatisticsState value)?  $default,){
final _that = this;
switch (_that) {
case _StatisticsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isRefresh,  List<Series<OrdinalSales, String>> list,  List<StatisticsOrder> listOfOrder,  StatisticsIncomeResponse? countData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatisticsState() when $default != null:
return $default(_that.isLoading,_that.isRefresh,_that.list,_that.listOfOrder,_that.countData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isRefresh,  List<Series<OrdinalSales, String>> list,  List<StatisticsOrder> listOfOrder,  StatisticsIncomeResponse? countData)  $default,) {final _that = this;
switch (_that) {
case _StatisticsState():
return $default(_that.isLoading,_that.isRefresh,_that.list,_that.listOfOrder,_that.countData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isRefresh,  List<Series<OrdinalSales, String>> list,  List<StatisticsOrder> listOfOrder,  StatisticsIncomeResponse? countData)?  $default,) {final _that = this;
switch (_that) {
case _StatisticsState() when $default != null:
return $default(_that.isLoading,_that.isRefresh,_that.list,_that.listOfOrder,_that.countData);case _:
  return null;

}
}

}

/// @nodoc


class _StatisticsState extends StatisticsState {
  const _StatisticsState({this.isLoading = false, this.isRefresh = true, final  List<Series<OrdinalSales, String>> list = const [], final  List<StatisticsOrder> listOfOrder = const [], this.countData}): _list = list,_listOfOrder = listOfOrder,super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isRefresh;
 final  List<Series<OrdinalSales, String>> _list;
@override@JsonKey() List<Series<OrdinalSales, String>> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

 final  List<StatisticsOrder> _listOfOrder;
@override@JsonKey() List<StatisticsOrder> get listOfOrder {
  if (_listOfOrder is EqualUnmodifiableListView) return _listOfOrder;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_listOfOrder);
}

@override final  StatisticsIncomeResponse? countData;

/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatisticsStateCopyWith<_StatisticsState> get copyWith => __$StatisticsStateCopyWithImpl<_StatisticsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatisticsState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isRefresh, isRefresh) || other.isRefresh == isRefresh)&&const DeepCollectionEquality().equals(other._list, _list)&&const DeepCollectionEquality().equals(other._listOfOrder, _listOfOrder)&&(identical(other.countData, countData) || other.countData == countData));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isRefresh,const DeepCollectionEquality().hash(_list),const DeepCollectionEquality().hash(_listOfOrder),countData);

@override
String toString() {
  return 'StatisticsState(isLoading: $isLoading, isRefresh: $isRefresh, list: $list, listOfOrder: $listOfOrder, countData: $countData)';
}


}

/// @nodoc
abstract mixin class _$StatisticsStateCopyWith<$Res> implements $StatisticsStateCopyWith<$Res> {
  factory _$StatisticsStateCopyWith(_StatisticsState value, $Res Function(_StatisticsState) _then) = __$StatisticsStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isRefresh, List<Series<OrdinalSales, String>> list, List<StatisticsOrder> listOfOrder, StatisticsIncomeResponse? countData
});




}
/// @nodoc
class __$StatisticsStateCopyWithImpl<$Res>
    implements _$StatisticsStateCopyWith<$Res> {
  __$StatisticsStateCopyWithImpl(this._self, this._then);

  final _StatisticsState _self;
  final $Res Function(_StatisticsState) _then;

/// Create a copy of StatisticsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isRefresh = null,Object? list = null,Object? listOfOrder = null,Object? countData = freezed,}) {
  return _then(_StatisticsState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isRefresh: null == isRefresh ? _self.isRefresh : isRefresh // ignore: cast_nullable_to_non_nullable
as bool,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<Series<OrdinalSales, String>>,listOfOrder: null == listOfOrder ? _self._listOfOrder : listOfOrder // ignore: cast_nullable_to_non_nullable
as List<StatisticsOrder>,countData: freezed == countData ? _self.countData : countData // ignore: cast_nullable_to_non_nullable
as StatisticsIncomeResponse?,
  ));
}


}

// dart format on
