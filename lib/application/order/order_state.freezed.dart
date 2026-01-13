// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OrderState {
  bool get isActiveLoading => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isAvailableLoading => throw _privateConstructorUsedError;
  bool get isHistoryLoading => throw _privateConstructorUsedError;
  bool get paymentType => throw _privateConstructorUsedError;
  OrderDetailData? get order => throw _privateConstructorUsedError;
  List<OrderDetailData> get activeOrders => throw _privateConstructorUsedError;
  List<OrderDetailData> get availableOrders =>
      throw _privateConstructorUsedError;
  List<OrderDetailData> get historyOrders => throw _privateConstructorUsedError;
  num get totalActiveOrder => throw _privateConstructorUsedError;
  int get deliveryTime => throw _privateConstructorUsedError;
  int get deliveryType => throw _privateConstructorUsedError;

  /// Create a copy of OrderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderStateCopyWith<OrderState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderStateCopyWith<$Res> {
  factory $OrderStateCopyWith(
          OrderState value, $Res Function(OrderState) then) =
      _$OrderStateCopyWithImpl<$Res, OrderState>;
  @useResult
  $Res call(
      {bool isActiveLoading,
      bool isLoading,
      bool isAvailableLoading,
      bool isHistoryLoading,
      bool paymentType,
      OrderDetailData? order,
      List<OrderDetailData> activeOrders,
      List<OrderDetailData> availableOrders,
      List<OrderDetailData> historyOrders,
      num totalActiveOrder,
      int deliveryTime,
      int deliveryType});
}

/// @nodoc
class _$OrderStateCopyWithImpl<$Res, $Val extends OrderState>
    implements $OrderStateCopyWith<$Res> {
  _$OrderStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isActiveLoading = null,
    Object? isLoading = null,
    Object? isAvailableLoading = null,
    Object? isHistoryLoading = null,
    Object? paymentType = null,
    Object? order = freezed,
    Object? activeOrders = null,
    Object? availableOrders = null,
    Object? historyOrders = null,
    Object? totalActiveOrder = null,
    Object? deliveryTime = null,
    Object? deliveryType = null,
  }) {
    return _then(_value.copyWith(
      isActiveLoading: null == isActiveLoading
          ? _value.isActiveLoading
          : isActiveLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAvailableLoading: null == isAvailableLoading
          ? _value.isAvailableLoading
          : isAvailableLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isHistoryLoading: null == isHistoryLoading
          ? _value.isHistoryLoading
          : isHistoryLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentType: null == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as bool,
      order: freezed == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as OrderDetailData?,
      activeOrders: null == activeOrders
          ? _value.activeOrders
          : activeOrders // ignore: cast_nullable_to_non_nullable
              as List<OrderDetailData>,
      availableOrders: null == availableOrders
          ? _value.availableOrders
          : availableOrders // ignore: cast_nullable_to_non_nullable
              as List<OrderDetailData>,
      historyOrders: null == historyOrders
          ? _value.historyOrders
          : historyOrders // ignore: cast_nullable_to_non_nullable
              as List<OrderDetailData>,
      totalActiveOrder: null == totalActiveOrder
          ? _value.totalActiveOrder
          : totalActiveOrder // ignore: cast_nullable_to_non_nullable
              as num,
      deliveryTime: null == deliveryTime
          ? _value.deliveryTime
          : deliveryTime // ignore: cast_nullable_to_non_nullable
              as int,
      deliveryType: null == deliveryType
          ? _value.deliveryType
          : deliveryType // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrdrStateImplCopyWith<$Res>
    implements $OrderStateCopyWith<$Res> {
  factory _$$OrdrStateImplCopyWith(
          _$OrdrStateImpl value, $Res Function(_$OrdrStateImpl) then) =
      __$$OrdrStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isActiveLoading,
      bool isLoading,
      bool isAvailableLoading,
      bool isHistoryLoading,
      bool paymentType,
      OrderDetailData? order,
      List<OrderDetailData> activeOrders,
      List<OrderDetailData> availableOrders,
      List<OrderDetailData> historyOrders,
      num totalActiveOrder,
      int deliveryTime,
      int deliveryType});
}

/// @nodoc
class __$$OrdrStateImplCopyWithImpl<$Res>
    extends _$OrderStateCopyWithImpl<$Res, _$OrdrStateImpl>
    implements _$$OrdrStateImplCopyWith<$Res> {
  __$$OrdrStateImplCopyWithImpl(
      _$OrdrStateImpl _value, $Res Function(_$OrdrStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isActiveLoading = null,
    Object? isLoading = null,
    Object? isAvailableLoading = null,
    Object? isHistoryLoading = null,
    Object? paymentType = null,
    Object? order = freezed,
    Object? activeOrders = null,
    Object? availableOrders = null,
    Object? historyOrders = null,
    Object? totalActiveOrder = null,
    Object? deliveryTime = null,
    Object? deliveryType = null,
  }) {
    return _then(_$OrdrStateImpl(
      isActiveLoading: null == isActiveLoading
          ? _value.isActiveLoading
          : isActiveLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAvailableLoading: null == isAvailableLoading
          ? _value.isAvailableLoading
          : isAvailableLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isHistoryLoading: null == isHistoryLoading
          ? _value.isHistoryLoading
          : isHistoryLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      paymentType: null == paymentType
          ? _value.paymentType
          : paymentType // ignore: cast_nullable_to_non_nullable
              as bool,
      order: freezed == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as OrderDetailData?,
      activeOrders: null == activeOrders
          ? _value._activeOrders
          : activeOrders // ignore: cast_nullable_to_non_nullable
              as List<OrderDetailData>,
      availableOrders: null == availableOrders
          ? _value._availableOrders
          : availableOrders // ignore: cast_nullable_to_non_nullable
              as List<OrderDetailData>,
      historyOrders: null == historyOrders
          ? _value._historyOrders
          : historyOrders // ignore: cast_nullable_to_non_nullable
              as List<OrderDetailData>,
      totalActiveOrder: null == totalActiveOrder
          ? _value.totalActiveOrder
          : totalActiveOrder // ignore: cast_nullable_to_non_nullable
              as num,
      deliveryTime: null == deliveryTime
          ? _value.deliveryTime
          : deliveryTime // ignore: cast_nullable_to_non_nullable
              as int,
      deliveryType: null == deliveryType
          ? _value.deliveryType
          : deliveryType // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$OrdrStateImpl extends _OrdrState {
  const _$OrdrStateImpl(
      {this.isActiveLoading = false,
      this.isLoading = false,
      this.isAvailableLoading = false,
      this.isHistoryLoading = false,
      this.paymentType = false,
      this.order = null,
      final List<OrderDetailData> activeOrders = const [],
      final List<OrderDetailData> availableOrders = const [],
      final List<OrderDetailData> historyOrders = const [],
      this.totalActiveOrder = 0,
      this.deliveryTime = 0,
      this.deliveryType = 0})
      : _activeOrders = activeOrders,
        _availableOrders = availableOrders,
        _historyOrders = historyOrders,
        super._();

  @override
  @JsonKey()
  final bool isActiveLoading;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isAvailableLoading;
  @override
  @JsonKey()
  final bool isHistoryLoading;
  @override
  @JsonKey()
  final bool paymentType;
  @override
  @JsonKey()
  final OrderDetailData? order;
  final List<OrderDetailData> _activeOrders;
  @override
  @JsonKey()
  List<OrderDetailData> get activeOrders {
    if (_activeOrders is EqualUnmodifiableListView) return _activeOrders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeOrders);
  }

  final List<OrderDetailData> _availableOrders;
  @override
  @JsonKey()
  List<OrderDetailData> get availableOrders {
    if (_availableOrders is EqualUnmodifiableListView) return _availableOrders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableOrders);
  }

  final List<OrderDetailData> _historyOrders;
  @override
  @JsonKey()
  List<OrderDetailData> get historyOrders {
    if (_historyOrders is EqualUnmodifiableListView) return _historyOrders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_historyOrders);
  }

  @override
  @JsonKey()
  final num totalActiveOrder;
  @override
  @JsonKey()
  final int deliveryTime;
  @override
  @JsonKey()
  final int deliveryType;

  @override
  String toString() {
    return 'OrderState(isActiveLoading: $isActiveLoading, isLoading: $isLoading, isAvailableLoading: $isAvailableLoading, isHistoryLoading: $isHistoryLoading, paymentType: $paymentType, order: $order, activeOrders: $activeOrders, availableOrders: $availableOrders, historyOrders: $historyOrders, totalActiveOrder: $totalActiveOrder, deliveryTime: $deliveryTime, deliveryType: $deliveryType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrdrStateImpl &&
            (identical(other.isActiveLoading, isActiveLoading) ||
                other.isActiveLoading == isActiveLoading) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isAvailableLoading, isAvailableLoading) ||
                other.isAvailableLoading == isAvailableLoading) &&
            (identical(other.isHistoryLoading, isHistoryLoading) ||
                other.isHistoryLoading == isHistoryLoading) &&
            (identical(other.paymentType, paymentType) ||
                other.paymentType == paymentType) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality()
                .equals(other._activeOrders, _activeOrders) &&
            const DeepCollectionEquality()
                .equals(other._availableOrders, _availableOrders) &&
            const DeepCollectionEquality()
                .equals(other._historyOrders, _historyOrders) &&
            (identical(other.totalActiveOrder, totalActiveOrder) ||
                other.totalActiveOrder == totalActiveOrder) &&
            (identical(other.deliveryTime, deliveryTime) ||
                other.deliveryTime == deliveryTime) &&
            (identical(other.deliveryType, deliveryType) ||
                other.deliveryType == deliveryType));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isActiveLoading,
      isLoading,
      isAvailableLoading,
      isHistoryLoading,
      paymentType,
      order,
      const DeepCollectionEquality().hash(_activeOrders),
      const DeepCollectionEquality().hash(_availableOrders),
      const DeepCollectionEquality().hash(_historyOrders),
      totalActiveOrder,
      deliveryTime,
      deliveryType);

  /// Create a copy of OrderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrdrStateImplCopyWith<_$OrdrStateImpl> get copyWith =>
      __$$OrdrStateImplCopyWithImpl<_$OrdrStateImpl>(this, _$identity);
}

abstract class _OrdrState extends OrderState {
  const factory _OrdrState(
      {final bool isActiveLoading,
      final bool isLoading,
      final bool isAvailableLoading,
      final bool isHistoryLoading,
      final bool paymentType,
      final OrderDetailData? order,
      final List<OrderDetailData> activeOrders,
      final List<OrderDetailData> availableOrders,
      final List<OrderDetailData> historyOrders,
      final num totalActiveOrder,
      final int deliveryTime,
      final int deliveryType}) = _$OrdrStateImpl;
  const _OrdrState._() : super._();

  @override
  bool get isActiveLoading;
  @override
  bool get isLoading;
  @override
  bool get isAvailableLoading;
  @override
  bool get isHistoryLoading;
  @override
  bool get paymentType;
  @override
  OrderDetailData? get order;
  @override
  List<OrderDetailData> get activeOrders;
  @override
  List<OrderDetailData> get availableOrders;
  @override
  List<OrderDetailData> get historyOrders;
  @override
  num get totalActiveOrder;
  @override
  int get deliveryTime;
  @override
  int get deliveryType;

  /// Create a copy of OrderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrdrStateImplCopyWith<_$OrdrStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
