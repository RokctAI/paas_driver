// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_image_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ProfileImageState {
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get carImageUrl => throw _privateConstructorUsedError;
  String? get path => throw _privateConstructorUsedError;

  /// Create a copy of ProfileImageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileImageStateCopyWith<ProfileImageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileImageStateCopyWith<$Res> {
  factory $ProfileImageStateCopyWith(
          ProfileImageState value, $Res Function(ProfileImageState) then) =
      _$ProfileImageStateCopyWithImpl<$Res, ProfileImageState>;
  @useResult
  $Res call({String? imageUrl, String? carImageUrl, String? path});
}

/// @nodoc
class _$ProfileImageStateCopyWithImpl<$Res, $Val extends ProfileImageState>
    implements $ProfileImageStateCopyWith<$Res> {
  _$ProfileImageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileImageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageUrl = freezed,
    Object? carImageUrl = freezed,
    Object? path = freezed,
  }) {
    return _then(_value.copyWith(
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      carImageUrl: freezed == carImageUrl
          ? _value.carImageUrl
          : carImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      path: freezed == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileImageStateImplCopyWith<$Res>
    implements $ProfileImageStateCopyWith<$Res> {
  factory _$$ProfileImageStateImplCopyWith(_$ProfileImageStateImpl value,
          $Res Function(_$ProfileImageStateImpl) then) =
      __$$ProfileImageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? imageUrl, String? carImageUrl, String? path});
}

/// @nodoc
class __$$ProfileImageStateImplCopyWithImpl<$Res>
    extends _$ProfileImageStateCopyWithImpl<$Res, _$ProfileImageStateImpl>
    implements _$$ProfileImageStateImplCopyWith<$Res> {
  __$$ProfileImageStateImplCopyWithImpl(_$ProfileImageStateImpl _value,
      $Res Function(_$ProfileImageStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileImageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? imageUrl = freezed,
    Object? carImageUrl = freezed,
    Object? path = freezed,
  }) {
    return _then(_$ProfileImageStateImpl(
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      carImageUrl: freezed == carImageUrl
          ? _value.carImageUrl
          : carImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      path: freezed == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ProfileImageStateImpl extends _ProfileImageState {
  const _$ProfileImageStateImpl({this.imageUrl, this.carImageUrl, this.path})
      : super._();

  @override
  final String? imageUrl;
  @override
  final String? carImageUrl;
  @override
  final String? path;

  @override
  String toString() {
    return 'ProfileImageState(imageUrl: $imageUrl, carImageUrl: $carImageUrl, path: $path)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImageStateImpl &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.carImageUrl, carImageUrl) ||
                other.carImageUrl == carImageUrl) &&
            (identical(other.path, path) || other.path == path));
  }

  @override
  int get hashCode => Object.hash(runtimeType, imageUrl, carImageUrl, path);

  /// Create a copy of ProfileImageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImageStateImplCopyWith<_$ProfileImageStateImpl> get copyWith =>
      __$$ProfileImageStateImplCopyWithImpl<_$ProfileImageStateImpl>(
          this, _$identity);
}

abstract class _ProfileImageState extends ProfileImageState {
  const factory _ProfileImageState(
      {final String? imageUrl,
      final String? carImageUrl,
      final String? path}) = _$ProfileImageStateImpl;
  const _ProfileImageState._() : super._();

  @override
  String? get imageUrl;
  @override
  String? get carImageUrl;
  @override
  String? get path;

  /// Create a copy of ProfileImageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImageStateImplCopyWith<_$ProfileImageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
