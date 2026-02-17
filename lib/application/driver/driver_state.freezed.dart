// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DriverState {
  DeliveryResponse? get driverData => throw _privateConstructorUsedError;

  /// Create a copy of DriverState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DriverStateCopyWith<DriverState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DriverStateCopyWith<$Res> {
  factory $DriverStateCopyWith(
          DriverState value, $Res Function(DriverState) then) =
      _$DriverStateCopyWithImpl<$Res, DriverState>;
  @useResult
  $Res call({DeliveryResponse? driverData});
}

/// @nodoc
class _$DriverStateCopyWithImpl<$Res, $Val extends DriverState>
    implements $DriverStateCopyWith<$Res> {
  _$DriverStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DriverState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverData = freezed,
  }) {
    return _then(_value.copyWith(
      driverData: freezed == driverData
          ? _value.driverData
          : driverData // ignore: cast_nullable_to_non_nullable
              as DeliveryResponse?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DriverStateImplCopyWith<$Res>
    implements $DriverStateCopyWith<$Res> {
  factory _$$DriverStateImplCopyWith(
          _$DriverStateImpl value, $Res Function(_$DriverStateImpl) then) =
      __$$DriverStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DeliveryResponse? driverData});
}

/// @nodoc
class __$$DriverStateImplCopyWithImpl<$Res>
    extends _$DriverStateCopyWithImpl<$Res, _$DriverStateImpl>
    implements _$$DriverStateImplCopyWith<$Res> {
  __$$DriverStateImplCopyWithImpl(
      _$DriverStateImpl _value, $Res Function(_$DriverStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of DriverState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? driverData = freezed,
  }) {
    return _then(_$DriverStateImpl(
      driverData: freezed == driverData
          ? _value.driverData
          : driverData // ignore: cast_nullable_to_non_nullable
              as DeliveryResponse?,
    ));
  }
}

/// @nodoc

class _$DriverStateImpl extends _DriverState {
  const _$DriverStateImpl({this.driverData}) : super._();

  @override
  final DeliveryResponse? driverData;

  @override
  String toString() {
    return 'DriverState(driverData: $driverData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DriverStateImpl &&
            (identical(other.driverData, driverData) ||
                other.driverData == driverData));
  }

  @override
  int get hashCode => Object.hash(runtimeType, driverData);

  /// Create a copy of DriverState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DriverStateImplCopyWith<_$DriverStateImpl> get copyWith =>
      __$$DriverStateImplCopyWithImpl<_$DriverStateImpl>(this, _$identity);
}

abstract class _DriverState extends DriverState {
  const factory _DriverState({final DeliveryResponse? driverData}) =
      _$DriverStateImpl;
  const _DriverState._() : super._();

  @override
  DeliveryResponse? get driverData;

  /// Create a copy of DriverState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DriverStateImplCopyWith<_$DriverStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
