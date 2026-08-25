// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_cards_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedCardsState {

 List<SavedCardModel> get cards; bool get isLoading; String? get error;
/// Create a copy of SavedCardsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedCardsStateCopyWith<SavedCardsState> get copyWith => _$SavedCardsStateCopyWithImpl<SavedCardsState>(this as SavedCardsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedCardsState&&const DeepCollectionEquality().equals(other.cards, cards)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(cards),isLoading,error);

@override
String toString() {
  return 'SavedCardsState(cards: $cards, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class $SavedCardsStateCopyWith<$Res>  {
  factory $SavedCardsStateCopyWith(SavedCardsState value, $Res Function(SavedCardsState) _then) = _$SavedCardsStateCopyWithImpl;
@useResult
$Res call({
 List<SavedCardModel> cards, bool isLoading, String? error
});




}
/// @nodoc
class _$SavedCardsStateCopyWithImpl<$Res>
    implements $SavedCardsStateCopyWith<$Res> {
  _$SavedCardsStateCopyWithImpl(this._self, this._then);

  final SavedCardsState _self;
  final $Res Function(SavedCardsState) _then;

/// Create a copy of SavedCardsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cards = null,Object? isLoading = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<SavedCardModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedCardsState].
extension SavedCardsStatePatterns on SavedCardsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedCardsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedCardsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedCardsState value)  $default,){
final _that = this;
switch (_that) {
case _SavedCardsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedCardsState value)?  $default,){
final _that = this;
switch (_that) {
case _SavedCardsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SavedCardModel> cards,  bool isLoading,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedCardsState() when $default != null:
return $default(_that.cards,_that.isLoading,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SavedCardModel> cards,  bool isLoading,  String? error)  $default,) {final _that = this;
switch (_that) {
case _SavedCardsState():
return $default(_that.cards,_that.isLoading,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SavedCardModel> cards,  bool isLoading,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _SavedCardsState() when $default != null:
return $default(_that.cards,_that.isLoading,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _SavedCardsState extends SavedCardsState {
  const _SavedCardsState({final  List<SavedCardModel> cards = const [], this.isLoading = false, this.error}): _cards = cards,super._();
  

 final  List<SavedCardModel> _cards;
@override@JsonKey() List<SavedCardModel> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

@override@JsonKey() final  bool isLoading;
@override final  String? error;

/// Create a copy of SavedCardsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedCardsStateCopyWith<_SavedCardsState> get copyWith => __$SavedCardsStateCopyWithImpl<_SavedCardsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedCardsState&&const DeepCollectionEquality().equals(other._cards, _cards)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cards),isLoading,error);

@override
String toString() {
  return 'SavedCardsState(cards: $cards, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class _$SavedCardsStateCopyWith<$Res> implements $SavedCardsStateCopyWith<$Res> {
  factory _$SavedCardsStateCopyWith(_SavedCardsState value, $Res Function(_SavedCardsState) _then) = __$SavedCardsStateCopyWithImpl;
@override @useResult
$Res call({
 List<SavedCardModel> cards, bool isLoading, String? error
});




}
/// @nodoc
class __$SavedCardsStateCopyWithImpl<$Res>
    implements _$SavedCardsStateCopyWith<$Res> {
  __$SavedCardsStateCopyWithImpl(this._self, this._then);

  final _SavedCardsState _self;
  final $Res Function(_SavedCardsState) _then;

/// Create a copy of SavedCardsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cards = null,Object? isLoading = null,Object? error = freezed,}) {
  return _then(_SavedCardsState(
cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<SavedCardModel>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
