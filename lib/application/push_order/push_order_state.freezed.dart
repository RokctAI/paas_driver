// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_order_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PushOrderState {
  bool get isTimeOut => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String get timerText => throw _privateConstructorUsedError;

  /// Create a copy of PushOrderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PushOrderStateCopyWith<PushOrderState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PushOrderStateCopyWith<$Res> {
  factory $PushOrderStateCopyWith(
          PushOrderState value, $Res Function(PushOrderState) then) =
      _$PushOrderStateCopyWithImpl<$Res, PushOrderState>;
  @useResult
  $Res call({bool isTimeOut, bool isLoading, String timerText});
}

/// @nodoc
class _$PushOrderStateCopyWithImpl<$Res, $Val extends PushOrderState>
    implements $PushOrderStateCopyWith<$Res> {
  _$PushOrderStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PushOrderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isTimeOut = null,
    Object? isLoading = null,
    Object? timerText = null,
  }) {
    return _then(_value.copyWith(
      isTimeOut: null == isTimeOut
          ? _value.isTimeOut
          : isTimeOut // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      timerText: null == timerText
          ? _value.timerText
          : timerText // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PushOrderStateImplCopyWith<$Res>
    implements $PushOrderStateCopyWith<$Res> {
  factory _$$PushOrderStateImplCopyWith(_$PushOrderStateImpl value,
          $Res Function(_$PushOrderStateImpl) then) =
      __$$PushOrderStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isTimeOut, bool isLoading, String timerText});
}

/// @nodoc
class __$$PushOrderStateImplCopyWithImpl<$Res>
    extends _$PushOrderStateCopyWithImpl<$Res, _$PushOrderStateImpl>
    implements _$$PushOrderStateImplCopyWith<$Res> {
  __$$PushOrderStateImplCopyWithImpl(
      _$PushOrderStateImpl _value, $Res Function(_$PushOrderStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PushOrderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isTimeOut = null,
    Object? isLoading = null,
    Object? timerText = null,
  }) {
    return _then(_$PushOrderStateImpl(
      isTimeOut: null == isTimeOut
          ? _value.isTimeOut
          : isTimeOut // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      timerText: null == timerText
          ? _value.timerText
          : timerText // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PushOrderStateImpl extends _PushOrderState {
  const _$PushOrderStateImpl(
      {this.isTimeOut = false, this.isLoading = false, this.timerText = '0 s'})
      : super._();

  @override
  @JsonKey()
  final bool isTimeOut;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final String timerText;

  @override
  String toString() {
    return 'PushOrderState(isTimeOut: $isTimeOut, isLoading: $isLoading, timerText: $timerText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PushOrderStateImpl &&
            (identical(other.isTimeOut, isTimeOut) ||
                other.isTimeOut == isTimeOut) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.timerText, timerText) ||
                other.timerText == timerText));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isTimeOut, isLoading, timerText);

  /// Create a copy of PushOrderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PushOrderStateImplCopyWith<_$PushOrderStateImpl> get copyWith =>
      __$$PushOrderStateImplCopyWithImpl<_$PushOrderStateImpl>(
          this, _$identity);
}

abstract class _PushOrderState extends PushOrderState {
  const factory _PushOrderState(
      {final bool isTimeOut,
      final bool isLoading,
      final String timerText}) = _$PushOrderStateImpl;
  const _PushOrderState._() : super._();

  @override
  bool get isTimeOut;
  @override
  bool get isLoading;
  @override
  String get timerText;

  /// Create a copy of PushOrderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PushOrderStateImplCopyWith<_$PushOrderStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
