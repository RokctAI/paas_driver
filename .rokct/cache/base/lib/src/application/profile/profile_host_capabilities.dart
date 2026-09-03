// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'package:base_sdk/src/domain/interface/gallery.dart';
import 'package:base_sdk/src/domain/interface/shops.dart';
import 'package:base_sdk/src/domain/interface/user.dart';

/// The account-facing repository facades a composed shell MAY register.
///
/// base_sdk declares the interfaces; the concrete implementations arrive
/// from feature SDKs at bootstrap (users_sdk registers
/// [UserRepositoryFacade], merchants_sdk [ShopsRepositoryFacade],
/// products_sdk [GalleryRepositoryFacade]). A shell composing none of them
/// — a radio app is base_sdk plus its player — still hosts the generic
/// profile page, so the host resolves each facade only where it is
/// registered and degrades per [ProfileHostCapabilities] instead of
/// throwing `GetIt: Object/factory with type ... is not registered` out
/// of the page's first build.
enum ProfileFacade {
  /// [UserRepositoryFacade] — the signed-in identity: profile details,
  /// addresses, wallet, referral, sign-out, delete-account.
  account,

  /// [ShopsRepositoryFacade] — shop creation from the profile.
  shops,

  /// [GalleryRepositoryFacade] — the image uploads behind shop creation.
  gallery,
}

/// Which [ProfileFacade]s the composing shell registered, read ONCE off
/// GetIt when the profile notifier is created ([detect]) and carried by
/// the generic profile host for the page's lifetime.
///
/// The host picks its surface from this:
///   * [hasAccount] false — ANONYMOUS MODE: no identity header (avatar,
///     name, edit pencil, badge, stats, corner), no sign-out, no usage
///     badge; the shell's top-row actions, plan slot, sections and footer
///     render as contributed.
///   * only [hasShops] / [hasGallery] false — the identity surface is
///     untouched; sections and header slots that declared a dependency
///     (`requires:`) on the missing facade are omitted, nothing else.
///   * all three true ([isComplete]) — exactly the surface the host always
///     rendered. Nothing changes for such shells.
///
/// Contributed widgets read the host's resolved value through
/// `ProfileHostScope.of(context)`.
@immutable
class ProfileHostCapabilities {
  /// [UserRepositoryFacade] is registered.
  final bool hasAccount;

  /// [ShopsRepositoryFacade] is registered.
  final bool hasShops;

  /// [GalleryRepositoryFacade] is registered.
  final bool hasGallery;

  const ProfileHostCapabilities({
    required this.hasAccount,
    required this.hasShops,
    required this.hasGallery,
  });

  /// Every facade present — the assumption the host made before anonymous
  /// mode existed, and what a widget rendered OUTSIDE the generic profile
  /// host assumes (see `ProfileHostScope.of`).
  static const ProfileHostCapabilities all = ProfileHostCapabilities(
    hasAccount: true,
    hasShops: true,
    hasGallery: true,
  );

  /// Reads each facade's registration off [locator] (`GetIt.instance` by
  /// default) WITHOUT resolving any of them — `isRegistered`, never `get`,
  /// so an absent facade is a `false`, not a `Bad state` throw.
  factory ProfileHostCapabilities.detect({GetIt? locator}) {
    final getIt = locator ?? GetIt.instance;
    return ProfileHostCapabilities(
      hasAccount: getIt.isRegistered<UserRepositoryFacade>(),
      hasShops: getIt.isRegistered<ShopsRepositoryFacade>(),
      hasGallery: getIt.isRegistered<GalleryRepositoryFacade>(),
    );
  }

  /// Whether [facade] is registered.
  bool has(ProfileFacade facade) => switch (facade) {
        ProfileFacade.account => hasAccount,
        ProfileFacade.shops => hasShops,
        ProfileFacade.gallery => hasGallery,
      };

  /// Whether every facade in [required] is registered. An empty
  /// [required] — the default for every section and header slot — is
  /// always satisfied.
  bool satisfies(Iterable<ProfileFacade> required) => required.every(has);

  /// No account facade: the host renders its anonymous surface.
  bool get isAnonymous => !hasAccount;

  /// Every facade registered: the host renders exactly as it always did.
  bool get isComplete => hasAccount && hasShops && hasGallery;

  /// The interface names of the absent facades, in [ProfileFacade] order —
  /// what the host's one `profile_host_anonymous_mode` telemetry event
  /// carries.
  List<String> get missingFacades => [
        for (final facade in ProfileFacade.values)
          if (!has(facade)) facadeName(facade),
      ];

  /// The base_sdk interface name behind [facade].
  static String facadeName(ProfileFacade facade) => switch (facade) {
        ProfileFacade.account => 'UserRepositoryFacade',
        ProfileFacade.shops => 'ShopsRepositoryFacade',
        ProfileFacade.gallery => 'GalleryRepositoryFacade',
      };

  @override
  bool operator ==(Object other) =>
      other is ProfileHostCapabilities &&
      other.hasAccount == hasAccount &&
      other.hasShops == hasShops &&
      other.hasGallery == hasGallery;

  @override
  int get hashCode => Object.hash(hasAccount, hasShops, hasGallery);

  @override
  String toString() => 'ProfileHostCapabilities(hasAccount: $hasAccount, '
      'hasShops: $hasShops, hasGallery: $hasGallery)';
}
