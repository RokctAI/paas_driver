// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delivery_zone_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeliveryZoneState {

 bool get isLoading; bool get isSaving; List<List<double>> get deliveryZones; List<LatLng> get tappedPoints; Set<Polygon> get polygon;
/// Create a copy of DeliveryZoneState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeliveryZoneStateCopyWith<DeliveryZoneState> get copyWith => _$DeliveryZoneStateCopyWithImpl<DeliveryZoneState>(this as DeliveryZoneState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeliveryZoneState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&const DeepCollectionEquality().equals(other.deliveryZones, deliveryZones)&&const DeepCollectionEquality().equals(other.tappedPoints, tappedPoints)&&const DeepCollectionEquality().equals(other.polygon, polygon));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSaving,const DeepCollectionEquality().hash(deliveryZones),const DeepCollectionEquality().hash(tappedPoints),const DeepCollectionEquality().hash(polygon));

@override
String toString() {
  return 'DeliveryZoneState(isLoading: $isLoading, isSaving: $isSaving, deliveryZones: $deliveryZones, tappedPoints: $tappedPoints, polygon: $polygon)';
}


}

/// @nodoc
abstract mixin class $DeliveryZoneStateCopyWith<$Res>  {
  factory $DeliveryZoneStateCopyWith(DeliveryZoneState value, $Res Function(DeliveryZoneState) _then) = _$DeliveryZoneStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isSaving, List<List<double>> deliveryZones, List<LatLng> tappedPoints, Set<Polygon> polygon
});




}
/// @nodoc
class _$DeliveryZoneStateCopyWithImpl<$Res>
    implements $DeliveryZoneStateCopyWith<$Res> {
  _$DeliveryZoneStateCopyWithImpl(this._self, this._then);

  final DeliveryZoneState _self;
  final $Res Function(DeliveryZoneState) _then;

/// Create a copy of DeliveryZoneState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isSaving = null,Object? deliveryZones = null,Object? tappedPoints = null,Object? polygon = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,deliveryZones: null == deliveryZones ? _self.deliveryZones : deliveryZones // ignore: cast_nullable_to_non_nullable
as List<List<double>>,tappedPoints: null == tappedPoints ? _self.tappedPoints : tappedPoints // ignore: cast_nullable_to_non_nullable
as List<LatLng>,polygon: null == polygon ? _self.polygon : polygon // ignore: cast_nullable_to_non_nullable
as Set<Polygon>,
  ));
}

}


/// Adds pattern-matching-related methods to [DeliveryZoneState].
extension DeliveryZoneStatePatterns on DeliveryZoneState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeliveryZoneState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeliveryZoneState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeliveryZoneState value)  $default,){
final _that = this;
switch (_that) {
case _DeliveryZoneState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeliveryZoneState value)?  $default,){
final _that = this;
switch (_that) {
case _DeliveryZoneState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isSaving,  List<List<double>> deliveryZones,  List<LatLng> tappedPoints,  Set<Polygon> polygon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeliveryZoneState() when $default != null:
return $default(_that.isLoading,_that.isSaving,_that.deliveryZones,_that.tappedPoints,_that.polygon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isSaving,  List<List<double>> deliveryZones,  List<LatLng> tappedPoints,  Set<Polygon> polygon)  $default,) {final _that = this;
switch (_that) {
case _DeliveryZoneState():
return $default(_that.isLoading,_that.isSaving,_that.deliveryZones,_that.tappedPoints,_that.polygon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isSaving,  List<List<double>> deliveryZones,  List<LatLng> tappedPoints,  Set<Polygon> polygon)?  $default,) {final _that = this;
switch (_that) {
case _DeliveryZoneState() when $default != null:
return $default(_that.isLoading,_that.isSaving,_that.deliveryZones,_that.tappedPoints,_that.polygon);case _:
  return null;

}
}

}

/// @nodoc


class _DeliveryZoneState extends DeliveryZoneState {
  const _DeliveryZoneState({this.isLoading = false, this.isSaving = false, final  List<List<double>> deliveryZones = const [], final  List<LatLng> tappedPoints = const [], final  Set<Polygon> polygon = const {}}): _deliveryZones = deliveryZones,_tappedPoints = tappedPoints,_polygon = polygon,super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSaving;
 final  List<List<double>> _deliveryZones;
@override@JsonKey() List<List<double>> get deliveryZones {
  if (_deliveryZones is EqualUnmodifiableListView) return _deliveryZones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_deliveryZones);
}

 final  List<LatLng> _tappedPoints;
@override@JsonKey() List<LatLng> get tappedPoints {
  if (_tappedPoints is EqualUnmodifiableListView) return _tappedPoints;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tappedPoints);
}

 final  Set<Polygon> _polygon;
@override@JsonKey() Set<Polygon> get polygon {
  if (_polygon is EqualUnmodifiableSetView) return _polygon;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_polygon);
}


/// Create a copy of DeliveryZoneState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeliveryZoneStateCopyWith<_DeliveryZoneState> get copyWith => __$DeliveryZoneStateCopyWithImpl<_DeliveryZoneState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeliveryZoneState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&const DeepCollectionEquality().equals(other._deliveryZones, _deliveryZones)&&const DeepCollectionEquality().equals(other._tappedPoints, _tappedPoints)&&const DeepCollectionEquality().equals(other._polygon, _polygon));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isSaving,const DeepCollectionEquality().hash(_deliveryZones),const DeepCollectionEquality().hash(_tappedPoints),const DeepCollectionEquality().hash(_polygon));

@override
String toString() {
  return 'DeliveryZoneState(isLoading: $isLoading, isSaving: $isSaving, deliveryZones: $deliveryZones, tappedPoints: $tappedPoints, polygon: $polygon)';
}


}

/// @nodoc
abstract mixin class _$DeliveryZoneStateCopyWith<$Res> implements $DeliveryZoneStateCopyWith<$Res> {
  factory _$DeliveryZoneStateCopyWith(_DeliveryZoneState value, $Res Function(_DeliveryZoneState) _then) = __$DeliveryZoneStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isSaving, List<List<double>> deliveryZones, List<LatLng> tappedPoints, Set<Polygon> polygon
});




}
/// @nodoc
class __$DeliveryZoneStateCopyWithImpl<$Res>
    implements _$DeliveryZoneStateCopyWith<$Res> {
  __$DeliveryZoneStateCopyWithImpl(this._self, this._then);

  final _DeliveryZoneState _self;
  final $Res Function(_DeliveryZoneState) _then;

/// Create a copy of DeliveryZoneState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isSaving = null,Object? deliveryZones = null,Object? tappedPoints = null,Object? polygon = null,}) {
  return _then(_DeliveryZoneState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,deliveryZones: null == deliveryZones ? _self._deliveryZones : deliveryZones // ignore: cast_nullable_to_non_nullable
as List<List<double>>,tappedPoints: null == tappedPoints ? _self._tappedPoints : tappedPoints // ignore: cast_nullable_to_non_nullable
as List<LatLng>,polygon: null == polygon ? _self._polygon : polygon // ignore: cast_nullable_to_non_nullable
as Set<Polygon>,
  ));
}


}

// dart format on
