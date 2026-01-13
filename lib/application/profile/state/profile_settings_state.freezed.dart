// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProfileSettingsState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isStatisticLoading => throw _privateConstructorUsedError;
  UserData? get userData => throw _privateConstructorUsedError;
  RequestModelData? get requestData => throw _privateConstructorUsedError;
  StatisticsResponse? get statistics => throw _privateConstructorUsedError;

  /// Create a copy of ProfileSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileSettingsStateCopyWith<ProfileSettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileSettingsStateCopyWith<$Res> {
  factory $ProfileSettingsStateCopyWith(ProfileSettingsState value,
          $Res Function(ProfileSettingsState) then) =
      _$ProfileSettingsStateCopyWithImpl<$Res, ProfileSettingsState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isStatisticLoading,
      UserData? userData,
      RequestModelData? requestData,
      StatisticsResponse? statistics});
}

/// @nodoc
class _$ProfileSettingsStateCopyWithImpl<$Res,
        $Val extends ProfileSettingsState>
    implements $ProfileSettingsStateCopyWith<$Res> {
  _$ProfileSettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isStatisticLoading = null,
    Object? userData = freezed,
    Object? requestData = freezed,
    Object? statistics = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isStatisticLoading: null == isStatisticLoading
          ? _value.isStatisticLoading
          : isStatisticLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      userData: freezed == userData
          ? _value.userData
          : userData // ignore: cast_nullable_to_non_nullable
              as UserData?,
      requestData: freezed == requestData
          ? _value.requestData
          : requestData // ignore: cast_nullable_to_non_nullable
              as RequestModelData?,
      statistics: freezed == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as StatisticsResponse?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileSettingsStateImplCopyWith<$Res>
    implements $ProfileSettingsStateCopyWith<$Res> {
  factory _$$ProfileSettingsStateImplCopyWith(_$ProfileSettingsStateImpl value,
          $Res Function(_$ProfileSettingsStateImpl) then) =
      __$$ProfileSettingsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isStatisticLoading,
      UserData? userData,
      RequestModelData? requestData,
      StatisticsResponse? statistics});
}

/// @nodoc
class __$$ProfileSettingsStateImplCopyWithImpl<$Res>
    extends _$ProfileSettingsStateCopyWithImpl<$Res, _$ProfileSettingsStateImpl>
    implements _$$ProfileSettingsStateImplCopyWith<$Res> {
  __$$ProfileSettingsStateImplCopyWithImpl(_$ProfileSettingsStateImpl _value,
      $Res Function(_$ProfileSettingsStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isStatisticLoading = null,
    Object? userData = freezed,
    Object? requestData = freezed,
    Object? statistics = freezed,
  }) {
    return _then(_$ProfileSettingsStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isStatisticLoading: null == isStatisticLoading
          ? _value.isStatisticLoading
          : isStatisticLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      userData: freezed == userData
          ? _value.userData
          : userData // ignore: cast_nullable_to_non_nullable
              as UserData?,
      requestData: freezed == requestData
          ? _value.requestData
          : requestData // ignore: cast_nullable_to_non_nullable
              as RequestModelData?,
      statistics: freezed == statistics
          ? _value.statistics
          : statistics // ignore: cast_nullable_to_non_nullable
              as StatisticsResponse?,
    ));
  }
}

/// @nodoc

class _$ProfileSettingsStateImpl extends _ProfileSettingsState {
  const _$ProfileSettingsStateImpl(
      {this.isLoading = false,
      this.isStatisticLoading = false,
      this.userData,
      this.requestData,
      this.statistics})
      : super._();

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isStatisticLoading;
  @override
  final UserData? userData;
  @override
  final RequestModelData? requestData;
  @override
  final StatisticsResponse? statistics;

  @override
  String toString() {
    return 'ProfileSettingsState(isLoading: $isLoading, isStatisticLoading: $isStatisticLoading, userData: $userData, requestData: $requestData, statistics: $statistics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileSettingsStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isStatisticLoading, isStatisticLoading) ||
                other.isStatisticLoading == isStatisticLoading) &&
            (identical(other.userData, userData) ||
                other.userData == userData) &&
            (identical(other.requestData, requestData) ||
                other.requestData == requestData) &&
            (identical(other.statistics, statistics) ||
                other.statistics == statistics));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isLoading, isStatisticLoading,
      userData, requestData, statistics);

  /// Create a copy of ProfileSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileSettingsStateImplCopyWith<_$ProfileSettingsStateImpl>
      get copyWith =>
          __$$ProfileSettingsStateImplCopyWithImpl<_$ProfileSettingsStateImpl>(
              this, _$identity);
}

abstract class _ProfileSettingsState extends ProfileSettingsState {
  const factory _ProfileSettingsState(
      {final bool isLoading,
      final bool isStatisticLoading,
      final UserData? userData,
      final RequestModelData? requestData,
      final StatisticsResponse? statistics}) = _$ProfileSettingsStateImpl;
  const _ProfileSettingsState._() : super._();

  @override
  bool get isLoading;
  @override
  bool get isStatisticLoading;
  @override
  UserData? get userData;
  @override
  RequestModelData? get requestData;
  @override
  StatisticsResponse? get statistics;

  /// Create a copy of ProfileSettingsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileSettingsStateImplCopyWith<_$ProfileSettingsStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
