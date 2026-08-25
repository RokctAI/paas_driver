// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShopOrderState {

 bool get isLoading; bool get isStartGroupLoading; bool get isStartGroup; bool get isOtherShop; bool get isDeleteLoading; bool get isCheckShopOrder; bool get isAddAndRemoveLoading; bool get isEditOrder; String get shareLink; Cart? get cart; List<CartProductData> get productList;
/// Create a copy of ShopOrderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopOrderStateCopyWith<ShopOrderState> get copyWith => _$ShopOrderStateCopyWithImpl<ShopOrderState>(this as ShopOrderState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopOrderState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isStartGroupLoading, isStartGroupLoading) || other.isStartGroupLoading == isStartGroupLoading)&&(identical(other.isStartGroup, isStartGroup) || other.isStartGroup == isStartGroup)&&(identical(other.isOtherShop, isOtherShop) || other.isOtherShop == isOtherShop)&&(identical(other.isDeleteLoading, isDeleteLoading) || other.isDeleteLoading == isDeleteLoading)&&(identical(other.isCheckShopOrder, isCheckShopOrder) || other.isCheckShopOrder == isCheckShopOrder)&&(identical(other.isAddAndRemoveLoading, isAddAndRemoveLoading) || other.isAddAndRemoveLoading == isAddAndRemoveLoading)&&(identical(other.isEditOrder, isEditOrder) || other.isEditOrder == isEditOrder)&&(identical(other.shareLink, shareLink) || other.shareLink == shareLink)&&(identical(other.cart, cart) || other.cart == cart)&&const DeepCollectionEquality().equals(other.productList, productList));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isStartGroupLoading,isStartGroup,isOtherShop,isDeleteLoading,isCheckShopOrder,isAddAndRemoveLoading,isEditOrder,shareLink,cart,const DeepCollectionEquality().hash(productList));

@override
String toString() {
  return 'ShopOrderState(isLoading: $isLoading, isStartGroupLoading: $isStartGroupLoading, isStartGroup: $isStartGroup, isOtherShop: $isOtherShop, isDeleteLoading: $isDeleteLoading, isCheckShopOrder: $isCheckShopOrder, isAddAndRemoveLoading: $isAddAndRemoveLoading, isEditOrder: $isEditOrder, shareLink: $shareLink, cart: $cart, productList: $productList)';
}


}

/// @nodoc
abstract mixin class $ShopOrderStateCopyWith<$Res>  {
  factory $ShopOrderStateCopyWith(ShopOrderState value, $Res Function(ShopOrderState) _then) = _$ShopOrderStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isStartGroupLoading, bool isStartGroup, bool isOtherShop, bool isDeleteLoading, bool isCheckShopOrder, bool isAddAndRemoveLoading, bool isEditOrder, String shareLink, Cart? cart, List<CartProductData> productList
});




}
/// @nodoc
class _$ShopOrderStateCopyWithImpl<$Res>
    implements $ShopOrderStateCopyWith<$Res> {
  _$ShopOrderStateCopyWithImpl(this._self, this._then);

  final ShopOrderState _self;
  final $Res Function(ShopOrderState) _then;

/// Create a copy of ShopOrderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isStartGroupLoading = null,Object? isStartGroup = null,Object? isOtherShop = null,Object? isDeleteLoading = null,Object? isCheckShopOrder = null,Object? isAddAndRemoveLoading = null,Object? isEditOrder = null,Object? shareLink = null,Object? cart = freezed,Object? productList = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isStartGroupLoading: null == isStartGroupLoading ? _self.isStartGroupLoading : isStartGroupLoading // ignore: cast_nullable_to_non_nullable
as bool,isStartGroup: null == isStartGroup ? _self.isStartGroup : isStartGroup // ignore: cast_nullable_to_non_nullable
as bool,isOtherShop: null == isOtherShop ? _self.isOtherShop : isOtherShop // ignore: cast_nullable_to_non_nullable
as bool,isDeleteLoading: null == isDeleteLoading ? _self.isDeleteLoading : isDeleteLoading // ignore: cast_nullable_to_non_nullable
as bool,isCheckShopOrder: null == isCheckShopOrder ? _self.isCheckShopOrder : isCheckShopOrder // ignore: cast_nullable_to_non_nullable
as bool,isAddAndRemoveLoading: null == isAddAndRemoveLoading ? _self.isAddAndRemoveLoading : isAddAndRemoveLoading // ignore: cast_nullable_to_non_nullable
as bool,isEditOrder: null == isEditOrder ? _self.isEditOrder : isEditOrder // ignore: cast_nullable_to_non_nullable
as bool,shareLink: null == shareLink ? _self.shareLink : shareLink // ignore: cast_nullable_to_non_nullable
as String,cart: freezed == cart ? _self.cart : cart // ignore: cast_nullable_to_non_nullable
as Cart?,productList: null == productList ? _self.productList : productList // ignore: cast_nullable_to_non_nullable
as List<CartProductData>,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopOrderState].
extension ShopOrderStatePatterns on ShopOrderState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopOrderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopOrderState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopOrderState value)  $default,){
final _that = this;
switch (_that) {
case _ShopOrderState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopOrderState value)?  $default,){
final _that = this;
switch (_that) {
case _ShopOrderState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isStartGroupLoading,  bool isStartGroup,  bool isOtherShop,  bool isDeleteLoading,  bool isCheckShopOrder,  bool isAddAndRemoveLoading,  bool isEditOrder,  String shareLink,  Cart? cart,  List<CartProductData> productList)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopOrderState() when $default != null:
return $default(_that.isLoading,_that.isStartGroupLoading,_that.isStartGroup,_that.isOtherShop,_that.isDeleteLoading,_that.isCheckShopOrder,_that.isAddAndRemoveLoading,_that.isEditOrder,_that.shareLink,_that.cart,_that.productList);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isStartGroupLoading,  bool isStartGroup,  bool isOtherShop,  bool isDeleteLoading,  bool isCheckShopOrder,  bool isAddAndRemoveLoading,  bool isEditOrder,  String shareLink,  Cart? cart,  List<CartProductData> productList)  $default,) {final _that = this;
switch (_that) {
case _ShopOrderState():
return $default(_that.isLoading,_that.isStartGroupLoading,_that.isStartGroup,_that.isOtherShop,_that.isDeleteLoading,_that.isCheckShopOrder,_that.isAddAndRemoveLoading,_that.isEditOrder,_that.shareLink,_that.cart,_that.productList);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isStartGroupLoading,  bool isStartGroup,  bool isOtherShop,  bool isDeleteLoading,  bool isCheckShopOrder,  bool isAddAndRemoveLoading,  bool isEditOrder,  String shareLink,  Cart? cart,  List<CartProductData> productList)?  $default,) {final _that = this;
switch (_that) {
case _ShopOrderState() when $default != null:
return $default(_that.isLoading,_that.isStartGroupLoading,_that.isStartGroup,_that.isOtherShop,_that.isDeleteLoading,_that.isCheckShopOrder,_that.isAddAndRemoveLoading,_that.isEditOrder,_that.shareLink,_that.cart,_that.productList);case _:
  return null;

}
}

}

/// @nodoc


class _ShopOrderState extends ShopOrderState {
  const _ShopOrderState({this.isLoading = false, this.isStartGroupLoading = false, this.isStartGroup = false, this.isOtherShop = false, this.isDeleteLoading = false, this.isCheckShopOrder = false, this.isAddAndRemoveLoading = false, this.isEditOrder = false, this.shareLink = "", this.cart = null, final  List<CartProductData> productList = const []}): _productList = productList,super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isStartGroupLoading;
@override@JsonKey() final  bool isStartGroup;
@override@JsonKey() final  bool isOtherShop;
@override@JsonKey() final  bool isDeleteLoading;
@override@JsonKey() final  bool isCheckShopOrder;
@override@JsonKey() final  bool isAddAndRemoveLoading;
@override@JsonKey() final  bool isEditOrder;
@override@JsonKey() final  String shareLink;
@override@JsonKey() final  Cart? cart;
 final  List<CartProductData> _productList;
@override@JsonKey() List<CartProductData> get productList {
  if (_productList is EqualUnmodifiableListView) return _productList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_productList);
}


/// Create a copy of ShopOrderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopOrderStateCopyWith<_ShopOrderState> get copyWith => __$ShopOrderStateCopyWithImpl<_ShopOrderState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopOrderState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isStartGroupLoading, isStartGroupLoading) || other.isStartGroupLoading == isStartGroupLoading)&&(identical(other.isStartGroup, isStartGroup) || other.isStartGroup == isStartGroup)&&(identical(other.isOtherShop, isOtherShop) || other.isOtherShop == isOtherShop)&&(identical(other.isDeleteLoading, isDeleteLoading) || other.isDeleteLoading == isDeleteLoading)&&(identical(other.isCheckShopOrder, isCheckShopOrder) || other.isCheckShopOrder == isCheckShopOrder)&&(identical(other.isAddAndRemoveLoading, isAddAndRemoveLoading) || other.isAddAndRemoveLoading == isAddAndRemoveLoading)&&(identical(other.isEditOrder, isEditOrder) || other.isEditOrder == isEditOrder)&&(identical(other.shareLink, shareLink) || other.shareLink == shareLink)&&(identical(other.cart, cart) || other.cart == cart)&&const DeepCollectionEquality().equals(other._productList, _productList));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isStartGroupLoading,isStartGroup,isOtherShop,isDeleteLoading,isCheckShopOrder,isAddAndRemoveLoading,isEditOrder,shareLink,cart,const DeepCollectionEquality().hash(_productList));

@override
String toString() {
  return 'ShopOrderState(isLoading: $isLoading, isStartGroupLoading: $isStartGroupLoading, isStartGroup: $isStartGroup, isOtherShop: $isOtherShop, isDeleteLoading: $isDeleteLoading, isCheckShopOrder: $isCheckShopOrder, isAddAndRemoveLoading: $isAddAndRemoveLoading, isEditOrder: $isEditOrder, shareLink: $shareLink, cart: $cart, productList: $productList)';
}


}

/// @nodoc
abstract mixin class _$ShopOrderStateCopyWith<$Res> implements $ShopOrderStateCopyWith<$Res> {
  factory _$ShopOrderStateCopyWith(_ShopOrderState value, $Res Function(_ShopOrderState) _then) = __$ShopOrderStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isStartGroupLoading, bool isStartGroup, bool isOtherShop, bool isDeleteLoading, bool isCheckShopOrder, bool isAddAndRemoveLoading, bool isEditOrder, String shareLink, Cart? cart, List<CartProductData> productList
});




}
/// @nodoc
class __$ShopOrderStateCopyWithImpl<$Res>
    implements _$ShopOrderStateCopyWith<$Res> {
  __$ShopOrderStateCopyWithImpl(this._self, this._then);

  final _ShopOrderState _self;
  final $Res Function(_ShopOrderState) _then;

/// Create a copy of ShopOrderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isStartGroupLoading = null,Object? isStartGroup = null,Object? isOtherShop = null,Object? isDeleteLoading = null,Object? isCheckShopOrder = null,Object? isAddAndRemoveLoading = null,Object? isEditOrder = null,Object? shareLink = null,Object? cart = freezed,Object? productList = null,}) {
  return _then(_ShopOrderState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isStartGroupLoading: null == isStartGroupLoading ? _self.isStartGroupLoading : isStartGroupLoading // ignore: cast_nullable_to_non_nullable
as bool,isStartGroup: null == isStartGroup ? _self.isStartGroup : isStartGroup // ignore: cast_nullable_to_non_nullable
as bool,isOtherShop: null == isOtherShop ? _self.isOtherShop : isOtherShop // ignore: cast_nullable_to_non_nullable
as bool,isDeleteLoading: null == isDeleteLoading ? _self.isDeleteLoading : isDeleteLoading // ignore: cast_nullable_to_non_nullable
as bool,isCheckShopOrder: null == isCheckShopOrder ? _self.isCheckShopOrder : isCheckShopOrder // ignore: cast_nullable_to_non_nullable
as bool,isAddAndRemoveLoading: null == isAddAndRemoveLoading ? _self.isAddAndRemoveLoading : isAddAndRemoveLoading // ignore: cast_nullable_to_non_nullable
as bool,isEditOrder: null == isEditOrder ? _self.isEditOrder : isEditOrder // ignore: cast_nullable_to_non_nullable
as bool,shareLink: null == shareLink ? _self.shareLink : shareLink // ignore: cast_nullable_to_non_nullable
as String,cart: freezed == cart ? _self.cart : cart // ignore: cast_nullable_to_non_nullable
as Cart?,productList: null == productList ? _self._productList : productList // ignore: cast_nullable_to_non_nullable
as List<CartProductData>,
  ));
}


}

// dart format on
