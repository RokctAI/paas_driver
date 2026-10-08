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


import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import 'package:base_sdk/src/models/data/profile_data.dart';
import 'package:base_sdk/src/presentation/components/custom_network_image.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

/// The one avatar every screen draws a person with.
///
/// Three states, in this order, and nothing else (Ray, 2026-09-18: "profile
/// image is ? no image or letters why"):
///
///   1. the stored picture, when [ProfileData.img] is set — through
///      [CustomNetworkImage], so a `data:` payload and an ordinary URL both
///      work and a failed load keeps that widget's own profile fallback;
///   2. otherwise the person's initials on the brand colour — the first
///      letter of each of the first two words of their name;
///   3. otherwise [Remix.user_line], a neutral person glyph.
///
/// A literal "?" is never drawn. The two private `_Avatar` copies this
/// replaces (the generic profile header and the launcher's account control)
/// both fell through to `'?'` whenever a signed-in user had no picture AND
/// no name/email on the locally cached [ProfileData] — which is exactly what
/// a freshly restored session looks like before the profile fetch lands. A
/// question mark reads as "we do not know who you are"; the glyph reads as
/// "a person", which is all the avatar ever meant to say.
///
/// Sizing is caller-supplied and already scaled: base_sdk's own pages pass
/// screenutil values (`56.r`, `22.sp`), launch_sdk — which does not depend on
/// flutter_screenutil — passes plain logical pixels. The widget itself stays
/// free of both so either host can use it.
class UserAvatar extends StatelessWidget {
  /// The person to draw. Null and empty behave identically: state 3.
  final ProfileData? user;

  /// Diameter of the circle.
  final double size;

  /// Initials type size. Defaults to `size / 2.5`, which keeps two letters
  /// inside the circle at every size the fleet uses.
  final double? fontSize;

  /// Size of the fallback glyph. Defaults to `size * 0.6`.
  final double? glyphSize;

  const UserAvatar({
    super.key,
    required this.user,
    required this.size,
    this.fontSize,
    this.glyphSize,
  });

  /// The initials text node, when state 2 is what renders.
  static const Key initialsKey = Key('user-avatar-initials');

  /// The neutral person glyph, when state 3 is what renders.
  static const Key glyphKey = Key('user-avatar-glyph');

  /// The initials for [user], or an empty string when there is no name to
  /// take them from — in which case the caller draws the glyph.
  ///
  /// The name is the profile's first and last name. Only when both are blank
  /// does this fall back to the local part of the email address, so a
  /// session that knows nothing but an address still shows that person's
  /// letter rather than nothing.
  static String initialsOf(ProfileData? user) {
    final String name =
        '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim();
    if (name.isNotEmpty) return initialsFromName(name);
    final String email = (user?.email ?? '').trim();
    if (email.isNotEmpty) return initialsFromName(email.split('@').first);
    return '';
  }

  /// First letters of the first two words of [name], uppercased; one letter
  /// when [name] is a single word; empty when there are no words.
  ///
  /// "Letter" is a whole user-perceived character, not a UTF-16 code unit:
  /// the leading code point plus any combining marks riding on it. So "éva"
  /// gives "É" (not a bare "E"), and an emoji or an astral-plane letter is
  /// not sliced in half into an unrenderable lone surrogate.
  ///
  /// Casing is Unicode's own default mapping ([String.toUpperCase]), which is
  /// the locale-independent one: scripts without case (CJK, Arabic, Hebrew)
  /// pass through unchanged instead of being mangled, and no locale is
  /// assumed for a name whose language the app does not know.
  static String initialsFromName(String name) {
    final Iterable<String> words = name
        .split(RegExp(r'\s+'))
        .where((String word) => word.trim().isNotEmpty)
        .take(2);
    final StringBuffer out = StringBuffer();
    for (final String word in words) {
      out.write(_firstLetter(word));
    }
    return out.toString();
  }

  /// Matches one user-perceived character at the start of a word: a
  /// non-mark code point followed by the combining marks attached to it.
  static final RegExp _leadingLetter = RegExp(r'^\P{M}\p{M}*', unicode: true);

  static String _firstLetter(String word) {
    final RegExpMatch? match = _leadingLetter.firstMatch(word);
    return (match?.group(0) ?? '').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String img = user?.img ?? '';
    if (img.isNotEmpty) {
      return CustomNetworkImage(
        url: img,
        width: size,
        height: size,
        radius: size / 2,
        profile: true,
      );
    }
    final String initials = initialsOf(user);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppStyle.primary,
        shape: BoxShape.circle,
      ),
      child: initials.isEmpty
          ? Icon(
              Remix.user_line,
              key: glyphKey,
              size: glyphSize ?? size * 0.6,
              color: AppStyle.white,
            )
          : Text(
              initials,
              key: initialsKey,
              style: AppStyle.interSemi(
                size: fontSize ?? size / 2.5,
                color: AppStyle.white,
              ),
            ),
    );
  }
}
