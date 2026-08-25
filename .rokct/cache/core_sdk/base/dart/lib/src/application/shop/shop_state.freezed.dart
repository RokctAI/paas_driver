// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shop_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShopState {

 bool get isLoading; bool get isFilterLoading; bool get isCategoryLoading; bool get isPopularLoading; bool get isProductLoading; bool get isProductCategoryLoading; bool get isPopularProduct; bool get isBrandsLoading; bool get isLike; bool get showWeekTime; bool get showBranch; bool get isMapLoading; bool get isGroupOrder; bool get isJoinOrder; bool get isSearchEnabled; bool get isTodayWorkingDay; bool get isTomorrowWorkingDay; bool get isNestedScrollDisabled; String get userUuid; String get searchText; TimeOfDay get startTodayTime; TimeOfDay get endTodayTime; int get currentIndex; int get subCategoryIndex; Set<Marker> get shopMarkers; List<LatLng> get polylineCoordinates; ShopData? get shopData;// @Default([]) List<ProductData> products,
// @Default([]) List<ProductData> popularProducts,
 List<ProductData> get categoryProducts; List<All> get allData; List<CategoryData>? get category; List<BrandData>? get brands; List<BranchModel>? get branches; List<String> get brandIds; int get sortIndex;
/// Create a copy of ShopState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopStateCopyWith<ShopState> get copyWith => _$ShopStateCopyWithImpl<ShopState>(this as ShopState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isFilterLoading, isFilterLoading) || other.isFilterLoading == isFilterLoading)&&(identical(other.isCategoryLoading, isCategoryLoading) || other.isCategoryLoading == isCategoryLoading)&&(identical(other.isPopularLoading, isPopularLoading) || other.isPopularLoading == isPopularLoading)&&(identical(other.isProductLoading, isProductLoading) || other.isProductLoading == isProductLoading)&&(identical(other.isProductCategoryLoading, isProductCategoryLoading) || other.isProductCategoryLoading == isProductCategoryLoading)&&(identical(other.isPopularProduct, isPopularProduct) || other.isPopularProduct == isPopularProduct)&&(identical(other.isBrandsLoading, isBrandsLoading) || other.isBrandsLoading == isBrandsLoading)&&(identical(other.isLike, isLike) || other.isLike == isLike)&&(identical(other.showWeekTime, showWeekTime) || other.showWeekTime == showWeekTime)&&(identical(other.showBranch, showBranch) || other.showBranch == showBranch)&&(identical(other.isMapLoading, isMapLoading) || other.isMapLoading == isMapLoading)&&(identical(other.isGroupOrder, isGroupOrder) || other.isGroupOrder == isGroupOrder)&&(identical(other.isJoinOrder, isJoinOrder) || other.isJoinOrder == isJoinOrder)&&(identical(other.isSearchEnabled, isSearchEnabled) || other.isSearchEnabled == isSearchEnabled)&&(identical(other.isTodayWorkingDay, isTodayWorkingDay) || other.isTodayWorkingDay == isTodayWorkingDay)&&(identical(other.isTomorrowWorkingDay, isTomorrowWorkingDay) || other.isTomorrowWorkingDay == isTomorrowWorkingDay)&&(identical(other.isNestedScrollDisabled, isNestedScrollDisabled) || other.isNestedScrollDisabled == isNestedScrollDisabled)&&(identical(other.userUuid, userUuid) || other.userUuid == userUuid)&&(identical(other.searchText, searchText) || other.searchText == searchText)&&(identical(other.startTodayTime, startTodayTime) || other.startTodayTime == startTodayTime)&&(identical(other.endTodayTime, endTodayTime) || other.endTodayTime == endTodayTime)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.subCategoryIndex, subCategoryIndex) || other.subCategoryIndex == subCategoryIndex)&&const DeepCollectionEquality().equals(other.shopMarkers, shopMarkers)&&const DeepCollectionEquality().equals(other.polylineCoordinates, polylineCoordinates)&&(identical(other.shopData, shopData) || other.shopData == shopData)&&const DeepCollectionEquality().equals(other.categoryProducts, categoryProducts)&&const DeepCollectionEquality().equals(other.allData, allData)&&const DeepCollectionEquality().equals(other.category, category)&&const DeepCollectionEquality().equals(other.brands, brands)&&const DeepCollectionEquality().equals(other.branches, branches)&&const DeepCollectionEquality().equals(other.brandIds, brandIds)&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex));
}


@override
int get hashCode => Object.hashAll([runtimeType,isLoading,isFilterLoading,isCategoryLoading,isPopularLoading,isProductLoading,isProductCategoryLoading,isPopularProduct,isBrandsLoading,isLike,showWeekTime,showBranch,isMapLoading,isGroupOrder,isJoinOrder,isSearchEnabled,isTodayWorkingDay,isTomorrowWorkingDay,isNestedScrollDisabled,userUuid,searchText,startTodayTime,endTodayTime,currentIndex,subCategoryIndex,const DeepCollectionEquality().hash(shopMarkers),const DeepCollectionEquality().hash(polylineCoordinates),shopData,const DeepCollectionEquality().hash(categoryProducts),const DeepCollectionEquality().hash(allData),const DeepCollectionEquality().hash(category),const DeepCollectionEquality().hash(brands),const DeepCollectionEquality().hash(branches),const DeepCollectionEquality().hash(brandIds),sortIndex]);

@override
String toString() {
  return 'ShopState(isLoading: $isLoading, isFilterLoading: $isFilterLoading, isCategoryLoading: $isCategoryLoading, isPopularLoading: $isPopularLoading, isProductLoading: $isProductLoading, isProductCategoryLoading: $isProductCategoryLoading, isPopularProduct: $isPopularProduct, isBrandsLoading: $isBrandsLoading, isLike: $isLike, showWeekTime: $showWeekTime, showBranch: $showBranch, isMapLoading: $isMapLoading, isGroupOrder: $isGroupOrder, isJoinOrder: $isJoinOrder, isSearchEnabled: $isSearchEnabled, isTodayWorkingDay: $isTodayWorkingDay, isTomorrowWorkingDay: $isTomorrowWorkingDay, isNestedScrollDisabled: $isNestedScrollDisabled, userUuid: $userUuid, searchText: $searchText, startTodayTime: $startTodayTime, endTodayTime: $endTodayTime, currentIndex: $currentIndex, subCategoryIndex: $subCategoryIndex, shopMarkers: $shopMarkers, polylineCoordinates: $polylineCoordinates, shopData: $shopData, categoryProducts: $categoryProducts, allData: $allData, category: $category, brands: $brands, branches: $branches, brandIds: $brandIds, sortIndex: $sortIndex)';
}


}

/// @nodoc
abstract mixin class $ShopStateCopyWith<$Res>  {
  factory $ShopStateCopyWith(ShopState value, $Res Function(ShopState) _then) = _$ShopStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isFilterLoading, bool isCategoryLoading, bool isPopularLoading, bool isProductLoading, bool isProductCategoryLoading, bool isPopularProduct, bool isBrandsLoading, bool isLike, bool showWeekTime, bool showBranch, bool isMapLoading, bool isGroupOrder, bool isJoinOrder, bool isSearchEnabled, bool isTodayWorkingDay, bool isTomorrowWorkingDay, bool isNestedScrollDisabled, String userUuid, String searchText, TimeOfDay startTodayTime, TimeOfDay endTodayTime, int currentIndex, int subCategoryIndex, Set<Marker> shopMarkers, List<LatLng> polylineCoordinates, ShopData? shopData, List<ProductData> categoryProducts, List<All> allData, List<CategoryData>? category, List<BrandData>? brands, List<BranchModel>? branches, List<String> brandIds, int sortIndex
});




}
/// @nodoc
class _$ShopStateCopyWithImpl<$Res>
    implements $ShopStateCopyWith<$Res> {
  _$ShopStateCopyWithImpl(this._self, this._then);

  final ShopState _self;
  final $Res Function(ShopState) _then;

/// Create a copy of ShopState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isFilterLoading = null,Object? isCategoryLoading = null,Object? isPopularLoading = null,Object? isProductLoading = null,Object? isProductCategoryLoading = null,Object? isPopularProduct = null,Object? isBrandsLoading = null,Object? isLike = null,Object? showWeekTime = null,Object? showBranch = null,Object? isMapLoading = null,Object? isGroupOrder = null,Object? isJoinOrder = null,Object? isSearchEnabled = null,Object? isTodayWorkingDay = null,Object? isTomorrowWorkingDay = null,Object? isNestedScrollDisabled = null,Object? userUuid = null,Object? searchText = null,Object? startTodayTime = null,Object? endTodayTime = null,Object? currentIndex = null,Object? subCategoryIndex = null,Object? shopMarkers = null,Object? polylineCoordinates = null,Object? shopData = freezed,Object? categoryProducts = null,Object? allData = null,Object? category = freezed,Object? brands = freezed,Object? branches = freezed,Object? brandIds = null,Object? sortIndex = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isFilterLoading: null == isFilterLoading ? _self.isFilterLoading : isFilterLoading // ignore: cast_nullable_to_non_nullable
as bool,isCategoryLoading: null == isCategoryLoading ? _self.isCategoryLoading : isCategoryLoading // ignore: cast_nullable_to_non_nullable
as bool,isPopularLoading: null == isPopularLoading ? _self.isPopularLoading : isPopularLoading // ignore: cast_nullable_to_non_nullable
as bool,isProductLoading: null == isProductLoading ? _self.isProductLoading : isProductLoading // ignore: cast_nullable_to_non_nullable
as bool,isProductCategoryLoading: null == isProductCategoryLoading ? _self.isProductCategoryLoading : isProductCategoryLoading // ignore: cast_nullable_to_non_nullable
as bool,isPopularProduct: null == isPopularProduct ? _self.isPopularProduct : isPopularProduct // ignore: cast_nullable_to_non_nullable
as bool,isBrandsLoading: null == isBrandsLoading ? _self.isBrandsLoading : isBrandsLoading // ignore: cast_nullable_to_non_nullable
as bool,isLike: null == isLike ? _self.isLike : isLike // ignore: cast_nullable_to_non_nullable
as bool,showWeekTime: null == showWeekTime ? _self.showWeekTime : showWeekTime // ignore: cast_nullable_to_non_nullable
as bool,showBranch: null == showBranch ? _self.showBranch : showBranch // ignore: cast_nullable_to_non_nullable
as bool,isMapLoading: null == isMapLoading ? _self.isMapLoading : isMapLoading // ignore: cast_nullable_to_non_nullable
as bool,isGroupOrder: null == isGroupOrder ? _self.isGroupOrder : isGroupOrder // ignore: cast_nullable_to_non_nullable
as bool,isJoinOrder: null == isJoinOrder ? _self.isJoinOrder : isJoinOrder // ignore: cast_nullable_to_non_nullable
as bool,isSearchEnabled: null == isSearchEnabled ? _self.isSearchEnabled : isSearchEnabled // ignore: cast_nullable_to_non_nullable
as bool,isTodayWorkingDay: null == isTodayWorkingDay ? _self.isTodayWorkingDay : isTodayWorkingDay // ignore: cast_nullable_to_non_nullable
as bool,isTomorrowWorkingDay: null == isTomorrowWorkingDay ? _self.isTomorrowWorkingDay : isTomorrowWorkingDay // ignore: cast_nullable_to_non_nullable
as bool,isNestedScrollDisabled: null == isNestedScrollDisabled ? _self.isNestedScrollDisabled : isNestedScrollDisabled // ignore: cast_nullable_to_non_nullable
as bool,userUuid: null == userUuid ? _self.userUuid : userUuid // ignore: cast_nullable_to_non_nullable
as String,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,startTodayTime: null == startTodayTime ? _self.startTodayTime : startTodayTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,endTodayTime: null == endTodayTime ? _self.endTodayTime : endTodayTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,subCategoryIndex: null == subCategoryIndex ? _self.subCategoryIndex : subCategoryIndex // ignore: cast_nullable_to_non_nullable
as int,shopMarkers: null == shopMarkers ? _self.shopMarkers : shopMarkers // ignore: cast_nullable_to_non_nullable
as Set<Marker>,polylineCoordinates: null == polylineCoordinates ? _self.polylineCoordinates : polylineCoordinates // ignore: cast_nullable_to_non_nullable
as List<LatLng>,shopData: freezed == shopData ? _self.shopData : shopData // ignore: cast_nullable_to_non_nullable
as ShopData?,categoryProducts: null == categoryProducts ? _self.categoryProducts : categoryProducts // ignore: cast_nullable_to_non_nullable
as List<ProductData>,allData: null == allData ? _self.allData : allData // ignore: cast_nullable_to_non_nullable
as List<All>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as List<CategoryData>?,brands: freezed == brands ? _self.brands : brands // ignore: cast_nullable_to_non_nullable
as List<BrandData>?,branches: freezed == branches ? _self.branches : branches // ignore: cast_nullable_to_non_nullable
as List<BranchModel>?,brandIds: null == brandIds ? _self.brandIds : brandIds // ignore: cast_nullable_to_non_nullable
as List<String>,sortIndex: null == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ShopState].
extension ShopStatePatterns on ShopState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShopState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShopState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShopState value)  $default,){
final _that = this;
switch (_that) {
case _ShopState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShopState value)?  $default,){
final _that = this;
switch (_that) {
case _ShopState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isFilterLoading,  bool isCategoryLoading,  bool isPopularLoading,  bool isProductLoading,  bool isProductCategoryLoading,  bool isPopularProduct,  bool isBrandsLoading,  bool isLike,  bool showWeekTime,  bool showBranch,  bool isMapLoading,  bool isGroupOrder,  bool isJoinOrder,  bool isSearchEnabled,  bool isTodayWorkingDay,  bool isTomorrowWorkingDay,  bool isNestedScrollDisabled,  String userUuid,  String searchText,  TimeOfDay startTodayTime,  TimeOfDay endTodayTime,  int currentIndex,  int subCategoryIndex,  Set<Marker> shopMarkers,  List<LatLng> polylineCoordinates,  ShopData? shopData,  List<ProductData> categoryProducts,  List<All> allData,  List<CategoryData>? category,  List<BrandData>? brands,  List<BranchModel>? branches,  List<String> brandIds,  int sortIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShopState() when $default != null:
return $default(_that.isLoading,_that.isFilterLoading,_that.isCategoryLoading,_that.isPopularLoading,_that.isProductLoading,_that.isProductCategoryLoading,_that.isPopularProduct,_that.isBrandsLoading,_that.isLike,_that.showWeekTime,_that.showBranch,_that.isMapLoading,_that.isGroupOrder,_that.isJoinOrder,_that.isSearchEnabled,_that.isTodayWorkingDay,_that.isTomorrowWorkingDay,_that.isNestedScrollDisabled,_that.userUuid,_that.searchText,_that.startTodayTime,_that.endTodayTime,_that.currentIndex,_that.subCategoryIndex,_that.shopMarkers,_that.polylineCoordinates,_that.shopData,_that.categoryProducts,_that.allData,_that.category,_that.brands,_that.branches,_that.brandIds,_that.sortIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isFilterLoading,  bool isCategoryLoading,  bool isPopularLoading,  bool isProductLoading,  bool isProductCategoryLoading,  bool isPopularProduct,  bool isBrandsLoading,  bool isLike,  bool showWeekTime,  bool showBranch,  bool isMapLoading,  bool isGroupOrder,  bool isJoinOrder,  bool isSearchEnabled,  bool isTodayWorkingDay,  bool isTomorrowWorkingDay,  bool isNestedScrollDisabled,  String userUuid,  String searchText,  TimeOfDay startTodayTime,  TimeOfDay endTodayTime,  int currentIndex,  int subCategoryIndex,  Set<Marker> shopMarkers,  List<LatLng> polylineCoordinates,  ShopData? shopData,  List<ProductData> categoryProducts,  List<All> allData,  List<CategoryData>? category,  List<BrandData>? brands,  List<BranchModel>? branches,  List<String> brandIds,  int sortIndex)  $default,) {final _that = this;
switch (_that) {
case _ShopState():
return $default(_that.isLoading,_that.isFilterLoading,_that.isCategoryLoading,_that.isPopularLoading,_that.isProductLoading,_that.isProductCategoryLoading,_that.isPopularProduct,_that.isBrandsLoading,_that.isLike,_that.showWeekTime,_that.showBranch,_that.isMapLoading,_that.isGroupOrder,_that.isJoinOrder,_that.isSearchEnabled,_that.isTodayWorkingDay,_that.isTomorrowWorkingDay,_that.isNestedScrollDisabled,_that.userUuid,_that.searchText,_that.startTodayTime,_that.endTodayTime,_that.currentIndex,_that.subCategoryIndex,_that.shopMarkers,_that.polylineCoordinates,_that.shopData,_that.categoryProducts,_that.allData,_that.category,_that.brands,_that.branches,_that.brandIds,_that.sortIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isFilterLoading,  bool isCategoryLoading,  bool isPopularLoading,  bool isProductLoading,  bool isProductCategoryLoading,  bool isPopularProduct,  bool isBrandsLoading,  bool isLike,  bool showWeekTime,  bool showBranch,  bool isMapLoading,  bool isGroupOrder,  bool isJoinOrder,  bool isSearchEnabled,  bool isTodayWorkingDay,  bool isTomorrowWorkingDay,  bool isNestedScrollDisabled,  String userUuid,  String searchText,  TimeOfDay startTodayTime,  TimeOfDay endTodayTime,  int currentIndex,  int subCategoryIndex,  Set<Marker> shopMarkers,  List<LatLng> polylineCoordinates,  ShopData? shopData,  List<ProductData> categoryProducts,  List<All> allData,  List<CategoryData>? category,  List<BrandData>? brands,  List<BranchModel>? branches,  List<String> brandIds,  int sortIndex)?  $default,) {final _that = this;
switch (_that) {
case _ShopState() when $default != null:
return $default(_that.isLoading,_that.isFilterLoading,_that.isCategoryLoading,_that.isPopularLoading,_that.isProductLoading,_that.isProductCategoryLoading,_that.isPopularProduct,_that.isBrandsLoading,_that.isLike,_that.showWeekTime,_that.showBranch,_that.isMapLoading,_that.isGroupOrder,_that.isJoinOrder,_that.isSearchEnabled,_that.isTodayWorkingDay,_that.isTomorrowWorkingDay,_that.isNestedScrollDisabled,_that.userUuid,_that.searchText,_that.startTodayTime,_that.endTodayTime,_that.currentIndex,_that.subCategoryIndex,_that.shopMarkers,_that.polylineCoordinates,_that.shopData,_that.categoryProducts,_that.allData,_that.category,_that.brands,_that.branches,_that.brandIds,_that.sortIndex);case _:
  return null;

}
}

}

/// @nodoc


class _ShopState extends ShopState {
  const _ShopState({this.isLoading = false, this.isFilterLoading = false, this.isCategoryLoading = true, this.isPopularLoading = true, this.isProductLoading = true, this.isProductCategoryLoading = false, this.isPopularProduct = false, this.isBrandsLoading = true, this.isLike = false, this.showWeekTime = false, this.showBranch = false, this.isMapLoading = false, this.isGroupOrder = false, this.isJoinOrder = false, this.isSearchEnabled = false, this.isTodayWorkingDay = false, this.isTomorrowWorkingDay = false, this.isNestedScrollDisabled = false, this.userUuid = "", this.searchText = "", this.startTodayTime = const TimeOfDay(hour: 0, minute: 0), this.endTodayTime = const TimeOfDay(hour: 0, minute: 0), this.currentIndex = 0, this.subCategoryIndex = 0, final  Set<Marker> shopMarkers = const {}, final  List<LatLng> polylineCoordinates = const [], this.shopData = null, final  List<ProductData> categoryProducts = const [], final  List<All> allData = const [], final  List<CategoryData>? category = const [], final  List<BrandData>? brands = const [], final  List<BranchModel>? branches = const [], final  List<String> brandIds = const [], this.sortIndex = 0}): _shopMarkers = shopMarkers,_polylineCoordinates = polylineCoordinates,_categoryProducts = categoryProducts,_allData = allData,_category = category,_brands = brands,_branches = branches,_brandIds = brandIds,super._();
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isFilterLoading;
@override@JsonKey() final  bool isCategoryLoading;
@override@JsonKey() final  bool isPopularLoading;
@override@JsonKey() final  bool isProductLoading;
@override@JsonKey() final  bool isProductCategoryLoading;
@override@JsonKey() final  bool isPopularProduct;
@override@JsonKey() final  bool isBrandsLoading;
@override@JsonKey() final  bool isLike;
@override@JsonKey() final  bool showWeekTime;
@override@JsonKey() final  bool showBranch;
@override@JsonKey() final  bool isMapLoading;
@override@JsonKey() final  bool isGroupOrder;
@override@JsonKey() final  bool isJoinOrder;
@override@JsonKey() final  bool isSearchEnabled;
@override@JsonKey() final  bool isTodayWorkingDay;
@override@JsonKey() final  bool isTomorrowWorkingDay;
@override@JsonKey() final  bool isNestedScrollDisabled;
@override@JsonKey() final  String userUuid;
@override@JsonKey() final  String searchText;
@override@JsonKey() final  TimeOfDay startTodayTime;
@override@JsonKey() final  TimeOfDay endTodayTime;
@override@JsonKey() final  int currentIndex;
@override@JsonKey() final  int subCategoryIndex;
 final  Set<Marker> _shopMarkers;
@override@JsonKey() Set<Marker> get shopMarkers {
  if (_shopMarkers is EqualUnmodifiableSetView) return _shopMarkers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_shopMarkers);
}

 final  List<LatLng> _polylineCoordinates;
@override@JsonKey() List<LatLng> get polylineCoordinates {
  if (_polylineCoordinates is EqualUnmodifiableListView) return _polylineCoordinates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_polylineCoordinates);
}

@override@JsonKey() final  ShopData? shopData;
// @Default([]) List<ProductData> products,
// @Default([]) List<ProductData> popularProducts,
 final  List<ProductData> _categoryProducts;
// @Default([]) List<ProductData> products,
// @Default([]) List<ProductData> popularProducts,
@override@JsonKey() List<ProductData> get categoryProducts {
  if (_categoryProducts is EqualUnmodifiableListView) return _categoryProducts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryProducts);
}

 final  List<All> _allData;
@override@JsonKey() List<All> get allData {
  if (_allData is EqualUnmodifiableListView) return _allData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allData);
}

 final  List<CategoryData>? _category;
@override@JsonKey() List<CategoryData>? get category {
  final value = _category;
  if (value == null) return null;
  if (_category is EqualUnmodifiableListView) return _category;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<BrandData>? _brands;
@override@JsonKey() List<BrandData>? get brands {
  final value = _brands;
  if (value == null) return null;
  if (_brands is EqualUnmodifiableListView) return _brands;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<BranchModel>? _branches;
@override@JsonKey() List<BranchModel>? get branches {
  final value = _branches;
  if (value == null) return null;
  if (_branches is EqualUnmodifiableListView) return _branches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String> _brandIds;
@override@JsonKey() List<String> get brandIds {
  if (_brandIds is EqualUnmodifiableListView) return _brandIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_brandIds);
}

@override@JsonKey() final  int sortIndex;

/// Create a copy of ShopState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShopStateCopyWith<_ShopState> get copyWith => __$ShopStateCopyWithImpl<_ShopState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShopState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isFilterLoading, isFilterLoading) || other.isFilterLoading == isFilterLoading)&&(identical(other.isCategoryLoading, isCategoryLoading) || other.isCategoryLoading == isCategoryLoading)&&(identical(other.isPopularLoading, isPopularLoading) || other.isPopularLoading == isPopularLoading)&&(identical(other.isProductLoading, isProductLoading) || other.isProductLoading == isProductLoading)&&(identical(other.isProductCategoryLoading, isProductCategoryLoading) || other.isProductCategoryLoading == isProductCategoryLoading)&&(identical(other.isPopularProduct, isPopularProduct) || other.isPopularProduct == isPopularProduct)&&(identical(other.isBrandsLoading, isBrandsLoading) || other.isBrandsLoading == isBrandsLoading)&&(identical(other.isLike, isLike) || other.isLike == isLike)&&(identical(other.showWeekTime, showWeekTime) || other.showWeekTime == showWeekTime)&&(identical(other.showBranch, showBranch) || other.showBranch == showBranch)&&(identical(other.isMapLoading, isMapLoading) || other.isMapLoading == isMapLoading)&&(identical(other.isGroupOrder, isGroupOrder) || other.isGroupOrder == isGroupOrder)&&(identical(other.isJoinOrder, isJoinOrder) || other.isJoinOrder == isJoinOrder)&&(identical(other.isSearchEnabled, isSearchEnabled) || other.isSearchEnabled == isSearchEnabled)&&(identical(other.isTodayWorkingDay, isTodayWorkingDay) || other.isTodayWorkingDay == isTodayWorkingDay)&&(identical(other.isTomorrowWorkingDay, isTomorrowWorkingDay) || other.isTomorrowWorkingDay == isTomorrowWorkingDay)&&(identical(other.isNestedScrollDisabled, isNestedScrollDisabled) || other.isNestedScrollDisabled == isNestedScrollDisabled)&&(identical(other.userUuid, userUuid) || other.userUuid == userUuid)&&(identical(other.searchText, searchText) || other.searchText == searchText)&&(identical(other.startTodayTime, startTodayTime) || other.startTodayTime == startTodayTime)&&(identical(other.endTodayTime, endTodayTime) || other.endTodayTime == endTodayTime)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&(identical(other.subCategoryIndex, subCategoryIndex) || other.subCategoryIndex == subCategoryIndex)&&const DeepCollectionEquality().equals(other._shopMarkers, _shopMarkers)&&const DeepCollectionEquality().equals(other._polylineCoordinates, _polylineCoordinates)&&(identical(other.shopData, shopData) || other.shopData == shopData)&&const DeepCollectionEquality().equals(other._categoryProducts, _categoryProducts)&&const DeepCollectionEquality().equals(other._allData, _allData)&&const DeepCollectionEquality().equals(other._category, _category)&&const DeepCollectionEquality().equals(other._brands, _brands)&&const DeepCollectionEquality().equals(other._branches, _branches)&&const DeepCollectionEquality().equals(other._brandIds, _brandIds)&&(identical(other.sortIndex, sortIndex) || other.sortIndex == sortIndex));
}


@override
int get hashCode => Object.hashAll([runtimeType,isLoading,isFilterLoading,isCategoryLoading,isPopularLoading,isProductLoading,isProductCategoryLoading,isPopularProduct,isBrandsLoading,isLike,showWeekTime,showBranch,isMapLoading,isGroupOrder,isJoinOrder,isSearchEnabled,isTodayWorkingDay,isTomorrowWorkingDay,isNestedScrollDisabled,userUuid,searchText,startTodayTime,endTodayTime,currentIndex,subCategoryIndex,const DeepCollectionEquality().hash(_shopMarkers),const DeepCollectionEquality().hash(_polylineCoordinates),shopData,const DeepCollectionEquality().hash(_categoryProducts),const DeepCollectionEquality().hash(_allData),const DeepCollectionEquality().hash(_category),const DeepCollectionEquality().hash(_brands),const DeepCollectionEquality().hash(_branches),const DeepCollectionEquality().hash(_brandIds),sortIndex]);

@override
String toString() {
  return 'ShopState(isLoading: $isLoading, isFilterLoading: $isFilterLoading, isCategoryLoading: $isCategoryLoading, isPopularLoading: $isPopularLoading, isProductLoading: $isProductLoading, isProductCategoryLoading: $isProductCategoryLoading, isPopularProduct: $isPopularProduct, isBrandsLoading: $isBrandsLoading, isLike: $isLike, showWeekTime: $showWeekTime, showBranch: $showBranch, isMapLoading: $isMapLoading, isGroupOrder: $isGroupOrder, isJoinOrder: $isJoinOrder, isSearchEnabled: $isSearchEnabled, isTodayWorkingDay: $isTodayWorkingDay, isTomorrowWorkingDay: $isTomorrowWorkingDay, isNestedScrollDisabled: $isNestedScrollDisabled, userUuid: $userUuid, searchText: $searchText, startTodayTime: $startTodayTime, endTodayTime: $endTodayTime, currentIndex: $currentIndex, subCategoryIndex: $subCategoryIndex, shopMarkers: $shopMarkers, polylineCoordinates: $polylineCoordinates, shopData: $shopData, categoryProducts: $categoryProducts, allData: $allData, category: $category, brands: $brands, branches: $branches, brandIds: $brandIds, sortIndex: $sortIndex)';
}


}

/// @nodoc
abstract mixin class _$ShopStateCopyWith<$Res> implements $ShopStateCopyWith<$Res> {
  factory _$ShopStateCopyWith(_ShopState value, $Res Function(_ShopState) _then) = __$ShopStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isFilterLoading, bool isCategoryLoading, bool isPopularLoading, bool isProductLoading, bool isProductCategoryLoading, bool isPopularProduct, bool isBrandsLoading, bool isLike, bool showWeekTime, bool showBranch, bool isMapLoading, bool isGroupOrder, bool isJoinOrder, bool isSearchEnabled, bool isTodayWorkingDay, bool isTomorrowWorkingDay, bool isNestedScrollDisabled, String userUuid, String searchText, TimeOfDay startTodayTime, TimeOfDay endTodayTime, int currentIndex, int subCategoryIndex, Set<Marker> shopMarkers, List<LatLng> polylineCoordinates, ShopData? shopData, List<ProductData> categoryProducts, List<All> allData, List<CategoryData>? category, List<BrandData>? brands, List<BranchModel>? branches, List<String> brandIds, int sortIndex
});




}
/// @nodoc
class __$ShopStateCopyWithImpl<$Res>
    implements _$ShopStateCopyWith<$Res> {
  __$ShopStateCopyWithImpl(this._self, this._then);

  final _ShopState _self;
  final $Res Function(_ShopState) _then;

/// Create a copy of ShopState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isFilterLoading = null,Object? isCategoryLoading = null,Object? isPopularLoading = null,Object? isProductLoading = null,Object? isProductCategoryLoading = null,Object? isPopularProduct = null,Object? isBrandsLoading = null,Object? isLike = null,Object? showWeekTime = null,Object? showBranch = null,Object? isMapLoading = null,Object? isGroupOrder = null,Object? isJoinOrder = null,Object? isSearchEnabled = null,Object? isTodayWorkingDay = null,Object? isTomorrowWorkingDay = null,Object? isNestedScrollDisabled = null,Object? userUuid = null,Object? searchText = null,Object? startTodayTime = null,Object? endTodayTime = null,Object? currentIndex = null,Object? subCategoryIndex = null,Object? shopMarkers = null,Object? polylineCoordinates = null,Object? shopData = freezed,Object? categoryProducts = null,Object? allData = null,Object? category = freezed,Object? brands = freezed,Object? branches = freezed,Object? brandIds = null,Object? sortIndex = null,}) {
  return _then(_ShopState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isFilterLoading: null == isFilterLoading ? _self.isFilterLoading : isFilterLoading // ignore: cast_nullable_to_non_nullable
as bool,isCategoryLoading: null == isCategoryLoading ? _self.isCategoryLoading : isCategoryLoading // ignore: cast_nullable_to_non_nullable
as bool,isPopularLoading: null == isPopularLoading ? _self.isPopularLoading : isPopularLoading // ignore: cast_nullable_to_non_nullable
as bool,isProductLoading: null == isProductLoading ? _self.isProductLoading : isProductLoading // ignore: cast_nullable_to_non_nullable
as bool,isProductCategoryLoading: null == isProductCategoryLoading ? _self.isProductCategoryLoading : isProductCategoryLoading // ignore: cast_nullable_to_non_nullable
as bool,isPopularProduct: null == isPopularProduct ? _self.isPopularProduct : isPopularProduct // ignore: cast_nullable_to_non_nullable
as bool,isBrandsLoading: null == isBrandsLoading ? _self.isBrandsLoading : isBrandsLoading // ignore: cast_nullable_to_non_nullable
as bool,isLike: null == isLike ? _self.isLike : isLike // ignore: cast_nullable_to_non_nullable
as bool,showWeekTime: null == showWeekTime ? _self.showWeekTime : showWeekTime // ignore: cast_nullable_to_non_nullable
as bool,showBranch: null == showBranch ? _self.showBranch : showBranch // ignore: cast_nullable_to_non_nullable
as bool,isMapLoading: null == isMapLoading ? _self.isMapLoading : isMapLoading // ignore: cast_nullable_to_non_nullable
as bool,isGroupOrder: null == isGroupOrder ? _self.isGroupOrder : isGroupOrder // ignore: cast_nullable_to_non_nullable
as bool,isJoinOrder: null == isJoinOrder ? _self.isJoinOrder : isJoinOrder // ignore: cast_nullable_to_non_nullable
as bool,isSearchEnabled: null == isSearchEnabled ? _self.isSearchEnabled : isSearchEnabled // ignore: cast_nullable_to_non_nullable
as bool,isTodayWorkingDay: null == isTodayWorkingDay ? _self.isTodayWorkingDay : isTodayWorkingDay // ignore: cast_nullable_to_non_nullable
as bool,isTomorrowWorkingDay: null == isTomorrowWorkingDay ? _self.isTomorrowWorkingDay : isTomorrowWorkingDay // ignore: cast_nullable_to_non_nullable
as bool,isNestedScrollDisabled: null == isNestedScrollDisabled ? _self.isNestedScrollDisabled : isNestedScrollDisabled // ignore: cast_nullable_to_non_nullable
as bool,userUuid: null == userUuid ? _self.userUuid : userUuid // ignore: cast_nullable_to_non_nullable
as String,searchText: null == searchText ? _self.searchText : searchText // ignore: cast_nullable_to_non_nullable
as String,startTodayTime: null == startTodayTime ? _self.startTodayTime : startTodayTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,endTodayTime: null == endTodayTime ? _self.endTodayTime : endTodayTime // ignore: cast_nullable_to_non_nullable
as TimeOfDay,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,subCategoryIndex: null == subCategoryIndex ? _self.subCategoryIndex : subCategoryIndex // ignore: cast_nullable_to_non_nullable
as int,shopMarkers: null == shopMarkers ? _self._shopMarkers : shopMarkers // ignore: cast_nullable_to_non_nullable
as Set<Marker>,polylineCoordinates: null == polylineCoordinates ? _self._polylineCoordinates : polylineCoordinates // ignore: cast_nullable_to_non_nullable
as List<LatLng>,shopData: freezed == shopData ? _self.shopData : shopData // ignore: cast_nullable_to_non_nullable
as ShopData?,categoryProducts: null == categoryProducts ? _self._categoryProducts : categoryProducts // ignore: cast_nullable_to_non_nullable
as List<ProductData>,allData: null == allData ? _self._allData : allData // ignore: cast_nullable_to_non_nullable
as List<All>,category: freezed == category ? _self._category : category // ignore: cast_nullable_to_non_nullable
as List<CategoryData>?,brands: freezed == brands ? _self._brands : brands // ignore: cast_nullable_to_non_nullable
as List<BrandData>?,branches: freezed == branches ? _self._branches : branches // ignore: cast_nullable_to_non_nullable
as List<BranchModel>?,brandIds: null == brandIds ? _self._brandIds : brandIds // ignore: cast_nullable_to_non_nullable
as List<String>,sortIndex: null == sortIndex ? _self.sortIndex : sortIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
